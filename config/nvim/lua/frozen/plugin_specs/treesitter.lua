local plugin = require("frozen.plugin")

return {
  plugin.spec("nvim-treesitter", {
    lazy = false,
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("frozen_treesitter", { clear = true }),
        pattern = { "bash", "c", "cpp", "html", "javascript", "json", "kotlin", "lua", "markdown", "python", "rust", "typescript", "yaml" },
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  }),
}
