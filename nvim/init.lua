vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local function open_terminal_split(split_cmd)
  local cwd = vim.fn.getcwd()
  vim.cmd(split_cmd)
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function close_split()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd("close")
  else
    vim.notify("Only one window remains", vim.log.levels.WARN)
  end
end

local function swap_split(dir)
  local current = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  local neighbor = vim.api.nvim_get_current_win()
  if neighbor == current then return end

  local current_buf = vim.api.nvim_win_get_buf(current)
  local neighbor_buf = vim.api.nvim_win_get_buf(neighbor)
  if current_buf == neighbor_buf then return end

  local current_view = vim.api.nvim_win_call(current, vim.fn.winsaveview)
  local neighbor_view = vim.api.nvim_win_call(neighbor, vim.fn.winsaveview)
  vim.api.nvim_win_set_buf(current, neighbor_buf)
  vim.api.nvim_win_set_buf(neighbor, current_buf)
  vim.api.nvim_win_call(current, function() pcall(vim.fn.winrestview, neighbor_view) end)
  vim.api.nvim_win_call(neighbor, function() pcall(vim.fn.winrestview, current_view) end)
  vim.api.nvim_set_current_win(neighbor)
end

local function shell_is_foreground()
  local job = vim.b.terminal_job_id
  local pid = job and vim.fn.jobpid(job) or nil
  if type(pid) ~= "number" or pid <= 0 then return true end

  local fd = io.open("/proc/" .. pid .. "/stat")
  if not fd then return true end
  local stat = fd:read("*a")
  fd:close()

  local rest = stat and stat:match("%)%s*(.*)$")
  if not rest then return true end
  local fields = vim.split(rest, "%s+", { trimempty = true })
  local pgrp, tpgid = tonumber(fields[3]), tonumber(fields[6])
  return pgrp ~= nil and tpgid ~= nil and pgrp == tpgid
end

vim.keymap.set("t", "<Esc>", function()
  if shell_is_foreground() then
    vim.cmd("stopinsert")
  else
    vim.api.nvim_chan_send(vim.b.terminal_job_id, "\27")
  end
end, { desc = "Leave terminal mode at shell prompt, otherwise forward Esc" })

for _, mode in ipairs({ "n", "t", "i" }) do
  vim.keymap.set(mode, "<A-S-=>", function() open_terminal_split("vsplit") end, { desc = "Split right with terminal" })
  vim.keymap.set(mode, "<A-+>", function() open_terminal_split("vsplit") end, { desc = "Split right with terminal" })
  vim.keymap.set(mode, "<A-->", function() open_terminal_split("split") end, { desc = "Split down with terminal" })
  vim.keymap.set(mode, "<A-S-->", function() open_terminal_split("split") end, { desc = "Split down with terminal" })

  vim.keymap.set(mode, "<A-Left>", "<Cmd>wincmd h<CR>", { desc = "Focus left split" })
  vim.keymap.set(mode, "<A-Right>", "<Cmd>wincmd l<CR>", { desc = "Focus right split" })
  vim.keymap.set(mode, "<A-Up>", "<Cmd>wincmd k<CR>", { desc = "Focus up split" })
  vim.keymap.set(mode, "<A-Down>", "<Cmd>wincmd j<CR>", { desc = "Focus down split" })
  vim.keymap.set(mode, "<A-q>", close_split, { desc = "Close active split" })
  vim.keymap.set(mode, "<A-w>", close_split, { desc = "Close active split" })
end

for _, mode in ipairs({ "n", "t", "i" }) do
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    vim.keymap.set(mode, "<A-" .. key .. ">", function() swap_split(key) end, { desc = "Swap split with neighbor" })
  end
end

-- Neovim starts as an editor by default. Use :terminal or the split shortcuts
-- explicitly when you want a shell.
