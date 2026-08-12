local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("render-markdown.nvim", {
    ft = { "markdown" },
    dependencies = { "nvim-treesitter" },
    opts = {
      enabled = true,
    },
    keys = {
      {
        keys.markdown.toggle,
        function() require("render-markdown").buf_toggle() end,
        ft = "markdown",
        desc = "Toggle rendered Markdown",
      },
      {
        keys.markdown.preview,
        function() require("render-markdown").preview() end,
        ft = "markdown",
        desc = "Markdown side preview",
      },
    },
  }),
}
