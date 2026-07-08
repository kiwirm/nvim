local M = {}

local SERVERS = {
    lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
        settings = { runtime = { version = "LuaJIT" } },
    },
    clangd = {
        cmd = { "clangd", "--clang-tidy", "--background-index" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
    },
    ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    },
    ruff = {
        cmd = { "ruff", "server", "--preview" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
        settings = { organizeImports = true, fixAll = true },
        init_options = { settings = { format = { enable = true } } },
    },
    pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "pyrightconfig.json", ".git" },
        settings = {
            python = {
                analysis = {
                    diagnosticSeverityOverrides = { reportMissingImports = "none" },
                },
            },
        },
    },
}

function M.setup()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.general = capabilities.general or {}
    capabilities.general.positionEncodings = { "utf-8", "utf-16" }
    capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

    for name, spec in pairs(SERVERS) do
        spec.capabilities = capabilities
        vim.lsp.config[name] = spec
        vim.lsp.enable(name)
    end

    local lsp_group = vim.api.nvim_create_augroup("my.lsp", {})

    vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_group,
        callback = function(args)
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
            local opts = { buffer = args.buf, noremap = true, silent = true }

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "ga", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "gio", function()
                vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
            end, opts)
            vim.keymap.set("n", "gid", function()
                vim.lsp.buf.code_action({ context = { only = { "source.removeUnused" } }, apply = true })
            end, opts)

            if not client:supports_method("textDocument/willSaveWaitUntil")
                and client:supports_method("textDocument/formatting") then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = lsp_group,
                    buffer = args.buf,
                    callback = function()
                        vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
                    end,
                })
            end
        end,
    })
end

return M
