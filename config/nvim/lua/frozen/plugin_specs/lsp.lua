local keys = require("frozen.settings.keybindings")
local plugin = require("frozen.plugin")

return {
  plugin.spec("nvim-lspconfig", {
    lazy = false,
    dependencies = { "blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      -- Keep supported servers listed here, but enable only those whose
      -- external command is available. Installing an LSP and restarting
      -- Neovim is therefore enough; absent servers do not produce errors.
      local servers = {
        { name = "basedpyright", command = "basedpyright-langserver" },
        { name = "clangd", command = "clangd" },
        { name = "rust_analyzer", command = "rust-analyzer" },
        { name = "dartls", command = "dart" },
        { name = "ts_ls", command = "typescript-language-server" },
        { name = "html", command = "vscode-html-language-server" },
        { name = "jsonls", command = "vscode-json-language-server" },
        { name = "yamlls", command = "yaml-language-server" },
        { name = "taplo", command = "taplo" },
        { name = "lemminx", command = "lemminx" },
        { name = "lua_ls", command = "lua-language-server" },
      }
      for _, server in ipairs(servers) do
        if vim.fn.executable(server.command) == 1 then
          vim.lsp.config(server.name, { capabilities = capabilities })
          vim.lsp.enable(server.name)
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("frozen_lsp_keys", { clear = true }),
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", keys.lsp.definition, vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Definition" }))
          vim.keymap.set("n", keys.lsp.references, vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
          vim.keymap.set("n", keys.lsp.rename, vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set({ "n", "x" }, keys.lsp.action, vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
          vim.keymap.set("n", keys.lsp.hover, vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
        end,
      })
    end,
  }),
}
