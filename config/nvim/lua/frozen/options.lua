vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Tools bundled for this configuration take precedence only inside Neovim.
-- This does not alter the parent shell or shadow distro tools system-wide.
local bundled_tools = vim.fn.stdpath("data") .. "/frozen-nvim/bin"
vim.env.PATH = bundled_tools .. ":" .. (vim.env.PATH or "")

local opt = vim.opt

-- Use the desktop clipboard only when a matching display and provider exist.
-- Otherwise y/p keep using Neovim's internal register without provider errors.
local wayland_clipboard = vim.env.WAYLAND_DISPLAY
  and vim.fn.executable("wl-copy") == 1
  and vim.fn.executable("wl-paste") == 1
local x11_clipboard = vim.env.DISPLAY
  and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1)

-- The repository test launcher isolates Neovim's XDG runtime directory. Give
-- wl-clipboard the original directory so it can still reach the Wayland socket.
local host_runtime = vim.env.FROZEN_NVIM_HOST_XDG_RUNTIME_DIR
if wayland_clipboard and host_runtime and host_runtime ~= vim.env.XDG_RUNTIME_DIR then
  local runtime = "XDG_RUNTIME_DIR=" .. host_runtime
  vim.g.clipboard = {
    name = "wl-clipboard (host runtime)",
    copy = {
      ["+"] = { "env", runtime, "wl-copy", "--type", "text/plain" },
      ["*"] = { "env", runtime, "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "env", runtime, "wl-paste", "--no-newline" },
      ["*"] = { "env", runtime, "wl-paste", "--no-newline", "--primary" },
    },
    cache_enabled = 1,
  }
end

if wayland_clipboard or x11_clipboard then
  opt.clipboard = "unnamedplus"
end

opt.autowrite = true
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.ignorecase = true
opt.inccommand = "nosplit"
opt.laststatus = 3
opt.list = true
opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.scrolloff = 4
opt.shiftwidth = 2
opt.showmode = false
opt.sidescrolloff = 8
-- Keep Git and diagnostic signs visible at the same time.
opt.signcolumn = "yes:2"
opt.smartcase = true
opt.smartindent = true
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 1000
opt.undofile = true
opt.updatetime = 200
opt.wrap = false

vim.g.markdown_recommended_style = 0
