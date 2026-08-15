local M = {}

local shadow_marker = "__frozen_nvim_context_"
local wrapped_clients = {}
local sequence = 0
local last_status = "Enhanced hover has not run yet"

local excluded_kinds = {
  [vim.lsp.protocol.CompletionItemKind.Text] = true,
  [vim.lsp.protocol.CompletionItemKind.Keyword] = true,
  [vim.lsp.protocol.CompletionItemKind.Snippet] = true,
  [vim.lsp.protocol.CompletionItemKind.File] = true,
  [vim.lsp.protocol.CompletionItemKind.Folder] = true,
  [vim.lsp.protocol.CompletionItemKind.Color] = true,
  [vim.lsp.protocol.CompletionItemKind.Unit] = true,
}

local function operators_for(filetype)
  local settings = require("frozen.settings.member_access")
  if vim.tbl_contains(settings.disabled_filetypes, filetype) then
    return {}
  end
  local operators = {}
  for _, section in ipairs(settings.operators) do
    if vim.tbl_contains(section.filetypes, filetype) then
      table.insert(operators, section.operator)
    end
  end
  return operators
end

local function completion_items(result)
  if not result or result == vim.NIL then
    return {}
  end
  return result.items or result
end

local function useful_items(result)
  local items = {}
  local seen = {}
  for _, item in ipairs(completion_items(result)) do
    local label = type(item.label) == "string" and item.label or nil
    local key = label and (label .. "\0" .. (item.detail or "")) or nil
    if label and not excluded_kinds[item.kind] and not seen[key] then
      seen[key] = true
      table.insert(items, item)
    end
  end
  return items
end

local function one_line(text)
  text = tostring(text or ""):gsub("[%s\r\n]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  if #text > 120 then
    text = text:sub(1, 117) .. "..."
  end
  return text
end

local function markdown_code(text)
  return tostring(text):gsub("`", "'")
end

local function format_items(items)
  local lines = { "", "### Members", "" }
  local kinds = vim.lsp.protocol.CompletionItemKind
  local limit = math.min(#items, 50)

  for index = 1, limit do
    local item = items[index]
    local kind = kinds[item.kind] or "Member"
    local detail = one_line(item.detail)
    local suffix = detail ~= "" and (" — `" .. markdown_code(detail) .. "`") or ""
    table.insert(lines, ("- `%s` _%s_%s"):format(markdown_code(item.label), kind, suffix))
  end

  if #items > limit then
    table.insert(lines, ("- _… %d additional members_"):format(#items - limit))
  end

  return lines
end

local function identifier_end(line, cursor_col)
  if cursor_col < 0 or cursor_col >= #line then
    return nil
  end
  local character = line:sub(cursor_col + 1, cursor_col + 1)
  if not character:match("[%w_]") then
    return nil
  end
  local remainder = line:sub(cursor_col + 2):match("^([%w_]*)") or ""
  return cursor_col + 1 + #remainder
end

local function prioritize_existing_operator(operators, line, insert_col)
  local existing = {}
  local remaining = {}
  for _, operator in ipairs(operators) do
    if line:sub(insert_col + 1, insert_col + #operator) == operator then
      table.insert(existing, operator)
    else
      table.insert(remaining, operator)
    end
  end
  vim.list_extend(existing, remaining)
  return existing
end

local function shadow_name(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return nil
  end
  sequence = sequence + 1
  local directory = vim.fs.dirname(filename)
  local extension = vim.fn.fnamemodify(filename, ":e")
  local suffix = extension ~= "" and ("." .. extension) or ""
  return ("%s/%s%d-%d%s"):format(directory, shadow_marker, vim.fn.getpid(), sequence, suffix)
end

local function suppress_shadow_diagnostics(client)
  if wrapped_clients[client.id] then
    return
  end
  wrapped_clients[client.id] = true

  local method = "textDocument/publishDiagnostics"
  local original = client.handlers[method] or vim.lsp.handlers[method]
  client.handlers[method] = function(err, result, context, config)
    if result and type(result.uri) == "string" and result.uri:find(shadow_marker, 1, true) then
      return
    end
    if original then
      return original(err, result, context, config)
    end
  end
end

local function probe(client, bufnr, row, insert_col, source_lines, operator, callback)
  local filename = shadow_name(bufnr)
  if not filename then
    callback(nil)
    return
  end

  local lines = vim.deepcopy(source_lines)
  local line = lines[row + 1]
  local operator_is_present = line:sub(insert_col + 1, insert_col + #operator) == operator
  if not operator_is_present then
    lines[row + 1] = line:sub(1, insert_col) .. operator .. line:sub(insert_col + 1)
  end
  local completion_col = insert_col + #operator

  local uri = vim.uri_from_fname(filename)
  local closed = false
  local finished = false
  local request_id

  local function close_shadow()
    if closed then
      return
    end
    closed = true
    client:notify("textDocument/didClose", {
      textDocument = { uri = uri },
    })
  end

  local function finish(items)
    if finished then
      return
    end
    finished = true
    close_shadow()
    callback(items)
  end

  local opened = client:notify("textDocument/didOpen", {
    textDocument = {
      uri = uri,
      languageId = client.get_language_id(bufnr, vim.bo[bufnr].filetype),
      version = 1,
      text = table.concat(lines, "\n"),
    },
  })
  if not opened then
    finish(nil)
    return
  end

  local character = vim.str_utfindex(
    lines[row + 1],
    client.offset_encoding,
      completion_col,
    false
  )

  local accepted
  accepted, request_id = client:request("textDocument/completion", {
    textDocument = { uri = uri },
    position = { line = row, character = character },
    context = {
      triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked,
    },
  }, function(err, result)
    if err then
      last_status = ("Completion request failed for `%s`: %s"):format(operator, err.message or "unknown error")
      finish(nil)
    else
      finish(useful_items(result))
    end
  end, bufnr)

  if not accepted then
    finish(nil)
    return
  end

  vim.defer_fn(function()
    if not finished then
      if request_id then
        client:cancel_request(request_id)
      end
      finish(nil)
    end
  end, 2000)
end

function M.request(client, bufnr, winid, callback)
  local filetype = vim.bo[bufnr].filetype
  local operators = operators_for(filetype)
  if #operators == 0 then
    last_status = ("Enhanced member hover is disabled or undefined for filetype `%s`"):format(filetype)
    callback(nil)
    return
  end
  if not client:supports_method("textDocument/completion", bufnr) then
    last_status = ("LSP client `%s` does not support completion"):format(client.name)
    callback(nil)
    return
  end
  if not client:supports_method("textDocument/didOpen", bufnr) then
    last_status = ("LSP client `%s` does not support temporary documents"):format(client.name)
    callback(nil)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(winid)
  local row = cursor[1] - 1
  local source_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line = source_lines[row + 1]
  local insert_col = line and identifier_end(line, cursor[2]) or nil
  if not insert_col then
    last_status = "Cursor is not on a simple identifier"
    callback(nil)
    return
  end

  operators = prioritize_existing_operator(operators, line, insert_col)

  suppress_shadow_diagnostics(client)
  last_status = ("Requesting members from `%s`"):format(client.name)

  local function attempt(index)
    local operator = operators[index]
    if not operator then
      last_status = ("LSP client `%s` returned no member completions"):format(client.name)
      callback(nil)
      return
    end
    probe(client, bufnr, row, insert_col, source_lines, operator, function(items)
      if items and #items > 0 then
        last_status = ("Received %d members from `%s` using `%s`"):format(#items, client.name, operator)
        callback(format_items(items))
      else
        attempt(index + 1)
      end
    end)
  end

  attempt(1)
end

function M.status()
  vim.notify(last_status, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("FrozenHoverStatus", M.status, {
  desc = "Show the result of the most recent enhanced hover request",
})

return M
