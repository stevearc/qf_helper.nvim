local config = require("qf_helper.config")
local nav = require("qf_helper.nav")
local position = require("qf_helper.position")
local util = require("qf_helper.util")

local M = {}

---@param bufnr integer
M.set_qf_defaults = function(bufnr)
  local winid = util.buf_get_win(bufnr, 0) or 0
  local qftype = util.get_win_type()
  local conf = config[qftype]

  vim.cmd(
    [[command! -buffer -range Keep call luaeval("require('qf_helper').cmd_filter(unpack(_A))", [v:true, <line1>, <line2>])]]
  )
  vim.cmd(
    [[command! -buffer -range Reject call luaeval("require('qf_helper').cmd_filter(unpack(_A))", [v:false, <line1>, <line2>])]]
  )

  if conf.default_options then
    vim.bo[bufnr].buflisted = false
    vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = winid })
    vim.api.nvim_set_option_value("winfixheight", true, { scope = "local", win = winid })
  end

  if conf.default_bindings then
    -- CTRL-t opens selection in new tab
    vim.keymap.set("n", "<C-t>", "<C-W><CR><C-W>T", { desc = "Open entry in new tab", buffer = bufnr })
    -- CTRL-s opens selection in horizontal split
    vim.keymap.set("n", "<C-s>", function()
      require("qf_helper").open_split("split")
    end, { desc = "Open entry in horizontal split", buffer = bufnr })
    -- CTRL-v opens selection in vertical split
    vim.keymap.set("n", "<C-v>", function()
      require("qf_helper").open_split("vsplit")
    end, { desc = "Open entry in vertical split", buffer = bufnr })
    -- p jumps without leaving quickfix
    vim.keymap.set("n", "<C-p>", "<CR><C-W>p", { desc = "Preview entry", buffer = bufnr })
    -- <C-k> scrolls up and jumps without leaving quickfix
    vim.keymap.set("n", "<C-k>", "k<CR><C-W>p", { desc = "Move cursor up and preview entry", buffer = bufnr })
    -- <C-j> scrolls down and jumps without leaving quickfix
    vim.keymap.set("n", "<C-j>", "j<CR><C-W>p", { desc = "Move cursor down and preview entry", buffer = bufnr })
    -- { and } navigates up and down by file
    vim.keymap.set("n", "{", function()
      local qfwin = vim.api.nvim_get_current_win()
      nav.jump(-vim.v.count1, { by_file = true })
      vim.api.nvim_set_current_win(qfwin)
    end, { desc = "Jump to previous file in list", buffer = bufnr })
    vim.keymap.set("n", "}", function()
      local qfwin = vim.api.nvim_get_current_win()
      nav.jump(vim.v.count1, { by_file = true })
      vim.api.nvim_set_current_win(qfwin)
    end, { desc = "Jump to next file in list", buffer = bufnr })
  end
end

M.maybe_autoclose = function()
  local qftype = util.get_win_type()
  if not qftype then
    return
  end
  local conf = config[qftype]
  if conf and vim.tbl_count(vim.api.nvim_list_wins()) == 1 and conf.autoclose then
    vim.cmd("quit")
  end
end

---@param qftype "c"|"l"
---@param opts nil|table
---    enter nil|boolean Enter the qf window after opening
---    height nil|integer Set the height of the qf window
M.open = function(qftype, opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    enter = false,
    height = nil,
  })
  local list = util.get_list(qftype)
  local list_winid = util.get_winid(qftype)
  if list_winid then
    if opts.enter and util.get_win_type() ~= qftype then
      position.set_pos_immediate(qftype, position.calculate_pos(qftype, list))
      vim.api.nvim_set_current_win(list_winid)
    end
    return
  end
  local conf = config[qftype]
  if not opts.height then
    opts.height = math.min(conf.max_height, math.max(conf.min_height, vim.tbl_count(list)))
  end
  position.set_pos_immediate(qftype, position.calculate_pos(qftype, list))
  local winid = vim.api.nvim_get_current_win()
  local cmd = string.format("%sopen %d", qftype, opts.height)
  if qftype == "c" then
    cmd = "botright " .. cmd
  end
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.api.nvim_err_writeln(err)
    return
  end
  -- the height could be wrong b/c of autocmds
  vim.api.nvim_win_set_height(0, opts.height)
  if not opts.enter then
    vim.api.nvim_set_current_win(winid)
  end
end

---@param qftype "c"|"l"
---@param opts nil|table
---    enter nil|boolean Enter the qf window after opening
---    height nil|integer Set the height of the qf window
M.toggle = function(qftype, opts)
  if util.is_open(qftype) then
    M.close(qftype)
  else
    M.open(qftype, opts)
  end
end

---@param qftype "c"|"l"
M.close = function(qftype)
  vim.cmd(qftype .. "close")
end

return M
