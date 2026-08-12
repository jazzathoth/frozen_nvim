# LazyVim prototype migration

This is a working checklist for converting the prototype into an ordinary,
repository-owned Neovim configuration. LazyVim 15.15.0 at commit
`83d90f339defdb109a6ede333865a66ffc7ef6aa` is provenance only. It is not
installed or loaded by the frozen configuration.

## Status meanings

- **Migrated**: configured by tracked Lua without a LazyVim dependency.
- **Pending**: source is pinned for inspection but is not loaded at runtime.
- **Excluded**: deliberately not part of the intended frozen configuration.

## Core behavior

| Area | Status | Repository owner | Notes |
| --- | --- | --- | --- |
| Leader keys and editor options | Migrated | `lua/frozen/options.lua` | Started with the useful, dependency-free subset; every value is editable. |
| Binding values | Migrated | `lua/frozen/bindings.lua` | This is the single place for key strings. |
| Global keymap actions | Migrated | `lua/frozen/keymaps.lua` | No LazyVim keymap helper. Bindings are intentionally a small starting set. |
| Autocommands | Migrated | `lua/frozen/autocmds.lua` | Yank highlight, external-change detection, text wrapping/spell, JSON conceal. |
| Diagnostics | Partial | `lua/frozen/keymaps.lua` | Navigation and floating diagnostics only. Presentation policy remains to be chosen. |
| Project-root detection | Pending | — | Needed primarily by LSP, terminals, and project pickers. |
| Formatting policy | Pending | — | Must distinguish editor routing from project style files. |
| LazyVim news, migrations, and extras UI | Excluded | — | Rolling-distribution machinery. |
| Mason automatic tool installation | Excluded | — | External tools need independent pins and verification. |

## Plugin migration

| Plugin or group | Status | Configuration |
| --- | --- | --- |
| lazy.nvim | Migrated | `lua/frozen/lazy.lua`; loader only, downloads disabled |
| tokyonight.nvim | Migrated | `lua/frozen/plugin_specs/colorscheme.lua` |
| which-key.nvim | Migrated | `lua/frozen/plugin_specs/which_key.lua` |
| gitsigns.nvim | Migrated | `lua/frozen/plugin_specs/gitsigns.lua` |
| mini.icons | Migrated | `lua/frozen/plugin_specs/lualine.lua` |
| lualine.nvim | Migrated | `lua/frozen/plugin_specs/lualine.lua` |
| nvim-treesitter | Partial | Explicit runtime setup and separately verified parser installer; highlighting policy is pending |
| catppuccin | Pending | Alternative colorscheme; not loaded |
| blink.cmp and friendly-snippets | Migrated | Completion from LSP, paths, snippets, and buffers |
| nvim-lspconfig | Migrated | Enables C/C++, Python, Rust, JS/TS, HTML, and Lua configs; external servers remain OS-managed |
| lazydev.nvim | Pending | Optional Lua configuration-development enhancements |
| conform.nvim | Migrated | Manual formatting with per-language formatter fallback lists |
| nvim-lint | Pending | Linter routing |
| snacks.nvim | Migrated | Project file tree, file search, grep, diagnostics list, and terminal only |
| bufferline.nvim | Pending | Buffer/tab UI |
| flash.nvim and mini.ai | Pending | Navigation and text objects |
| grug-far.nvim | Migrated | Project search and replace UI |
| noice.nvim and nui.nvim | Pending | Message, command-line, and popup UI |
| nvim-treesitter-textobjects | Pending | Tree-sitter navigation/text objects |
| nvim-ts-autotag | Pending | HTML/JSX tag behavior |
| persistence.nvim | Migrated | Project/last-session restoration and automatic persistence |
| render-markdown.nvim | Migrated | Terminal-only in-buffer rendering and side preview |
| plenary.nvim | Pending | Dependency; activate only when a migrated plugin requires it |
| todo-comments.nvim | Pending | Comment annotations |
| trouble.nvim | Pending | Diagnostics/location-list UI |
| ts-comments.nvim | Pending | Tree-sitter-aware comments |

All pending plugin sources currently remain in `lua/frozen/plugins.lua` so the
prototype can be inspected at exact commits. Presence in that manifest does not
mean a plugin is active. When the migration is complete, rejected plugins can be
removed from both the manifest and installer.

## External and generated dependencies

These are separate from Neovim plugin commits and need their own policies:

- Neovim binary archive and checksum
- tree-sitter CLI archive and checksum
- parser grammar revisions and native `.so` files
- language servers such as clangd, basedpyright, rust-analyzer, and a TypeScript server
- formatter, linter, debugger, and plugin build artifacts

## Acceptance conditions

The migration is complete only when:

1. No runtime specification or Lua module references `LazyVim` or `lazyvim`.
2. A clean install does not download the LazyVim repository.
3. Every runtime plugin is declared in the central immutable manifest.
4. Plugin options live in repository-owned modules.
5. Binding strings live in `bindings.lua`.
6. Installation succeeds from an empty test HOME.
7. Verification can run without updating or resolving moving branches.
