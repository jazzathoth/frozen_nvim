local plugin = require("frozen.plugin")
local keys = require("frozen.settings.keybindings")

return {
  plugin.spec("friendly-snippets", { lazy = true }),
  plugin.spec("blink.cmp", {
    event = "InsertEnter",
    dependencies = { "friendly-snippets" },
    opts = {
      keymap = {
        preset = "default",
        [keys.completion.next] = { "select_next", "fallback" },
        [keys.completion.previous] = { "select_prev", "fallback" },
        [keys.completion.accept] = {
          "select_and_accept",
          function()
            -- Expand an empty pair onto three lines when completion did not
            -- consume Enter.
            return require("mini.pairs").cr()
          end,
        },
        [keys.completion.cancel] = { "cancel", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 500 } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = {
        implementation = "rust",
        -- install.sh supplies and verifies the v1.10.2 release binary.
        prebuilt_binaries = { download = false, force_version = "v1.10.2" },
      },
    },
  }),
}
