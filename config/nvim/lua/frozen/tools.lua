-- Runtime tools bundled specifically for this configuration. Changing
-- vim.env.PATH affects Neovim and its children, but not the parent shell.
-- Only ripgrep lives here; installation-only tools use a separate directory.
local runtime_bin = vim.fn.stdpath("data") .. "/frozen-nvim/runtime-bin"
vim.env.PATH = runtime_bin .. ":" .. (vim.env.PATH or "")
