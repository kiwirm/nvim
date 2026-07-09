local M = {}

local git_changed_files_counts = nil

local function buf_label(buf)
    local n = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
    return n == "" and "[No Name]" or n
end

local function two_buffer_component()
    local current = vim.api.nvim_get_current_buf()
    local other = vim.fn.bufnr("#")
    if other <= 0 or other == current or vim.fn.buflisted(other) ~= 1 then
        other = nil
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if b ~= current and vim.fn.buflisted(b) == 1 then
                other = b
                break
            end
        end
    end

    return buf_label(current) .. ":" .. (other and buf_label(other) or "[No Other]")
end

local function tabs_with_buffers_component()
    local current_tab = vim.api.nvim_get_current_tabpage()
    local labels = {}

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        local tab_number = vim.api.nvim_tabpage_get_number(tab)
        if tab == current_tab then
            table.insert(labels, tab_number .. ":" .. two_buffer_component())
        else
            table.insert(labels, tostring(tab_number))
        end
    end

    return table.concat(labels, "/")
end

local GIT_LINE_SPECS = {
    { key = "added",   prefix = "+", hl = "DiffAdd" },
    { key = "changed", prefix = "~", hl = "DiffChange" },
    { key = "removed", prefix = "-", hl = "DiffDelete" },
}

local function git_line_changes_component()
    local gitsigns = vim.b.gitsigns_status_dict
    if not gitsigns then
        return ""
    end

    local parts = {}
    for _, spec in ipairs(GIT_LINE_SPECS) do
        local n = gitsigns[spec.key] or 0
        if n > 0 then
            table.insert(parts, "%#" .. spec.hl .. "#" .. spec.prefix .. n)
        end
    end

    if #parts == 0 then
        return ""
    end

    return " " .. table.concat(parts, "") .. "%* "
end

local function git_branch_component()
    local gitsigns = vim.b.gitsigns_status_dict
    if not gitsigns or not gitsigns.head or gitsigns.head == "" then
        return ""
    end

    if #gitsigns.head > 16 then
        return gitsigns.head:sub(1, 16)
    end

    return gitsigns.head
end

function M.update_git_changed_files_count()
    local git_dir = vim.fs.find(".git", { upward = true, path = vim.uv.cwd() })[1]
    if not git_dir then
        git_changed_files_counts = nil
        return
    end

    local repo_root = vim.fs.dirname(git_dir)
    local result = vim.system({ "git", "status", "--porcelain" }, {
        cwd = repo_root,
        text = true,
    }):wait()

    if result.code ~= 0 then
        git_changed_files_counts = nil
        return
    end

    local counts = { added = 0, changed = 0, removed = 0 }
    for line in string.gmatch(result.stdout or "", "[^\r\n]+") do
        local x = line:sub(1, 1)
        local y = line:sub(2, 2)

        if x == "?" and y == "?" or x == "A" or y == "A" then
            counts.added = counts.added + 1
        elseif x == "D" or y == "D" then
            counts.removed = counts.removed + 1
        else
            counts.changed = counts.changed + 1
        end
    end

    git_changed_files_counts = counts
end

local function git_file_changes_component()
    if git_changed_files_counts == nil then
        M.update_git_changed_files_count()
    end

    if not git_changed_files_counts then
        return ""
    end

    local parts = {}
    for _, spec in ipairs(GIT_LINE_SPECS) do
        local n = git_changed_files_counts[spec.key] or 0
        if n > 0 then
            table.insert(parts, spec.prefix .. n)
        end
    end

    return table.concat(parts, "")
end

local function git_branch_files_component()
    local branch = git_branch_component()
    local changes = git_file_changes_component()

    if branch ~= "" and changes ~= "" then
        return branch .. ":" .. changes
    end

    return branch .. changes
end

function M.setup()
    require("lualine").setup({
        options = {
            component_separators = "",
            section_separators = "",
            icons_enabled = false,
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { tabs_with_buffers_component },
            lualine_c = {
                function()
                    local total = vim.fn.line("$")
                    local loc = vim.fn.len(vim.fn.filter(vim.fn.getline(1, "$"), 'v:val =~ "\\S"'))
                    return total .. "l/" .. loc .. "loc"
                end,
            },
            lualine_x = {
                { "lsp_status", symbols = { separator = "/" } },
            },
            lualine_y = {
                { git_line_changes_component, color = nil, padding = 0 },
            },
            lualine_z = {
                git_branch_files_component,
            },
        },
        extensions = {},
    })
end

return M
