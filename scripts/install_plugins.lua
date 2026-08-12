local script = debug.getinfo(1, "S").source:sub(2)
local repo = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(script)))
local destination = assert(arg[1], "usage: install_plugins.lua PLUGIN_DIRECTORY")
local manifest = assert(loadfile(repo .. "/config/nvim/lua/frozen/plugins.lua"))()

vim.fn.mkdir(destination, "p")

local function run(command)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, table.concat(command, " ") .. "\n" .. (result.stderr or result.stdout or ""))
end

for _, plugin in ipairs(manifest) do
  local directory = destination .. "/" .. plugin.name
  if vim.fn.isdirectory(directory .. "/.git") == 0 then
    vim.fn.mkdir(directory, "p")
    run({ "git", "-C", directory, "init" })
    run({ "git", "-C", directory, "remote", "add", "origin", plugin.url })
  else
    local remote = vim.trim(vim.system({ "git", "-C", directory, "remote", "get-url", "origin" }, { text = true }):wait().stdout or "")
    assert(remote == plugin.url, ("unexpected remote for %s: %s"):format(plugin.name, remote))
  end
  local head_result = vim.system({ "git", "-C", directory, "rev-parse", "HEAD" }, { text = true }):wait()
  local head = head_result.code == 0 and vim.trim(head_result.stdout or "") or ""
  if head ~= plugin.commit then
    run({ "git", "-C", directory, "fetch", "--depth=1", "origin", plugin.commit })
    run({ "git", "-C", directory, "checkout", "--detach", plugin.commit })
  end
  print(("verified  %-32s %s"):format(plugin.name, plugin.commit))
end
