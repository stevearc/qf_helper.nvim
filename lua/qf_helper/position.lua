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

local debounce_idx = 0
M.set_pos = function(qftype, pos)
  debounce_idx = debounce_idx + 1
  if M.get_pos(qftype) == pos then
    return
  end
  local idx = debounce_idx
  vim.defer_fn(function()
    if idx == debounce_idx then
      M.set_pos_immediate(qftype, pos)
    end
  end, 10)
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
  local cursor = vim.api.nvim_win_get_cursor(0)
  local foundbuf = false
  local foundline = false
  local prev_lnum = -1
  local prev_col = -1
  local prev_bufnr = -1
  local ret = -1
  local seen_bufs = {}
  for i, entry in ipairs(list) do
    -- If we detect that the list isn't sorted, bail.
    if prev_bufnr == -1 then
      -- pass
    elseif entry.bufnr ~= prev_bufnr then
      if seen_bufs[entry.bufnr] then
        return -1
      end
      seen_bufs[entry.bufnr] = true
    elseif entry.lnum < prev_lnum then
      return -1
    elseif entry.lnum == prev_lnum and entry.col < prev_col then
      return -1
    end

    if ret > 0 then
      -- pass
    elseif bufnr == entry.bufnr then
      if entry.lnum == cursor[1] then
        if entry.col > 1 + cursor[2] then
          ret = foundline and i - 1 or i
        end
        foundline = true
      elseif entry.lnum > cursor[1] then
        ret = math.max(1, foundbuf and i - 1 or i)
      end
      foundbuf = true
    elseif foundbuf then
      ret = i - 1
    end
    prev_lnum = entry.lnum
    prev_col = entry.col
    prev_bufnr = entry.bufnr
  end

  if foundbuf then
    return ret == -1 and vim.tbl_count(list) or ret
  else
    return M.get_pos(qftype)
  end
end

return M
