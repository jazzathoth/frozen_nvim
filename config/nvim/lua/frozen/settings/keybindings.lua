-- Edit key strings here. Plugin configuration modules import this table.
return {
  files = {
    tree = "\\e", find = "\\ff", grep = "\\fg", new = "\\fn",
    open_tab = "t", open_split = "<C-s>", open_vsplit = "<C-v>",
  },
  buffers = { all = "\\ba", displayed = "\\bb", orphaned = "\\bo", modified = "\\bm" },
  tabs = { rename = "\\tr" },
  git = {
    next_hunk = "]h",
    previous_hunk = "[h",
    preview_hunk = "\\ghp",
    diff_index = "\\ghd",
    diff_head = "\\ghD",
    blame_line = "\\ghb",
  },
  windows = { left = "<C-h>", down = "<C-j>", up = "<C-k>", right = "<C-l>", split_below = "\\-", split_right = "\\|" },
  diagnostics = { line = "\\cd", next = "]d", previous = "[d", list = "\\xx" },
  lsp = {
    definition = "gD", preview_definition = "gd", references = "gr",
    rename = "\\cr", action = "\\ca", hover = "K",
  },
  completion = { next = "<Tab>", previous = "<S-Tab>", accept = "<CR>", cancel = "<C-e>" },
  markdown = { toggle = "\\mt", preview = "\\mp" },
  format = "\\cf",
  replace = "\\sr",
  session = { restore = "\\qs", last = "\\ql", stop = "\\qd" },
  terminal = { "<C-/>", "<C-_>" },
  quit_all = "\\qq",
}
