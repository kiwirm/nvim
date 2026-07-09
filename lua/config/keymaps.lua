local M = {}

function M.setup()
    local sidebar = require("config.sidebar")
    vim.keymap.set({ "n", "v", "o" }, "<Space>", "<Nop>", { silent = true })
    vim.keymap.set({ "n", "v" }, ";", ":")
    vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>")
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true })

    vim.keymap.set("n", "<leader>o", ":update<CR> :source $MYVIMRC<CR>")
    vim.keymap.set("n", "<leader>w", ":write<CR>")
    vim.keymap.set("n", "<leader>q", ":quit<CR>")
    vim.keymap.set("n", "<leader>j", "15j")
    vim.keymap.set("n", "<leader>k", "15k")
    vim.keymap.set("n", "<leader>b", ":b#<CR>")
    vim.keymap.set("n", "<leader>v", ":tabnew $MYVIMRC<CR>")
    vim.keymap.set("n", "<leader>a", ":e ~/My\\ Drive/me/notes/todo.md<CR> :vsp ~/My\\ Drive/me/notes/calendar.md<CR>")
    vim.keymap.set("n", "<leader>y", '^vg_"+y')
    vim.keymap.set("n", "<leader>l", function()
        local enabled = vim.wo.number or vim.wo.relativenumber
        vim.wo.number = not enabled
        vim.wo.relativenumber = not enabled
    end, { desc = "Toggle line numbers" })
    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

    vim.keymap.set("n", "gh", vim.diagnostic.open_float)

    vim.keymap.set("n", "<leader>t", function()
        sidebar.toggle("terminal")
    end)
    vim.keymap.set("n", "<leader>c", function()
        sidebar.toggle("claude")
    end)
    vim.keymap.set("n", "<leader>r", function()
        sidebar.toggle_repl()
    end, { desc = "DAP REPL" })
    local dap = require("dap")
    local dap_python = require("dap-python")
    local dap_maps = {
        { "dc", dap.continue,          "DAP continue" },
        { "dn", dap.step_over,         "DAP step over" },
        { "di", dap.step_into,         "DAP step into" },
        { "do", dap.step_out,          "DAP step out" },
        { "db", dap.toggle_breakpoint, "DAP toggle breakpoint" },
        { "dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, "DAP conditional breakpoint" },
        { "dt", dap_python.test_method, "DAP debug test method" },
        { "dT", dap_python.test_class,  "DAP debug test class" },
    }
    for _, m in ipairs(dap_maps) do
        vim.keymap.set("n", "<leader>" .. m[1], m[2], { desc = m[3] })
    end

    vim.keymap.set("n", "<leader>x", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local lnum = cursor[1] - 1
        local line = vim.api.nvim_get_current_line()
        local path = vim.api.nvim_buf_get_name(bufnr)
        local diags = vim.diagnostic.get(bufnr, { lnum = lnum })

        if #diags == 0 then
            vim.notify("No diagnostics on current line", vim.log.levels.WARN)
            return
        end

        local d = diags[1]
        local source = d.source or "Unknown"
        local code = d.code and (" [" .. tostring(d.code) .. "]") or ""
        local payload = table.concat({
            "File: " .. path,
            "Line " .. tostring(cursor[1]) .. ": " .. line,
            "Diagnostic (" .. source .. code .. "): " .. (d.message or ""),
        }, "\n")

        sidebar.open_claude_and_send(payload)
    end, { desc = "Submit current diagnostic+line to Claude" })

    vim.keymap.set("n", "<leader>R", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(bufnr)
        local payload = table.concat({
            "Please perform a code review for this file.",
            "Prioritize findings by severity, with concrete fixes and missing tests.",
            "File: " .. path,
            "Read the file directly from disk; do not ask me to paste it.",
        }, "\n")

        sidebar.open_claude_and_send(payload)
    end, { desc = "Submit current file for Claude code review" })

    vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
    local pick = function(source) return function() require("snacks").picker[source]() end end
    vim.keymap.set("n", "<leader>f", pick("files"))
    vim.keymap.set("n", "<leader>F", pick("resume")) -- snacks resume is global (last picker), not per-source
    vim.keymap.set("n", "<leader>/", pick("grep"))
    vim.keymap.set("n", "<leader>?", pick("resume"))
    vim.keymap.set("n", "<leader>gd", pick("git_status"))
    vim.keymap.set("n", "<leader>gb", pick("git_branches"))
    vim.keymap.set("n", "<leader>gc", pick("git_log"))
    vim.keymap.set("n", "<leader>gh", pick("git_log_file"))
    vim.keymap.set("n", "<leader>4", pick("buffers"))
    vim.keymap.set("n", "<leader>2", pick("lsp_symbols"))
    vim.keymap.set("n", "<leader>3", pick("lsp_workspace_symbols"))
    vim.keymap.set("n", "<leader>1", pick("treesitter"))
    vim.keymap.set("n", "<leader>h", pick("help"))
    vim.keymap.set("n", "<leader>H", pick("help"))
    vim.keymap.set("n", "<leader>;", pick("commands"))
    vim.keymap.set("n", "<leader>:", pick("commands"))
    vim.keymap.set("n", "<leader><leader>", pick("pickers"))

    vim.keymap.set("n", "gs", require("substitute").operator, { noremap = true })
    vim.keymap.set("n", "gss", require("substitute").line, { noremap = true })
    vim.keymap.set("x", "S", require("substitute").visual, { noremap = true })
    vim.keymap.set("n", "gX", require("substitute.exchange").operator, { noremap = true })
    vim.keymap.set("n", "gXX", require("substitute.exchange").line, { noremap = true })
    vim.keymap.set("x", "X", require("substitute.exchange").visual, { noremap = true })
end

return M
