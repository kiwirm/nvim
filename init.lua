--- @diagnostic disable: undefined-global
---

local is_win = vim.fn.has("win32") == 1
local sep = is_win and ";" or ":"
local mise_shims = is_win
    and (vim.fn.expand("$LOCALAPPDATA") .. "\\mise\\shims")
    or vim.fn.expand("~/.local/share/mise/shims")
if vim.fn.isdirectory(mise_shims) == 1 then
    vim.env.PATH = mise_shims .. sep .. vim.env.PATH
end
-- Shims work but re-resolve the tool on every spawn (~80ms each on Windows),
-- which makes tools like fzf/rg feel sluggish. Resolve the real bin dirs and
-- put them ahead of the shims. Done async so it never slows startup.
if vim.fn.executable("mise") == 1 then
    vim.system({ "mise", "bin-paths" }, { text = true }, function(res)
        if res.code ~= 0 or not res.stdout then return end
        local dirs = {}
        for line in res.stdout:gmatch("[^\r\n]+") do
            if line ~= "" then dirs[#dirs + 1] = line end
        end
        if #dirs > 0 then
            vim.schedule(function()
                vim.env.PATH = table.concat(dirs, sep) .. sep .. vim.env.PATH
            end)
        end
    end)
end

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
