local config = require("qf_helper.config")
local M = {}

---@param winid nil|integer
---@return nil|"c"|"l"
M.get_win_type = function(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(winid)[1]
  if info.quickfix == 0 then
    return nil
  elseif info.loclist == 0 then
    return "c"
  else
    return "l"
  end
end

---@param qftype "c"|"l"
---@return boolean
M.is_open = function(qftype)
  return M.get_winid(qftype) ~= nil
end

---@param qftype "c"|"l"
---@return nil|integer
M.get_winid = function(qftype)
  local winid
  if qftype == "l" then
    winid = vim.fn.getloclist(0, { winid = 0 }).winid
  else
    winid = vim.fn.getqflist({ winid = 0 }).winid
  end
  if winid == 0 then
    return nil
  else
    return winid
  end
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

M.set_list = function(qftype, items)
  if qftype == "l" then
    vim.fn.setloclist(0, items)
  else
    vim.fn.setqflist(items)
  end
end

---@param bufnr integer
---@param preferred_win nil|integer
---@return nil|integer
M.buf_get_win = function(bufnr, preferred_win)
  if
    preferred_win
    and vim.api.nvim_win_is_valid(preferred_win)
    and vim.api.nvim_win_get_buf(preferred_win) == bufnr
  then
    return preferred_win
  end
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      return winid
    end
  end
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      return winid
    end
  end
  return nil
end

return M
