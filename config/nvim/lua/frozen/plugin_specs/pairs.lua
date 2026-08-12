local plugin = require("frozen.plugin")

return {
  plugin.spec("mini.pairs", {
    event = "InsertEnter",
    opts = {},
  }),
}
