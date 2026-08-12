local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("snacks.nvim", {
    priority = 1000,
    lazy = false,
    opts = {
      explorer = { enabled = true },
      picker = { enabled = true },
      terminal = { enabled = true },
    },
    keys = {
      { keys.files.tree, function() Snacks.explorer() end, desc = "Project files" },
      { keys.files.find, function() Snacks.picker.files() end, desc = "Find files" },
      { keys.files.grep, function() Snacks.picker.grep() end, desc = "Search project" },
      { keys.diagnostics.list, function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { keys.terminal[1], function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Terminal" },
      { keys.terminal[2], function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Terminal keycode alias" },
    },
  }),
}
