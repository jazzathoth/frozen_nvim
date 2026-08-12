-- Use a conventional hanging indent:
--
-- call(
--     argument,
-- )
--
-- Python's built-in indenter defaults to two levels after an opening
-- delimiter and aligns the closing delimiter with the last content line.
vim.g.python_indent = {
  open_paren = "shiftwidth()",
  nested_paren = "shiftwidth()",
  continue = "shiftwidth()",
  closed_paren_align_last_line = false,
}
