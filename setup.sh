vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Minimal terminal behavior: leave terminal mode at the prompt, otherwise pass Esc
-- through to the foreground program.
local function terminal_shell_is_foreground()
  local job = vim.b.terminal_job_id
  if not job then
    return true
  end

  local pid = vim.fn.jobpid(job)
  if type(pid) ~= "number" or pid <= 0 then
    return true
  end

  local fd = io.open("/proc/" .. pid .. "/stat")
  if not fd then
    return true
  end

  local stat = fd:read("*a")
  fd:close()

  local rest = stat and stat:match("%)%s*(.*)$")
  if not rest then
    return true
  end

  local fields = vim.split(rest, "%s+", { trimempty = true })
  local pgrp = tonumber(fields[3])
  local tpgid = tonumber(fields[6])
  return pgrp ~= nil and tpgid ~= nil and pgrp == tpgid
end

vim.keymap.set("t", "<Esc>", function()
  if terminal_shell_is_foreground() then
    vim.cmd("stopinsert")
  else
    vim.api.nvim_chan_send(vim.b.terminal_job_id, "\27")
  end
end, { desc = "Leave terminal mode at the shell, else send Esc to the running program" })

-- Split a new terminal to the right or below, inheriting the current working directory.
local function open_terminal_split(split_cmd)
  local cwd = vim.fn.getcwd()
  vim.cmd(split_cmd)
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function term_vsplit()
  open_terminal_split("vsplit")
end

local function term_split()
  open_terminal_split("split")
end

for _, mode in ipairs({ "n", "t", "i" }) do
  vim.keymap.set(mode, "<A-S-=>", term_vsplit, { desc = "Split right with terminal" })
  vim.keymap.set(mode, "<A-+>", term_vsplit, { desc = "Split right with terminal" })
  vim.keymap.set(mode, "<A-S-->", term_split, { desc = "Split down with terminal" })
  vim.keymap.set(mode, "<A-_>", term_split, { desc = "Split down with terminal" })
end

-- Focus movement across splits.
for _, mode in ipairs({ "n", "t", "i" }) do
  vim.keymap.set(mode, "<A-Left>",  "<Cmd>wincmd h<CR>", { desc = "Focus left split" })
  vim.keymap.set(mode, "<A-Right>", "<Cmd>wincmd l<CR>", { desc = "Focus right split" })
  vim.keymap.set(mode, "<A-Up>",    "<Cmd>wincmd k<CR>", { desc = "Focus up split" })
  vim.keymap.set(mode, "<A-Down>",  "<Cmd>wincmd j<CR>", { desc = "Focus down split" })
end

-- Swap the current split with its neighbor.
local function swap_split(dir)
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  local other = vim.api.nvim_get_current_win()
  if other == cur then
    return
  end

  local cur_buf = vim.api.nvim_win_get_buf(cur)
  local other_buf = vim.api.nvim_win_get_buf(other)
  if cur_buf == other_buf then
    return
  end

  local cur_view = vim.api.nvim_win_call(cur, vim.fn.winsaveview)
  local other_view = vim.api.nvim_win_call(other, vim.fn.winsaveview)

  vim.api.nvim_win_set_buf(cur, other_buf)
  vim.api.nvim_win_set_buf(other, cur_buf)
  vim.api.nvim_win_call(cur, function() pcall(vim.fn.winrestview, other_view) end)
  vim.api.nvim_win_call(other, function() pcall(vim.fn.winrestview, cur_view) end)
  vim.api.nvim_set_current_win(other)
end

for _, mode in ipairs({ "n", "t", "i" }) do
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    vim.keymap.set(mode, "<A-" .. key .. ">", function()
      swap_split(key)
    end, { desc = "Swap split with neighbor" })
  end
end

-- Zoom current split.
local zoom_restore_cmd = nil
local function zoom_split()
  if zoom_restore_cmd then
    local cmd = zoom_restore_cmd
    zoom_restore_cmd = nil
    pcall(vim.cmd, cmd)
    return
  end

  local wins = vim.api.nvim_tabpage_list_wins(0)
  local normal_wins = 0
  for _, w in ipairs(wins) do
    local cfg = vim.api.nvim_win_get_config(w)
    if cfg.relative == "" then
      normal_wins = normal_wins + 1
    end
  end

  if normal_wins < 2 then
    return
  end

  zoom_restore_cmd = vim.fn.winrestcmd()
  vim.cmd("wincmd _")
  vim.cmd("wincmd |")
end

for _, mode in ipairs({ "n", "t", "i" }) do
  vim.keymap.set(mode, "<A-z>", zoom_split, { desc = "Toggle zoom on the current split" })
end

-- Close active split.
local function close_split()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd("close")
  else
    vim.notify("Only one window remains", vim.log.levels.WARN)
  end
end

for _, mode in ipairs({ "n", "t", "i" }) do
  vim.keymap.set(mode, "<A-q>", close_split, { desc = "Close active split" })
  vim.keymap.set(mode, "<A-w>", close_split, { desc = "Close active split" })
end

-- Default behavior for an empty start: open a terminal when launched without files.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local untouched = vim.api.nvim_buf_get_name(0) == ""
      and vim.bo.buftype == ""
      and not vim.bo.modified
      and vim.api.nvim_buf_line_count(0) == 1

    if
      vim.fn.argc() == 0
      and vim.fn.has("ttyin") == 1
      and #vim.api.nvim_list_uis() > 0
      and untouched
    then
      vim.schedule(function()
        vim.cmd("terminal")
        vim.cmd("startinsert")
      end)
    end
  end,
})
