local statusline = require("config.statusline")

local M = {}

local function python_debugger_path()
    local is_win = vim.fn.has("win32") == 1
    local bin = is_win and "/Scripts/python.exe" or "/bin/python"
    local fallback = is_win and "python" or "python3"

    local cwd = vim.uv.cwd()
    local candidates = {
        cwd .. "/.venv" .. bin,
        cwd .. "/venv" .. bin,
        vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv" .. bin,
        fallback,
    }

    for _, path in ipairs(candidates) do
        if path == fallback or vim.fn.executable(path) == 1 then
            return path
        end
    end

    return fallback
end

local MASON_ENSURE = {
    "lua-language-server",
    "pyright",
    "ruff",
    "clangd",
    "typescript-language-server",
    "debugpy",
    "tinymist",
}

function M.setup()
    vim.pack.add({
        "https://github.com/ellisonleao/gruvbox.nvim",
        "https://github.com/stevearc/oil.nvim",
        "https://github.com/folke/snacks.nvim",
        "https://github.com/nvim-lualine/lualine.nvim",
        { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
        "https://github.com/lewis6991/gitsigns.nvim",
        "https://github.com/kylechui/nvim-surround",
        "https://github.com/ggandor/leap.nvim",
        "https://github.com/gbprod/substitute.nvim",
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "master" },
        "https://github.com/neovim/nvim-lspconfig",
        "https://github.com/mason-org/mason.nvim",
        "https://github.com/mfussenegger/nvim-dap",
        "https://github.com/mfussenegger/nvim-dap-python",
        "https://github.com/saghen/blink.lib",
        "https://github.com/saghen/blink.cmp",
        "https://github.com/rafamadriz/friendly-snippets",
        "https://github.com/declancm/cinnamon.nvim",
    })
    vim.pack.add({
        { src = "https://github.com/chomosuke/typst-preview.nvim" },
        { src = "https://github.com/epwalsh/obsidian.nvim" },
        { src = "https://github.com/tidalcycles/vim-tidal" },
    }, { load = false })
    vim.cmd([[colorscheme gruvbox]])

    require("gitsigns").setup({
        signs = {
            add = { text = "┃" },
            change = { text = "┃" },
            delete = { text = "▁" },
            topdelete = { text = "▔" },
            changedelete = { text = "┃" },
            untracked = { text = "┃" },
        },
    })

    require("blink.cmp").setup({
        keymap = { preset = "default" },
        completion = {
            menu = { auto_show = true },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        fuzzy = { implementation = "lua" },
    })

    require("nvim-surround").setup()
    require("cinnamon").setup({ keymaps = { basic = true, extra = false } })

    require("mason").setup()
    local mr = require("mason-registry")
    mr.refresh(function()
        for _, name in ipairs(MASON_ENSURE) do
            local ok, pkg = pcall(mr.get_package, name)
            if ok and not pkg:is_installed() then
                pkg:install()
            end
        end
    end)

    require("dap-python").setup(python_debugger_path(), {
        console = "internalConsole",
    })

    local dap = require("dap")

    local cwd = vim.uv.cwd()
    if cwd and cwd:match("gis%-backend$") then
        dap.configurations.python = dap.configurations.python or {}
        table.insert(dap.configurations.python, {
            type = "python",
            request = "launch",
            name = "report: type=1 title=111111",
            module = "src.scripts.create_report",
            cwd = cwd,
            args = { "--report-type", "1", "--title-ids", "111111" },
            envFile = cwd .. "/.env",
            env = {
                PYDEVD_USE_SYS_MONITORING = "false",
            },
            justMyCode = false,
            console = "internalConsole",
        })
    end
    require("snacks").setup({
        -- Native-nvim picker: renders in a normal window (no fzf/ConPTY), so it
        -- opens far faster than fzf-lua on Windows. Keymaps live in keymaps.lua.
        picker = {
            enabled = true,
            sources = {
                -- show dotfiles (e.g. .env) in the files picker
                files = { hidden = true },
            },
        },
    })
    require("leap").add_default_mappings()
    require("oil").setup()
    require("substitute").setup()

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        once = true,
        callback = function()
            vim.cmd("packadd markview.nvim")
            require("markview").setup({
                preview = {
                    filetypes = { "markdown" },
                    ignore_buftypes = {},
                },
            })
            vim.cmd("packadd obsidian.nvim")
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typst" },
        once = true,
        callback = function()
            vim.cmd("packadd typst-preview.nvim")
            require("typst-preview").setup({
                dependencies_bin = { tinymist = "tinymist" },
            })
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tidal" },
        once = true,
        callback = function()
            vim.cmd("packadd vim-tidal")
        end,
    })

    statusline.setup()

    require("nvim-treesitter.configs").setup({
        ensure_installed = {},
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        modules = {},
        highlight = { enable = true },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ic"] = "@comment.inner",
                    ["ac"] = "@comment.outer",
                },
                selection_modes = {
                    ["@parameter.outer"] = "v",
                    ["@function.outer"] = "V",
                    ["@class.outer"] = "<c-v>",
                },
                include_surrounding_whitespace = false,
            },
        },
    })

    -- nvim-treesitter (master) markdown injection queries crash on nvim 0.12's
    -- runtime ("attempt to call method 'range'"). Override them with empty
    -- queries; markview.nvim handles code-block rendering anyway.
    pcall(vim.treesitter.query.set, "markdown", "injections", "")
    pcall(vim.treesitter.query.set, "markdown_inline", "injections", "")
end

return M
