local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  error("lazy.nvim is missing; run install.sh")
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "frozen.plugin_specs" },
  },
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  defaults = { lazy = false, version = false },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  install = { missing = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

