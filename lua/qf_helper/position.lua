local config = require("qf_helper.config")
local util = require("qf_helper.util")
local M = {}

---@param qftype nil|"c"|"l"
M.update_qf_position = function(qftype)
  if qftype == nil then
    if config.loclist.track_location then
      M.update_qf_position("l")
    end
    if config.quickfix.track_location then
      M.update_qf_position("c")
    end
  elseif util.is_open(qftype) then
    local new_pos = M.calculate_pos(qftype, util.get_list(qftype))
    M.set_pos(qftype, new_pos)
  end
end

-- pos is 1-indexed, like nr in the quickfix
M.set_pos_immediate = function(qftype, pos)
  local conf = config[qftype]
  if pos < 1 or not conf.track_location then
    return
  end
  local winid = util.get_winid(qftype)
  if winid then
    vim.api.nvim_win_set_cursor(winid, { pos, 0 })
    vim.api.nvim_win_set_option(winid, "cursorline", true)
  end
end

local timer
M.set_pos = function(qftype, pos)
  if timer then
    timer:close()
  end
  timer = vim.loop.new_timer()
  timer:start(10, 0, function()
    timer:close()
    timer = nil
    vim.schedule_wrap(M.set_pos_immediate)(qftype, pos)
  end)
end

-- pos is 1-indexed, like nr in the quickfix
M.get_pos = function(qftype)
  if qftype == "l" then
    return vim.fn.getloclist(0, { idx = 0 }).idx
  else
    return vim.fn.getqflist({ idx = 0 }).idx
  end
end

---pos is 1-indexed, like nr in the quickfix
---@param qftype "c"|"l"
---@param list table[]
---@return integer
M.calculate_pos = function(qftype, list)
  if vim.bo.buftype ~= "" then
    return -1
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local filtered_list = util.filter_qf(function(e)
    return e.valid == 1 and e.bufnr == bufnr and e.lnum > 0
  end, list)
  if vim.tbl_isempty(filtered_list) then
    return -1
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local prev_lnum = -1
  local prev_col = -1
  local ret = filtered_list[1].qf_pos
  for _, entry in ipairs(filtered_list) do
    -- If we detect that the list isn't sorted, bail.
    if prev_lnum == -1 then
      -- pass
    elseif entry.lnum < prev_lnum then
      return -1
    elseif entry.lnum == prev_lnum and entry.col < prev_col then
      return -1
    end

    if cursor[1] > entry.lnum or (cursor[1] == entry.lnum and cursor[2] + 1 >= entry.col) then
      ret = entry.qf_pos
    end
    prev_lnum = entry.lnum
    prev_col = entry.col
  end

  return ret
end

return M
