local keys = require("frozen.settings.keybindings")
local features = require("frozen.settings.features")
local plugin = require("frozen.plugin")

local explorer_keys = {}
if features.explorer_open_actions then
  explorer_keys[keys.files.open_tab] = "tabdrop"
  explorer_keys[keys.files.open_split] = "edit_split"
  explorer_keys[keys.files.open_vsplit] = "edit_vsplit"
else
  explorer_keys[keys.files.open_tab] = false
  explorer_keys[keys.files.open_split] = false
  explorer_keys[keys.files.open_vsplit] = false
end

local plugin_keys = {
  { keys.files.tree, function() Snacks.explorer() end, desc = "Project files" },
  { keys.files.find, function() Snacks.picker.files() end, desc = "Find files" },
  { keys.files.grep, function() Snacks.picker.grep() end, desc = "Search project" },
  { keys.diagnostics.list, function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
  { keys.terminal[1], function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Terminal" },
  { keys.terminal[2], function() Snacks.terminal() end, mode = { "n", "t" }, desc = "Terminal keycode alias" },
}
if features.buffer_menus then
  vim.list_extend(plugin_keys, {
    { keys.buffers.all, function() require("frozen.buffers").open("all") end, desc = "All buffers" },
    { keys.buffers.displayed, function() require("frozen.buffers").open("displayed") end, desc = "Displayed buffers" },
    { keys.buffers.orphaned, function() require("frozen.buffers").open("orphaned") end, desc = "Orphaned buffers" },
    { keys.buffers.modified, function() require("frozen.buffers").open("modified") end, desc = "Modified buffers" },
  })
end

return {
  plugin.spec("snacks.nvim", {
    priority = 1000,
    lazy = false,
    opts = {
      explorer = { enabled = true },
      picker = {
        enabled = true,
        sources = {
          explorer = { win = { list = { keys = explorer_keys } } },
        },
      },
      terminal = { enabled = true },
    },
    keys = plugin_keys,
  }),
}
