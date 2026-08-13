local M = {}

local function normal_file(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
end

function M.setup()
  local group = vim.api.nvim_create_augroup("frozen_tabs", { clear = true })

  local function refresh()
    vim.schedule(function()
      if package.loaded.lualine then
        require("lualine").refresh({
          force = true,
          scope = "all",
          place = { "tabline", "statusline" },
        })
      end
    end)
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      if normal_file(event.buf) then
        vim.t.frozen_last_file = vim.api.nvim_buf_get_name(event.buf)
      end
      refresh()
    end,
  })

  vim.api.nvim_create_autocmd({ "TabNew", "TabClosed", "TabEnter", "VimResized", "BufModifiedSet" }, {
    group = group,
    callback = refresh,
  })
end

local function truncate(name, width)
  if vim.fn.strdisplaywidth(name) <= width then
    return name
  end
  local chars = vim.fn.strchars(name)
  local kept = math.max(width - 1, 1)
  local left = math.ceil(kept / 2)
  local right = math.floor(kept / 2)
  local function result()
    return vim.fn.strcharpart(name, 0, left)
      .. "…"
      .. vim.fn.strcharpart(name, chars - right, right)
  end
  while left + right > 1 and vim.fn.strdisplaywidth(result()) > width do
    if left > right then
      left = left - 1
    else
      right = right - 1
    end
  end
  return result()
end

local function full_label(default, context)
  local tab = vim.api.nvim_list_tabpages()[context.tabnr]
  if not tab then
    return default
  end

  local ok, manual = pcall(vim.api.nvim_tabpage_get_var, tab, "tabname")
  if ok and manual ~= "" then
    return manual
  end

  local ok_last, last = pcall(vim.api.nvim_tabpage_get_var, tab, "frozen_last_file")
  if ok_last and type(last) == "string" and last ~= "" then
    return vim.fn.fnamemodify(last, ":t")
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if normal_file(buf) then
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    end
  end
  return default
end

function M.label(default, context)
  local tab_count = math.max(#vim.api.nvim_list_tabpages(), 1)
  local number_width = #tostring(tab_count)
  -- Number, optional compact modified marker, separating space, padding, and
  -- divider consume this much of each tab. Names retain at least four cells;
  -- below that threshold Lualine may elide distant tabs instead.
  local overhead = number_width + 5
  local name_width = math.max(4, math.floor((vim.o.columns - 1) / tab_count) - overhead)
  return truncate(full_label(default, context), name_width)
end

function M.max_length()
  return vim.o.columns
end

function M.rename()
  vim.ui.input({ prompt = "Tab name (empty restores automatic name): " }, function(name)
    if name == nil then
      return
    end
    if name == "" then
      pcall(vim.api.nvim_tabpage_del_var, 0, "tabname")
    else
      vim.api.nvim_tabpage_set_var(0, "tabname", name)
    end
    require("lualine").refresh({ force = true, place = { "tabline" } })
  end)
end

return M
