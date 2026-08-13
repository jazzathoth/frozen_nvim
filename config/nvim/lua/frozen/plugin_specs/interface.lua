local features = require("frozen.settings.features")
local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

local enabled = features.named_tabs or features.modified_buffer_status

return {
  plugin.spec("lualine.nvim", {
    enabled = enabled,
    lazy = false,
    config = function()
      local tabs = require("frozen.tabs")
      local tabline = vim.api.nvim_get_hl(0, { name = "TabLine", link = false })
      local function color(value, fallback)
        return value and ("#%06x"):format(value) or fallback
      end
      local inactive_fg = color(tabline.fg, "#c0c0c0")
      local inactive_bg = color(tabline.bg, "#303030")
      if features.named_tabs then
        tabs.setup()
      end

      local tabline = {}
      if features.named_tabs then
        tabline = {
          lualine_a = {
            {
              "tabs",
              mode = 2,
              max_length = tabs.max_length,
              tab_max_length = 0,
              show_modified_status = true,
              symbols = { modified = "+" },
              tabs_color = {
                active = { fg = inactive_bg, bg = inactive_fg, bold = true },
                inactive = { fg = inactive_fg, bg = inactive_bg },
              },
              fmt = tabs.label,
            },
          },
        }
      end

      local sections
      if features.modified_buffer_status then
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { require("frozen.buffers").status, "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        }
      end

      require("lualine").setup({
        options = {
          always_show_tabline = features.named_tabs,
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = sections,
        tabline = tabline,
      })
      if not features.modified_buffer_status then
        require("lualine").hide({ place = { "statusline" } })
      end
    end,
    keys = features.named_tabs and {
      { keys.tabs.rename, require("frozen.tabs").rename, desc = "Rename current tab" },
    } or {},
  }),
}
