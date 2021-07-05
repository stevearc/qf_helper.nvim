local config = require("qf_helper.config")
local M = {}

M.get_win_type = function(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(winid)[1]
  if info.quickfix == 0 then
    return ""
  elseif info.loclist == 0 then
    return "c"
  else
    return "l"
  end
end

M.is_open = function(qftype)
  return M.get_win_info(qftype) ~= nil
end

M.get_win_info = function(qftype)
  local ll = qftype == "l" and 1 or 0
  for _, info in ipairs(vim.fn.getwininfo()) do
    if info.quickfix == 1 and info.loclist == ll then
      return info
    end
  end
  return nil
end

M.get_active_list = function()
  local loclist = vim.fn.getloclist(0)
  local qflist = vim.fn.getqflist()

  local lret = { qftype = "l", list = loclist }
  local cret = { qftype = "c", list = qflist }
  local wintype = M.get_win_type()
  if wintype == "c" then
    return cret
  elseif wintype == "l" then
    return lret
  end
  -- If loclist is empty, use quickfix
  if vim.tbl_isempty(loclist) then
    return cret
    -- If quickfix is empty, use loclist
  elseif vim.tbl_isempty(qflist) then
    return lret
  elseif M.is_open("c") then
    if not M.is_open("l") then
      return cret
    end
  elseif M.is_open("l") then
    return lret
  end
  -- They're either both empty or both open
  return config.prefer_loclist and lret or cret
end

M.get_list = function(qftype)
  return qftype == "l" and vim.fn.getloclist(0) or vim.fn.getqflist()
end

-- pos is 1-indexed, like nr in the quickfix
M.get_pos = function(qftype)
  if qftype == "l" then
    return vim.fn.getloclist(0, { idx = 0 }).idx
  else
    return vim.fn.getqflist({ idx = 0 }).idx
  end
end

-- pos is 1-indexed, like nr in the quickfix
M.calculate_pos = function(qftype, list)
  if vim.api.nvim_buf_get_option(0, "buftype") ~= "" then
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
  for i, entry in ipairs(list) do
    -- If we detect that the list isn't sorted, bail.
    if entry.bufnr ~= prev_bufnr then
      prev_lnum = -1
      prev_col = -1
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
  end

  if foundbuf then
    return ret == -1 and vim.tbl_count(list) or ret
  else
    return M.get_pos(qftype)
  end
end

return M
