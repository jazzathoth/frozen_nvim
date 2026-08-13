local M = {}

local function is_normal_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buflisted
    and vim.bo[buf].buftype == ""
end

local function is_normal_window(win)
  return vim.api.nvim_win_is_valid(win)
    and vim.api.nvim_win_get_config(win).relative == ""
    and is_normal_buffer(vim.api.nvim_win_get_buf(win))
end

local function visible_windows(buf)
  return vim.tbl_filter(is_normal_window, vim.fn.win_findbuf(buf))
end

local function tab_numbers(windows)
  local tabs = {}
  for _, win in ipairs(windows) do
    local tab = vim.api.nvim_win_get_tabpage(win)
    tabs[vim.api.nvim_tabpage_get_number(tab)] = true
  end
  local numbers = vim.tbl_keys(tabs)
  table.sort(numbers)
  return numbers
end

local function editor_window()
  local current = vim.api.nvim_get_current_win()
  if is_normal_window(current) then
    return current
  end

  local previous = vim.fn.win_getid(vim.fn.winnr("#"))
  if previous ~= 0 and is_normal_window(previous) then
    return previous
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_normal_window(win) then
      return win
    end
  end
end

local function description(buf, windows)
  local modified = vim.bo[buf].modified and "[+] " or ""
  if #windows == 0 then
    return modified .. "orphaned"
  end
  local tabs = tab_numbers(windows)
  local label = #tabs == 1 and "tab " or "tabs "
  return modified .. "displayed: " .. label .. table.concat(tabs, ", ")
end

local function items(kind)
  local result = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_normal_buffer(buf) then
      local windows = visible_windows(buf)
      local displayed = #windows > 0
      local modified = vim.bo[buf].modified
      local include = kind == "all"
        or kind == "displayed" and displayed
        or kind == "orphaned" and not displayed
        or kind == "modified" and modified
      if include then
        local name = vim.api.nvim_buf_get_name(buf)
        local display_name = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
        local location = description(buf, windows)
        result[#result + 1] = {
          buf = buf,
          file = name ~= "" and name or nil,
          name = display_name,
          location = location,
          text = display_name .. " " .. location,
        }
      end
    end
  end
  table.sort(result, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  return result
end

local function navigate(buf)
  local windows = visible_windows(buf)
  if #windows == 0 then
    return false
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  table.sort(windows, function(a, b)
    local a_current = vim.api.nvim_win_get_tabpage(a) == current_tab
    local b_current = vim.api.nvim_win_get_tabpage(b) == current_tab
    if a_current ~= b_current then
      return a_current
    end
    return a < b
  end)
  vim.api.nvim_set_current_win(windows[1])
  return true
end

local function replace(origin, buf)
  if not origin or not is_normal_window(origin) then
    origin = editor_window()
  end
  if not origin then
    vim.notify("No normal editor window is available", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_set_current_win(origin)
  vim.api.nvim_win_set_buf(origin, buf)
end

local titles = {
  all = "All buffers (displayed navigates; orphaned replaces)",
  displayed = "Displayed buffers (Enter navigates)",
  orphaned = "Orphaned buffers (Enter replaces current editor)",
  modified = "Modified buffers (displayed navigates; orphaned replaces)",
}

function M.open(kind)
  assert(titles[kind], "unknown buffer menu: " .. tostring(kind))
  local origin = editor_window()

  local function selected_buffer(item)
    return item and item.buf and vim.api.nvim_buf_is_valid(item.buf) and item.buf or nil
  end

  local function open_in_tab(_, item)
    local buf = selected_buffer(item)
    if not buf then
      return
    end
    if not navigate(buf) then
      vim.cmd(("tab sbuffer %d"):format(buf))
    end
  end

  local function open_in_split(picker, item, vertical)
    local buf = selected_buffer(item)
    if not buf then
      return
    end
    picker:close()
    vim.schedule(function()
      local target = origin
      if not target or not is_normal_window(target) then
        target = editor_window()
      end
      if not target then
        vim.notify("No normal editor window is available", vim.log.levels.WARN)
        return
      end
      vim.api.nvim_set_current_win(target)
      vim.cmd((vertical and "vertical sbuffer %d" or "sbuffer %d"):format(buf))
    end)
  end

  return Snacks.picker({
    source = "frozen_" .. kind .. "_buffers",
    title = titles[kind],
    finder = function()
      return items(kind)
    end,
    format = function(item)
      return {
        { item.name, "SnacksPickerFile" },
        { "  " },
        { item.location, item.location:find("orphaned", 1, true) and "WarningMsg" or "Comment" },
      }
    end,
    preview = "file",
    actions = {
      confirm = function(picker, item)
        if not item then
          return
        end
        picker:close()
        vim.schedule(function()
          if kind == "displayed" then
            navigate(item.buf)
          elseif kind == "orphaned" then
            replace(origin, item.buf)
          elseif not navigate(item.buf) then
            replace(origin, item.buf)
          end
        end)
      end,
      frozen_tab = function(picker, item)
        picker:close()
        vim.schedule(function()
          open_in_tab(picker, item)
        end)
      end,
      frozen_split = function(picker, item)
        open_in_split(picker, item, false)
      end,
      frozen_vsplit = function(picker, item)
        open_in_split(picker, item, true)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-x>"] = { "bufdelete", mode = { "n", "i" } },
          ["<c-s>"] = { "frozen_split", mode = { "n", "i" } },
          ["<c-v>"] = { "frozen_vsplit", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["t"] = "frozen_tab",
          ["<c-s>"] = "frozen_split",
          ["<c-v>"] = "frozen_vsplit",
          ["dd"] = "bufdelete",
        },
      },
    },
  })
end

function M.status()
  local modified = 0
  local orphaned = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_normal_buffer(buf) then
      if vim.bo[buf].modified then
        modified = modified + 1
      end
      if #visible_windows(buf) == 0 then
        orphaned = orphaned + 1
      end
    end
  end
  if modified == 0 and orphaned == 0 then
    return ""
  end
  return ("Modified: %d | Orphaned: %d"):format(modified, orphaned)
end

return M
