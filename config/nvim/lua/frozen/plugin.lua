local M = {}
local pins = {}

for _, plugin in ipairs(require("frozen.plugins")) do
  pins[plugin.name] = plugin
end

function M.spec(name, config)
  local pin = assert(pins[name], "plugin is not pinned: " .. name)
  return vim.tbl_deep_extend("force", {
    name = pin.name,
    url = pin.url,
    commit = pin.commit,
  }, config or {})
end

return M

