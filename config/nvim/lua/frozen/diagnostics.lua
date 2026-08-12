-- Show at most one diagnostic sign per line. Multiple messages remain
-- available through diagnostic floats and lists; only the gutter is reduced.
local sign_namespace = vim.api.nvim_create_namespace("frozen_diagnostic_signs")
local original_signs = vim.diagnostic.handlers.signs

vim.diagnostic.handlers.signs = {
  show = function(_, buffer, _, opts)
    local worst_by_line = {}
    for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
      local current = worst_by_line[diagnostic.lnum]
      if not current or diagnostic.severity < current.severity then
        worst_by_line[diagnostic.lnum] = diagnostic
      end
    end
    original_signs.show(sign_namespace, buffer, vim.tbl_values(worst_by_line), opts)
  end,
  hide = function(_, buffer)
    original_signs.hide(sign_namespace, buffer)
  end,
}

vim.diagnostic.config({
  severity_sort = true,
  signs = { priority = 10 },
})
