local M = {}

local label = " %t"
local owned = {}

local function is_normal_file_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].buflisted
    and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function is_normal_window(winid)
  return vim.api.nvim_win_is_valid(winid)
    and vim.api.nvim_win_get_config(winid).relative == ""
end

local function update_window(winid)
  if not is_normal_window(winid) then
    return
  end

  local current = vim.wo[winid].winbar
  local eligible = is_normal_file_buffer(vim.api.nvim_win_get_buf(winid))

  if eligible then
    -- Do not replace a winbar deliberately installed by another component.
    if current == "" or (owned[winid] and current == label) then
      vim.wo[winid].winbar = label
      owned[winid] = true
    else
      owned[winid] = nil
    end
  else
    -- Clear only a label created by this module.
    if owned[winid] and current == label then
      vim.wo[winid].winbar = ""
    end
    owned[winid] = nil
  end
end

local function update_current_window()
  update_window(vim.api.nvim_get_current_win())
end

local function apply_highlights()
  vim.api.nvim_set_hl(0, "WinBar", { link = "StatusLine" })
  vim.api.nvim_set_hl(0, "WinBarNC", { link = "StatusLineNC" })
end

function M.setup()
  if not require("frozen.settings.features").pane_labels then
    return
  end

  apply_highlights()

  local group = vim.api.nvim_create_augroup("frozen_pane_labels", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- Run after the colorscheme and its other callbacks finish resetting
      -- highlight groups.
      vim.schedule(apply_highlights)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "BufFilePost" }, {
    group = group,
    callback = update_current_window,
  })

  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    update_window(winid)
  end
end

return M
