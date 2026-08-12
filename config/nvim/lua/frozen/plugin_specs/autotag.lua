local plugin = require("frozen.plugin")

return {
  plugin.spec("nvim-ts-autotag", {
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
    },
  }),
}
