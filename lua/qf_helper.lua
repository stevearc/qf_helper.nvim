local M = {}

---@param mod string Name of qf_helper module
---@param fn string Name of function to wrap
local function lazy(mod, fn)
  return function(...)
    return require(string.format("qf_helper.%s", mod))[fn](...)
  end
end

---@param opts nil|table
M.setup = function(opts)
  if vim.fn.has("nvim-0.8") == 0 then
    vim.notify_once("qf_helper has dropped support for Neovim <0.8", vim.log.levels.ERROR)
    return
  end
  local config = require("qf_helper.config")
  config.update(opts)

  vim.api.nvim_create_user_command("QNext", function(args)
    require("qf_helper.nav").jump(args.count, { bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("QPrev", function(args)
    require("qf_helper.nav").jump(-args.count, { bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("QFNext", function(args)
    require("qf_helper.nav").jump(args.count, { qftype = "c", bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("QFPrev", function(args)
    require("qf_helper.nav").jump(-args.count, { qftype = "c", bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("LLNext", function(args)
    require("qf_helper.nav").jump(args.count, { qftype = "l", bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("LLPrev", function(args)
    require("qf_helper.nav").jump(-args.count, { qftype = "l", bang = args.bang, bar = true })
  end, { bang = true, count = 1 })
  vim.api.nvim_create_user_command("QFOpen", function(args)
    M.open("c", { enter = not args.bang, bar = true })
  end, { bang = true })
  vim.api.nvim_create_user_command("LLOpen", function(args)
    M.open("l", { enter = not args.bang, bar = true })
  end, { bang = true })
  vim.api.nvim_create_user_command("QFToggle", function(args)
    M.toggle("c", { enter = not args.bang, bar = true })
  end, { bang = true })
  vim.api.nvim_create_user_command("LLToggle", function(args)
    M.toggle("l", { enter = not args.bang, bar = true })
  end, { bang = true })
  vim.api.nvim_create_user_command(
    "Cclear",
    "call setqflist([])",
    { desc = "Clear entries in the quickfix list", bar = true }
  )
  vim.api.nvim_create_user_command(
    "Lclear",
    "call setloclist(0, [])",
    { desc = "Clear entries in the loclist", bar = true }
  )

  local aug = vim.api.nvim_create_augroup("QFHelper", {})
  if config.sort_lsp_diagnostics then
    -- Sort diagnostics properly so our qf_helper cursor position works
    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "Update the diagnostics handler to sort the values",
      pattern = "*",
      group = aug,
      once = true,
      callback = function(args)
        local function sort_diagnostics(a, b)
          if a.range.start.line == b.range.start.line then
            return a.range.start.character < b.range.start.character
          else
            return a.range.start.line < b.range.start.line
          end
        end

        local diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
        vim.lsp.handlers["textDocument/publishDiagnostics"] = function(a1, a2, params, a4, a5, a6)
          if params and params.diagnostics then
            table.sort(params.diagnostics, sort_diagnostics)
          end
          return diagnostics_handler(a1, a2, params, a4, a5, a6)
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Set default quickfix options",
    pattern = "qf",
    group = aug,
    callback = function(args)
      require("qf_helper.window").set_qf_defaults(args.buf)
    end,
  })

  if config.quickfix.autoclose or config.loclist.autoclose then
    vim.api.nvim_create_autocmd("WinEnter", {
      desc = "Autoclose tab or vim if quickfix is last remaining window",
      pattern = "*",
      group = aug,
      callback = function()
        require("qf_helper.window").maybe_autoclose()
      end,
    })
  end

  if config.quickfix.track_location or config.loclist.track_location then
    vim.api.nvim_create_autocmd("CursorMoved", {
      desc = "Update location in quickfix",
      pattern = "*",
      group = aug,
      callback = function()
        require("qf_helper.position").update_qf_position()
      end,
    })
  end
end

---@param qftype "c"|"l"
---@param opts nil|table
---    enter nil|boolean Enter the qf window after opening
---    height nil|integer Set the height of the qf window
M.open = lazy("window", "open")

---@param qftype "c"|"l"
---@param opts nil|table
---    enter nil|boolean Enter the qf window after opening
---    height nil|integer Set the height of the qf window
M.toggle = lazy("window", "toggle")

---@param qftype "c"|"l"
M.close = lazy("window", "close")

M.open_split = function(cmd)
  local util = require("qf_helper.util")
  local wintype = util.get_win_type()
  if not wintype then
    error("Only use qf_helper.open_split inside the quickfix buffer")
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  vim.cmd("wincmd p")
  vim.cmd(cmd)
  vim.cmd(line .. wintype .. wintype)
end

M.cmd_filter = function(keep, range_start, range_end)
  local util = require("qf_helper.util")
  local qftype = util.get_win_type()
  if not qftype then
    vim.api.nvim_err_writeln("Can only use :Keep and :Reject inside quickfix buffer")
    return
  end
  local list = util.get_list(qftype)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local newlist
  local lnum = cursor[1]
  if keep then
    newlist = { unpack(list, range_start, range_end) }
    lnum = cursor[1] - range_start + 1
  else
    newlist = {}
    for i, item in ipairs(list) do
      if i < range_start or i > range_end then
        table.insert(newlist, item)
      end
    end
    local delta = cursor[1] - range_start
    if delta > 0 then
      lnum = cursor[1] - delta
    end
  end
  util.set_list(qftype, newlist)
  if #newlist == 0 then
    return
  end
  lnum = math.min(math.max(1, lnum), #newlist)
  vim.api.nvim_win_set_cursor(0, { lnum, cursor[2] })
end

return M
