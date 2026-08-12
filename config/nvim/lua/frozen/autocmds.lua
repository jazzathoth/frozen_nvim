local function group(name)
  return vim.api.nvim_create_augroup("frozen_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd.checktime()
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group("text"),
  pattern = { "gitcommit", "markdown", "plaintex", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group("json"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

