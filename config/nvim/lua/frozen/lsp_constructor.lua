local M = {}

local type_kinds = {
  [vim.lsp.protocol.SymbolKind.Class] = true,
  [vim.lsp.protocol.SymbolKind.Interface] = true,
  [vim.lsp.protocol.SymbolKind.Struct] = true,
}

local function enabled_for(filetype)
  local settings = require("frozen.settings.member_access")
  return not vim.tbl_contains(settings.disabled_filetypes, filetype)
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

local function location_parts(location)
  local uri = location.targetUri or location.uri
  local range = location.targetSelectionRange or location.targetRange or location.range
  if not uri or not range or not range.start then
    return nil
  end
  return uri, range.start
end

local function position_compare(left, right)
  if left.line ~= right.line then
    return left.line < right.line and -1 or 1
  end
  if left.character == right.character then
    return 0
  end
  return left.character < right.character and -1 or 1
end

local function range_contains(range, position)
  return range
    and position_compare(range.start, position) <= 0
    and position_compare(position, range["end"]) <= 0
end

local function symbol_range(symbol)
  if symbol.location then
    return symbol.location.range
  end
  return symbol.selectionRange or symbol.range
end

local function find_hierarchical_type(symbols, position)
  local found
  local function visit(symbol)
    if type_kinds[symbol.kind] and range_contains(symbol_range(symbol), position) then
      found = symbol
    end
    for _, child in ipairs(symbol.children or {}) do
      visit(child)
    end
  end
  for _, symbol in ipairs(symbols or {}) do
    visit(symbol)
  end
  return found
end

local function constructors_from_hierarchy(type_symbol, default_uri)
  local constructors = {}
  if not type_symbol then
    return constructors
  end
  for _, child in ipairs(type_symbol.children or {}) do
    if child.kind == vim.lsp.protocol.SymbolKind.Constructor then
      local range = child.selectionRange or child.range
      if range and range.start then
        table.insert(constructors, {
          uri = default_uri,
          position = range.start,
        })
      end
    end
  end
  return constructors
end

local function constructors_from_flat(symbols, uri, position)
  local type_name
  for _, symbol in ipairs(symbols or {}) do
    local location = symbol.location
    if type_kinds[symbol.kind]
      and location
      and location.uri == uri
      and range_contains(location.range, position)
    then
      type_name = symbol.name
      break
    end
  end
  if not type_name then
    return {}
  end

  local constructors = {}
  for _, symbol in ipairs(symbols) do
    local location = symbol.location
    if symbol.kind == vim.lsp.protocol.SymbolKind.Constructor
      and symbol.containerName == type_name
      and location
      and location.uri == uri
      and location.range
      and location.range.start
    then
      table.insert(constructors, {
        uri = uri,
        position = location.range.start,
      })
    end
  end
  return constructors
end

local function constructor_locations(symbols, uri, position)
  local hierarchical = false
  for _, symbol in ipairs(symbols or {}) do
    if not symbol.location then
      hierarchical = true
      break
    end
  end
  if hierarchical then
    return constructors_from_hierarchy(find_hierarchical_type(symbols, position), uri)
  end
  return constructors_from_flat(symbols, uri, position)
end

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

local function format_hovers(hovers)
  if #hovers == 0 then
    return nil
  end
  local lines = { "", "### Constructor", "" }
  for index, hover in ipairs(hovers) do
    if index > 1 then
      table.insert(lines, "")
      table.insert(lines, "---")
      table.insert(lines, "")
    end
    vim.list_extend(lines, hover)
  end
  return lines
end

function M.request(client, bufnr, winid, callback)
  if not enabled_for(vim.bo[bufnr].filetype)
    or not client:supports_method("textDocument/typeDefinition", bufnr)
    or not client:supports_method("textDocument/documentSymbol", bufnr)
    or not client:supports_method("textDocument/hover", bufnr)
  then
    callback(nil)
    return
  end

  local position = vim.lsp.util.make_position_params(winid, client.offset_encoding)
  local accepted = client:request("textDocument/typeDefinition", position, function(type_err, type_result)
    if type_err then
      callback(nil)
      return
    end

    local targets = {}
    local seen_targets = {}
    for _, location in ipairs(locations(type_result)) do
      local uri, target_position = location_parts(location)
      local key = uri and target_position
        and (uri .. ":" .. target_position.line .. ":" .. target_position.character)
      if key and not seen_targets[key] then
        seen_targets[key] = true
        table.insert(targets, { uri = uri, position = target_position })
      end
    end
    if #targets == 0 then
      callback(nil)
      return
    end

    local constructor_targets = {}
    local remaining_symbols = #targets
    local function symbols_finished()
      remaining_symbols = remaining_symbols - 1
      if remaining_symbols ~= 0 then
        return
      end
      if #constructor_targets == 0 then
        callback(nil)
        return
      end

      local hovers = {}
      local seen_hovers = {}
      local remaining_hovers = math.min(#constructor_targets, 5)
      local function hover_finished()
        remaining_hovers = remaining_hovers - 1
        if remaining_hovers == 0 then
          callback(format_hovers(hovers))
        end
      end

      for index = 1, remaining_hovers do
        local target = constructor_targets[index]
        local hover_accepted = client:request("textDocument/hover", {
          textDocument = { uri = target.uri },
          position = target.position,
        }, function(hover_err, hover_result)
          if not hover_err then
            local lines = hover_lines(hover_result)
            local key = lines and table.concat(lines, "\n")
            if key and not seen_hovers[key] then
              seen_hovers[key] = true
              table.insert(hovers, lines)
            end
          end
          hover_finished()
        end, bufnr)
        if not hover_accepted then
          hover_finished()
        end
      end
    end

    for _, target in ipairs(targets) do
      local symbols_accepted = client:request("textDocument/documentSymbol", {
        textDocument = { uri = target.uri },
      }, function(symbol_err, symbols)
        if not symbol_err then
          vim.list_extend(constructor_targets, constructor_locations(symbols, target.uri, target.position))
        end
        symbols_finished()
      end, bufnr)
      if not symbols_accepted then
        symbols_finished()
      end
    end
  end, bufnr)

  if not accepted then
    callback(nil)
  end
end

return M
