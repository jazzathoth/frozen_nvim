-- Neovim 0.12.4's diagnostic underline handler defers drawing diagnostics for
-- unloaded buffers until BufRead. It then reads diagnostic.lnum with strict
-- bounds checking, so a stale LSP diagnostic below the file's current final
-- line raises "Index out of bounds" while a picker or explorer opens the file.
--
-- Upstream issue and fix: https://github.com/neovim/neovim/issues/40838
-- The fix is targeted at Neovim 0.13. Remove this module and its require() in
-- init.lua when the pinned Neovim release contains that fix. The exact version
-- guard below prevents this compatibility code from affecting another release.

local version = vim.version()
if version.major ~= 0 or version.minor ~= 12 or version.patch ~= 4 then
  return
end

local original = vim.diagnostic.handlers.underline
local pending = {}

local function pending_for(namespace)
  pending[namespace] = pending[namespace] or {}
  return pending[namespace]
end

local function cancel_pending(namespace, bufnr)
  local namespace_pending = pending[namespace]
  local autocmd = namespace_pending and namespace_pending[bufnr]
  if autocmd then
    pcall(vim.api.nvim_del_autocmd, autocmd)
    namespace_pending[bufnr] = nil
  end
end

local function show_valid(namespace, bufnr, diagnostics, opts)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local valid = vim.tbl_filter(function(diagnostic)
    return type(diagnostic.lnum) == "number"
      and diagnostic.lnum >= 0
      and diagnostic.lnum < line_count
  end, diagnostics)

  return original.show(namespace, bufnr, valid, opts)
end

vim.diagnostic.handlers.underline = {
  show = function(namespace, bufnr, diagnostics, opts)
    if vim.api.nvim_buf_is_loaded(bufnr) then
      return show_valid(namespace, bufnr, diagnostics, opts)
    end

    cancel_pending(namespace, bufnr)
    local namespace_pending = pending_for(namespace)
    namespace_pending[bufnr] = vim.api.nvim_create_autocmd("BufRead", {
      buffer = bufnr,
      once = true,
      callback = function()
        namespace_pending[bufnr] = nil
        show_valid(namespace, bufnr, diagnostics, opts)
      end,
    })
  end,
  hide = function(namespace, bufnr)
    cancel_pending(namespace, bufnr)
    return original.hide(namespace, bufnr)
  end,
}
