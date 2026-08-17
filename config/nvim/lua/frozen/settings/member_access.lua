-- Member-access syntax used by the enhanced LSP hover. Languages may appear
-- in more than one section when they support more than one operator.
--
-- This table is intentionally repository-owned instead of inferred from an
-- LSP server's completion trigger list: those lists also contain unrelated
-- syntax such as quotes, JSX delimiters, and annotation characters.
return {
  -- These servers already provide useful native hover output. Keep their
  -- operator entries below so augmentation can be enabled later by removing
  -- the filetype from this list.
  disabled_filetypes = {
    "c",
    "cpp",
    "rust",
  },

  -- Lua patterns matched against completion labels before they are displayed
  -- in the compact member summary. This does not affect normal completion.
  ignore_patterns = {
    "^_",
  },

  operators = {
    {
      operator = ".",
      filetypes = {
        "ada",
        "apex",
        "c",
        "cpp",
        "c_sharp",
        "dart",
        "d",
        "elixir",
        "fsharp",
        "go",
        "groovy",
        "hcl",
        "java",
        "javascript",
        "javascriptreact",
        "julia",
        "kotlin",
        "lua",
        "nim",
        "nix",
        "objc",
        "objcpp",
        "ocaml",
        "ps1",
        "python",
        "ruby",
        "rust",
        "scala",
        "solidity",
        "sql",
        "svelte",
        "swift",
        "terraform",
        "typescript",
        "typescriptreact",
        "vala",
        "vue",
        "zig",
      },
    },
    {
      operator = "->",
      filetypes = {
        "c",
        "cpp",
        "objc",
        "objcpp",
        "perl",
        "php",
      },
    },
    {
      operator = "::",
      filetypes = {
        "cpp",
        "php",
        "ruby",
        "rust",
      },
    },
    {
      operator = ":",
      filetypes = {
        "erlang",
        "lua",
      },
    },
    {
      operator = "%",
      filetypes = {
        "fortran",
      },
    },
    {
      operator = "#",
      filetypes = {
        "ocaml",
      },
    },
    {
      operator = "$",
      filetypes = {
        "r",
      },
    },
    {
      operator = "@",
      filetypes = {
        "r",
      },
    },
  },
}
