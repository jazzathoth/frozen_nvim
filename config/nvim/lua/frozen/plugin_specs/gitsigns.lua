local bindings = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("gitsigns.nvim", {
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Keep Git in the first of the two sign columns; diagnostics use the second.
      sign_priority = 20,
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "?" },
      },
      on_attach = function(buffer)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, description)
          vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = description })
        end

        map("n", bindings.git.next_hunk, gs.next_hunk, "Next Git hunk")
        map("n", bindings.git.previous_hunk, gs.prev_hunk, "Previous Git hunk")
        map("n", bindings.git.preview_hunk, gs.preview_hunk, "Preview Git hunk")
        map("n", bindings.git.diff_index, function() gs.diffthis() end, "Diff file against Git index")
        map("n", bindings.git.diff_head, function() gs.diffthis("HEAD") end, "Diff file against HEAD")
        map("n", bindings.git.blame_line, gs.blame_line, "Blame line")
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)

      local function set_highlights()
        vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#00ff00", bold = true })
        vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ffff00", bold = true })
        vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#ff3030", bold = true })
      end
      set_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("frozen_gitsigns_colors", { clear = true }),
        callback = set_highlights,
      })
    end,
  }),
}
