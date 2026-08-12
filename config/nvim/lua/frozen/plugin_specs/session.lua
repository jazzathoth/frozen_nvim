local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("persistence.nvim", {
    event = "BufReadPre",
    opts = {},
    keys = {
      { keys.session.restore, function() require("persistence").load() end, desc = "Restore project session" },
      { keys.session.last, function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { keys.session.stop, function() require("persistence").stop() end, desc = "Stop session saving" },
    },
  }),
}
