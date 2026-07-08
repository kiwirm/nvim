local M = {}

function M.setup()
    local COLEMAK = "qwfpgjluy\\;arstdhneiozxcvbkm"
    local QWERTY = "qwertyuiopasdfghjkl\\;zxcvbnm"
    local COLEMAK_UPPER = string.gsub(string.upper(COLEMAK), ";", ":")
    local QWERTY_UPPER = string.gsub(string.upper(QWERTY), ";", ":")
    vim.opt.langmap = COLEMAK .. COLEMAK_UPPER .. ";" .. QWERTY .. QWERTY_UPPER

    local modes = { "n", "v", "x", "o" }
    for i = 1, #COLEMAK do
        local c = COLEMAK:sub(i, i)
        local q = QWERTY:sub(i, i)
        for _, mode in ipairs(modes) do
            vim.keymap.set(mode, "<C-" .. c .. ">", "<C-" .. q .. ">", { noremap = true })
        end
    end

    vim.g.mapleader = " "
    vim.o.foldignore = ""
    vim.o.number = true
    vim.o.signcolumn = "yes"
    vim.o.termguicolors = true
    vim.o.wrap = false
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
    vim.o.softtabstop = 4
    vim.o.expandtab = true
    vim.o.swapfile = false
    vim.o.clipboard = "unnamedplus"
    vim.o.scrolloff = 3
    vim.o.ignorecase = true
    vim.o.cmdheight = 0
    vim.o.showtabline = 0
    vim.o.splitright = true
    vim.o.autoread = true
    vim.opt.list = true
    vim.opt.listchars = { tab = "→ ", trail = "·", leadmultispace = "│   " }

    local indent_group = vim.api.nvim_create_augroup("my.indent", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = indent_group,
        pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "html", "json", "yaml", "markdown" },
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end,
    })

    vim.diagnostic.config({
        float = { source = "always" },
    })

    vim.cmd("set completeopt+=noselect")
    vim.cmd([[cabbrev h setup help]])
end

return M
