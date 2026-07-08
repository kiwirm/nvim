--- @diagnostic disable: undefined-global
---

local config_lua = vim.fn.stdpath("config") .. "/lua"
package.path = table.concat({
    config_lua .. "/?.lua",
    config_lua .. "/?/init.lua",
    package.path,
}, ";")

require("config.config").setup()
require("config.plugins").setup()
require("config.lsp").setup()
require("config.keymaps").setup()
require("config.commands").setup()
require("config.autocmds").setup()
