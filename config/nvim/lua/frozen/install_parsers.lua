local parsers = require("frozen.parsers")
local task = require("nvim-treesitter").install(parsers, { summary = true })
task:wait()

local installed = require("nvim-treesitter").get_installed()
for _, parser in ipairs(parsers) do
  assert(vim.tbl_contains(installed, parser), "parser installation failed: " .. parser)
end

