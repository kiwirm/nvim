local M = {}

local SIDE_PANEL_WIDTH = 0.4

local side_panel = {
    win = nil,
    active_kind = nil,
}

local side_panels = {
    terminal = {
        buf = nil,
        job = nil,
        cmd = { vim.o.shell },
        filetype = "side-terminal",
    },
    claude = {
        buf = nil,
        job = nil,
        cmd = { "claude" },
        filetype = "claude",
    },
}

local function is_side_panel_open()
    return side_panel.win and vim.api.nvim_win_is_valid(side_panel.win)
end

local function is_panel_buf_valid(panel)
    return panel.buf and vim.api.nvim_buf_is_valid(panel.buf)
end

local function create_panel_buffer(panel)
    panel.buf = vim.api.nvim_create_buf(false, false)
    vim.bo[panel.buf].bufhidden = "hide"
    vim.bo[panel.buf].swapfile = false
    vim.bo[panel.buf].filetype = panel.filetype

    if panel.filetype == "claude" then
        vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = panel.buf, noremap = true })
        vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = panel.buf, noremap = true })

        local group = vim.api.nvim_create_augroup("my.claude_panel_" .. panel.buf, { clear = true })
        local saved_timeoutlen
        vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
            group = group,
            buffer = panel.buf,
            callback = function()
                saved_timeoutlen = vim.o.timeoutlen
                vim.o.timeoutlen = 200
            end,
        })
        vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
            group = group,
            buffer = panel.buf,
            callback = function()
                if saved_timeoutlen then
                    vim.o.timeoutlen = saved_timeoutlen
                end
            end,
        })
    end
end

local function close_panel(panel)
    local matches = panel == nil or side_panels[side_panel.active_kind] == panel
    if is_side_panel_open() and matches then
        vim.api.nvim_win_close(side_panel.win, true)
    end
    side_panel.win = nil
    side_panel.active_kind = nil
end

local function ensure_side_panel_window()
    if is_side_panel_open() then
        return side_panel.win
    end

    vim.cmd("vertical rightbelow vsplit")
    side_panel.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(side_panel.win, math.floor(vim.o.columns * SIDE_PANEL_WIDTH))
    return side_panel.win
end

local function set_active_panel(kind)
    side_panel.win = vim.api.nvim_get_current_win()
    side_panel.active_kind = kind
end

local function open_panel(kind)
    local panel = side_panels[kind]
    if panel.job == nil or not is_panel_buf_valid(panel) then
        create_panel_buffer(panel)
    end

    local win = ensure_side_panel_window()
    vim.api.nvim_win_set_buf(win, panel.buf)
    vim.api.nvim_set_current_win(win)
    set_active_panel(kind)

    if panel.job == nil then
        panel.job = vim.fn.termopen(panel.cmd, {
            cwd = vim.uv.cwd(),
            on_exit = function()
                panel.job = nil
            end,
        })
    end

    vim.bo[panel.buf].filetype = panel.filetype
end

function M.use_side_panel_window(kind)
    local win = ensure_side_panel_window()
    vim.api.nvim_set_current_win(win)
    set_active_panel(kind)
    return win
end

function M.toggle_repl()
    if is_side_panel_open() and side_panel.active_kind == "repl" then
        require("dap.repl").close()
        close_panel()
        return
    end

    require("dap.repl").toggle(nil, "lua require('config.sidebar').use_side_panel_window('repl')")
end

function M.toggle(kind)
    if is_side_panel_open() and side_panel.active_kind == kind then
        close_panel(side_panels[kind])
        return
    end

    open_panel(kind)
end

function M.open_claude_and_send(payload)
    local panel = side_panels.claude
    local should_wait = panel.job == nil

    if not is_side_panel_open() or side_panel.active_kind ~= "claude" then
        open_panel("claude")
    end

    local function send()
        if panel.job == nil then
            vim.notify("Claude is not ready yet", vim.log.levels.ERROR)
            return
        end
        vim.fn.chansend(panel.job, payload .. "\n")
    end

    if should_wait then
        vim.defer_fn(send, 100)
    else
        send()
    end
end

return M
