local M = {}

function M.setup()
    vim.api.nvim_create_user_command("OpenPdf", function()
        local filepath = vim.api.nvim_buf_get_name(0)
        if filepath:match("%.typ$") then
            local pdf_path = filepath:gsub("%.typ$", ".pdf")
            vim.system({ "open", pdf_path })
        end
    end, {})

    -- Like `gf`, but reveals the file under the cursor in the OS file manager
    -- (Explorer/Finder) instead of opening it in nvim.
    vim.api.nvim_create_user_command("RevealInExplorer", function()
        local cfile = vim.fn.expand("<cfile>")
        if cfile == "" then
            vim.notify("gf: no file under cursor", vim.log.levels.WARN)
            return
        end
        local base = vim.fn.expand("%:p:h")
        local target
        for _, c in ipairs({ cfile, base .. "/" .. cfile, vim.fn.getcwd() .. "/" .. cfile }) do
            local ex = vim.fn.expand(c)
            if vim.fn.filereadable(ex) == 1 or vim.fn.isdirectory(ex) == 1 then
                target = vim.fn.fnamemodify(ex, ":p")
                break
            end
        end
        if not target then
            local found = vim.fn.findfile(cfile, base .. ";" .. vim.fn.getcwd())
            target = found ~= "" and vim.fn.fnamemodify(found, ":p") or nil
        end
        if not target then
            vim.notify("gf: can't find file '" .. cfile .. "'", vim.log.levels.WARN)
            return
        end
        if vim.fn.has("win32") == 1 then
            -- explorer /select reveals & highlights the file; string form so
            -- the path is quoted correctly for cmd.exe (handles spaces).
            vim.fn.jobstart('explorer.exe /select,"' .. target:gsub("/", "\\") .. '"')
        elseif vim.fn.has("mac") == 1 then
            vim.system({ "open", "-R", target })
        else
            vim.system({ "xdg-open", vim.fn.fnamemodify(target, ":h") })
        end
    end, { desc = "Reveal file under cursor in OS file manager" })
end

return M
