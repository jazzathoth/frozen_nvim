local bindings = require("frozen.settings.keybindings")
local map = vim.keymap.set

map("n", bindings.files.new, "<cmd>enew<cr>", { desc = "New file" })
map("n", bindings.quit_all, "<cmd>quitall<cr>", { desc = "Quit all" })

map("n", bindings.windows.left, "<C-w>h", { desc = "Window left", remap = true })
map("n", bindings.windows.down, "<C-w>j", { desc = "Window down", remap = true })
map("n", bindings.windows.up, "<C-w>k", { desc = "Window up", remap = true })
map("n", bindings.windows.right, "<C-w>l", { desc = "Window right", remap = true })
map("n", bindings.windows.split_below, "<C-w>s", { desc = "Split below", remap = true })
map("n", bindings.windows.split_right, "<C-w>v", { desc = "Split right", remap = true })

local function diagnostic_jump(count)
  return function()
    vim.diagnostic.jump({ count = count * vim.v.count1, float = true })
  end
end

map("n", bindings.diagnostics.line, vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", bindings.diagnostics.next, diagnostic_jump(1), { desc = "Next diagnostic" })
map("n", bindings.diagnostics.previous, diagnostic_jump(-1), { desc = "Previous diagnostic" })
