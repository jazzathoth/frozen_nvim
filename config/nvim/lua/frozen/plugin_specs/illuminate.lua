local plugin = require("frozen.plugin")

return {
  plugin.spec("vim-illuminate", {
    lazy = false,
    config = function()
      local illuminate = require("illuminate")

      illuminate.configure({
        -- LSP references distinguish symbols with the same spelling in
        -- different scopes. Do not fall back to textual regex matching.
        providers = { "lsp" },
        delay = 200,
        disable_keymaps = true,
        filetypes_denylist = {
          -- Defaults documented by vim-illuminate.
          "dirbuf",
          "dirvish",
          "fugitive",

          -- UI buffers used by plugins pinned in this repository.
          "grug-far",
          "lazy",
          "lazy_backdrop",
          "noice",
          "trouble",
          "snacks_dashboard",
          "snacks_input",
          "snacks_layout_box",
          "snacks_notif",
          "snacks_notif_history",
          "snacks_picker_input",
          "snacks_picker_list",
          "snacks_picker_preview",
          "snacks_terminal",
          "snacks_win",
          "snacks_win_backdrop",
          "snacks_win_help",

          -- Common Neovim and plugin UI filetypes.
          "checkhealth",
          "help",
          "man",
          "mason",
          "neo-tree",
          "notify",
          "NvimTree",
          "qf",
          "TelescopePrompt",
          "toggleterm",
        },
        should_enable = function(bufnr)
          return vim.bo[bufnr].buftype == ""
        end,
      })

      -- The plugin creates its defaults before lazy.nvim calls config().
      -- Remove only mappings whose callbacks are Illuminate's own, leaving
      -- any pre-existing user mappings untouched.
      for _, mapping in ipairs({
        { mode = "n", lhs = "<A-n>", callback = illuminate.goto_next_reference },
        { mode = "n", lhs = "<A-p>", callback = illuminate.goto_prev_reference },
        { mode = "o", lhs = "<A-i>", callback = illuminate.textobj_select },
        { mode = "x", lhs = "<A-i>", callback = illuminate.textobj_select },
      }) do
        local current = vim.fn.maparg(mapping.lhs, mapping.mode, false, true)
        if current.callback == mapping.callback then
          vim.keymap.del(mapping.mode, mapping.lhs)
        end
      end
    end,
  }),
}
