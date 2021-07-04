local Config = {
  prefer_loclist = true,       -- For ambiguous navigation commands
  sort_lsp_diagnostics = true, -- Sort LSP diagnostic results
  quickfix = {
    autoclose = true,          -- Autoclose qf if it's the only open window
    default_bindings = true,   -- Set up recommended bindings in qf window
    default_options = true,    -- Set recommended buffer and window options
    max_height = 10,           -- Max qf height when using open() or toggle()
    min_height = 1,            -- Min qf height when using open() or toggle()
    track_location = 'cursor', -- Keep qf updated with your current location
                               -- Set to 'true' to sync the real qf index
  },
  loclist = {                  -- The same options, but for the loclist
    autoclose = true,
    default_bindings = true,
    default_options = true,
    max_height = 10,
    min_height = 1,
    track_location = 'cursor',
  },
}

function Config:update(opts)
  local merged = vim.tbl_deep_extend('keep', opts or {}, self)
  for k,v in pairs(merged) do
    self[k] = v
  end
end

setmetatable(Config, {
  __index = function(t, k)
    if k == 'l' then
      k = 'loclist'
    elseif k == 'c' then
      k = 'quickfix'
    end
    return rawget(t, k)
  end,
})

return Config
