local M = {}

local function hover_lines(result)
  if not result or not result.contents then
    return nil
  end
  local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
  while lines[1] == "" do
    table.remove(lines, 1)
  end
  while lines[#lines] == "" do
    table.remove(lines)
  end
  return #lines > 0 and lines or nil
end

local function score(lines)
  local characters = 0
  for _, line in ipairs(lines) do
    characters = characters + #line
  end
  return characters + (#lines * 20)
end

local function has_declaration(lines)
  local text = table.concat(lines, "\n")
  return text:find("%(")
    or text:find("%f[%a]class%f[%A]")
    or text:find("%f[%a]struct%f[%A]")
    or text:find("%f[%a]interface%f[%A]")
    or text:find("%f[%a]enum%f[%A]")
    or text:find("%f[%a]trait%f[%A]")
    or text:find("%f[%a]typedef%f[%A]")
    or text:find("%f[%a]mixin%f[%A]")
    or text:find("%f[%a]extension%f[%A]")
    or text:find("%f[%a]get%f[%A]")
    or text:find("%f[%a]set%f[%A]")
end

local function locations(result)
  if not result then
    return {}
  end
  if result.uri or result.targetUri then
    return { result }
  end
  return result
end

local function target_params(location)
  local uri = location.targetUri or location.uri
  local range = location.targetSelectionRange or location.targetRange or location.range
  if not uri or not range or not range.start then
    return nil
  end
  return {
    textDocument = { uri = uri },
    position = range.start,
  }
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winid)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })
  local client = clients[1]
  if not client then
    vim.notify("No language server with hover support is attached", vim.log.levels.WARN)
    return
  end

  local candidates = {}

  local function add_candidate(result)
    local lines = hover_lines(result)
    if lines then
      table.insert(candidates, lines)
    end
  end

  local function render()
    if vim.api.nvim_get_current_buf() ~= bufnr
      or vim.api.nvim_get_current_win() ~= winid
      or not vim.deep_equal(vim.api.nvim_win_get_cursor(winid), cursor)
    then
      return
    end
    if #candidates == 0 then
      vim.notify("No symbol information available", vim.log.levels.INFO)
      return
    end
    table.sort(candidates, function(left, right) return score(left) > score(right) end)
    vim.lsp.util.open_floating_preview(candidates[1], "markdown", {
      border = "rounded",
      focus_id = "frozen_symbol_context",
      max_width = 100,
      max_height = 20,
      title = "Symbol context",
    })
  end

  local function request(method, params, callback)
    local accepted = client:request(method, params, function(err, result)
      callback(not err and result or nil)
    end, bufnr)
    if not accepted then
      callback(nil)
    end
  end

  local position = vim.lsp.util.make_position_params(winid, client.offset_encoding)

  local function request_target_hovers(method, done)
    if not client:supports_method(method, bufnr) then
      done()
      return
    end
    request(method, position, function(result)
      local targets = {}
      local seen = {}
      for _, location in ipairs(locations(result)) do
        local params = target_params(location)
        local key = params and (params.textDocument.uri .. ":" .. params.position.line .. ":" .. params.position.character)
        if params and not seen[key] then
          seen[key] = true
          table.insert(targets, params)
          if #targets == 3 then
            break
          end
        end
      end
      if #targets == 0 then
        done()
        return
      end
      local remaining = #targets
      for _, params in ipairs(targets) do
        request("textDocument/hover", params, function(hover)
          add_candidate(hover)
          remaining = remaining - 1
          if remaining == 0 then
            done()
          end
        end)
      end
    end)
  end

  request("textDocument/hover", position, function(hover)
    add_candidate(hover)
    request_target_hovers("textDocument/definition", function()
      table.sort(candidates, function(left, right) return score(left) > score(right) end)
      local best = candidates[1]
      -- Variable/expression hover is often only "name: Type". Follow its
      -- type in that case, but do not replace an actual function or type
      -- declaration with unrelated return-type information.
      if not best or (score(best) < 180 and not has_declaration(best)) then
        request_target_hovers("textDocument/typeDefinition", render)
      else
        render()
      end
    end)
  end)
end

function M.definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winid)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })
  local client = clients[1]
  if not client or not client:supports_method("textDocument/definition", bufnr) then
    vim.notify("No language server with definition preview support is attached", vim.log.levels.WARN)
    return
  end

  local position = vim.lsp.util.make_position_params(winid, client.offset_encoding)
  local accepted = client:request("textDocument/definition", position, function(err, result)
    if err or #locations(result) == 0 then
      vim.notify("Definition not found", vim.log.levels.INFO)
      return
    end

    local targets = {}
    local seen = {}
    for _, location in ipairs(locations(result)) do
      local params = target_params(location)
      local key = params and (params.textDocument.uri .. ":" .. params.position.line .. ":" .. params.position.character)
      if params and not seen[key] then
        seen[key] = true
        table.insert(targets, params)
        if #targets == 3 then
          break
        end
      end
    end
    if #targets == 0 then
      vim.notify("Definition not found", vim.log.levels.INFO)
      return
    end

    local candidates = {}
    local remaining = #targets
    local function finish_target()
      remaining = remaining - 1
      if remaining ~= 0 then
        return
      end
      if vim.api.nvim_get_current_buf() ~= bufnr
        or vim.api.nvim_get_current_win() ~= winid
        or not vim.deep_equal(vim.api.nvim_win_get_cursor(winid), cursor)
      then
        return
      end
      if #candidates == 0 then
        vim.notify("No definition information available", vim.log.levels.INFO)
        return
      end
      table.sort(candidates, function(left, right) return score(left) > score(right) end)
      vim.lsp.util.open_floating_preview(candidates[1], "markdown", {
        border = "rounded",
        focus_id = "frozen_definition_information",
        max_width = 100,
        max_height = 20,
        title = "Definition",
      })
    end
    for _, params in ipairs(targets) do
      local hover_accepted = client:request("textDocument/hover", params, function(hover_err, hover)
        if not hover_err then
          local lines = hover_lines(hover)
          if lines then
            table.insert(candidates, lines)
          end
        end
        finish_target()
      end, bufnr)
      if not hover_accepted then
        finish_target()
      end
    end
  end, bufnr)
  if not accepted then
    vim.notify("Definition request was rejected", vim.log.levels.WARN)
  end
end

return M
