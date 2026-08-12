local lazy_config = require("lazy.core.config")
local data_plugins = vim.fn.stdpath("data") .. "/lazy"
local pins = {}

for _, pin in ipairs(require("frozen.plugins")) do
  pins[pin.name] = pin
  local directory = data_plugins .. "/" .. pin.name
  local result = vim.system({ "git", "-C", directory, "rev-parse", "HEAD" }, { text = true }):wait()
  assert(result.code == 0, "cannot inspect plugin checkout: " .. pin.name)
  local actual = vim.trim(result.stdout)
  assert(actual == pin.commit, ("plugin %s: expected %s, got %s"):format(pin.name, pin.commit, actual))
end

for name, runtime in pairs(lazy_config.plugins) do
  local pin = assert(pins[name], "runtime plugin is not in the frozen manifest: " .. name)
  if name ~= "lazy.nvim" then
    assert(runtime.commit == pin.commit, "runtime commit differs from manifest: " .. name)
  end
end

assert(lazy_config.plugins.LazyVim == nil, "LazyVim is still a runtime plugin")
assert(package.loaded.lazyvim == nil, "LazyVim was loaded")

local ts_config = require("nvim-treesitter.config")
local ts_parsers = require("nvim-treesitter.parsers")
for _, parser in ipairs(require("frozen.parsers")) do
  assert(vim.tbl_contains(require("nvim-treesitter").get_installed(), parser), "missing parser: " .. parser)
  local expected = assert(ts_parsers[parser].install_info.revision, "parser has no pinned revision: " .. parser)
  local revision_file = ts_config.get_install_dir("parser-info") .. "/" .. parser .. ".revision"
  local file = assert(io.open(revision_file, "r"), "parser revision is missing: " .. parser)
  local actual = vim.trim(file:read("*a"))
  file:close()
  assert(actual == expected, ("parser %s: expected %s, got %s"):format(parser, expected, actual))
end
