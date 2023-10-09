local position = require("qf_helper.position")
local util = require("qf_helper.util")
local M = {}

---@param steps integer
---@param opts nil|table
---    qftype nil|"c"|"l" Use quickfix, loclist, or auto-detect
---    wrap nil|boolean Wrap around list if we hit the end/start
---    by_file nil|boolean Jump by file, not by entry
---    bang nil|boolean Jump even if buffer is modified and 'hidden' is not set
---
M.jump = function(steps, opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    qftype = nil,
    wrap = true,
    by_file = false,
    bang = false,
  })
  local active_list
  if opts.qftype == nil then
    active_list = util.get_active_list()
  else
    active_list = {
      qftype = opts.qftype,
      list = util.get_list(opts.qftype),
    }
  end
  if vim.tbl_isempty(active_list.list) then
    return
  end

  if opts.by_file then
    vim.cmd({
      cmd = active_list.qftype .. (steps < 0 and "p" or "n") .. "f",
      count = math.abs(steps),
      mods = { emsg_silent = true },
    })
  else
    local pos = position.get_pos(active_list.qftype)
    local cur_entry = active_list.list[pos]

    local filtered_list = util.filter_qf(function(e)
      return e.valid == 1 and e.lnum > 0
    end, active_list.list)
    local effective_pos = util.tbl_index(filtered_list, cur_entry)
    if effective_pos then
      if opts.wrap then
        effective_pos = ((effective_pos - 1 + steps) % vim.tbl_count(filtered_list)) + 1
      end
      pos = filtered_list[effective_pos].qf_pos
    else
      pos = pos + steps
      if opts.wrap then
        pos = ((pos - 1) % vim.tbl_count(active_list.list)) + 1
      end
    end

    vim.cmd({
      cmd = active_list.qftype:rep(2),
      bang = opts.bang,
      count = pos,
      mods = {
        emsg_silent = true,
      },
    })
  end
  vim.cmd("normal! zv")

  -- Print out current position after jumping if quickfix isn't open
  if not util.is_open(active_list.qftype) then
    local newpos = position.get_pos(active_list.qftype)
    local text = active_list.list[newpos].text
    text = string.gsub(text, "^%s*", "")
    local line = string.format("(%d of %d) %s", newpos, #active_list.list, text)
    if string.find(vim.o.shortmess, "a") then
      local newline_idx = string.find(line, "\n")
      if newline_idx then
        line = string.sub(line, 1, newline_idx - 1)
      end
    end
    vim.api.nvim_echo({ { line, nil } }, false, {})
  end
end

return M
