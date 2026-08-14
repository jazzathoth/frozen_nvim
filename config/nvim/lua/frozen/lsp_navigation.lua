local M = {}

local function locations(result)
  if not result then
    return {}
  end
  if result.uri or result.targetUri then
    return { result }
  end
  return result
end

function M.definition_tab()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
  local client = clients[1]
  if not client then
    vim.notify("No language server with definition support is attached", vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_position_params(winid, client.offset_encoding)
  local accepted = client:request("textDocument/definition", params, function(err, result)
    local targets = locations(result)
    if err or #targets == 0 then
      vim.notify("Definition not found", vim.log.levels.INFO)
      return
    end

    local target = targets[1]
    local uri = target.targetUri or target.uri
    if not uri then
      vim.notify("Definition has no target URI", vim.log.levels.WARN)
      return
    end

    if uri:sub(1, 7) == "file://" then
      local filename = vim.uri_to_fname(uri)
      vim.cmd("tab drop " .. vim.fn.fnameescape(filename))
    end
    if not vim.lsp.util.show_document(target, client.offset_encoding, { reuse_win = true, focus = true }) then
      vim.notify("Could not open definition", vim.log.levels.WARN)
    end
  end, bufnr)
  if not accepted then
    vim.notify("Definition request was rejected", vim.log.levels.WARN)
  end
end

return M
