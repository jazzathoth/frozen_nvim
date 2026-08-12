local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("conform.nvim", {
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { keys.format, function() require("conform").format({ async = true, lsp_format = "fallback" }) end, mode = { "n", "x" }, desc = "Format" },
    },
    opts = {
      formatters_by_ft = {
        c = { "clang-format" }, cpp = { "clang-format" },
        dart = { lsp_format = "fallback" },
        python = { "ruff_format", "black", stop_after_first = true },
        rust = { "rustfmt", lsp_format = "fallback" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        lua = { "stylua" },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  }),
}
