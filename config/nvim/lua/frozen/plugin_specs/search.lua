local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("grug-far.nvim", {
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = { { keys.replace, "<cmd>GrugFar<cr>", mode = { "n", "x" }, desc = "Search and replace" } },
    opts = {
      enabledEngines = { "ripgrep" },
      engines = {
        ripgrep = { path = vim.fn.stdpath("data") .. "/frozen-nvim/runtime-bin/rg" },
      },
    },
  }),
}
