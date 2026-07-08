local M = {}

function M.setup()
    local statusline = require("config.statusline")
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.txt", "*.md", "*.typ" },
        callback = function()
            vim.opt_local.wrap = true
            vim.opt_local.linebreak = true
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
        end,
    })

    vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold", "CursorHoldI" }, {
        command = "checktime",
    })

    vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
        callback = statusline.update_git_changed_files_count,
    })
end

return M
