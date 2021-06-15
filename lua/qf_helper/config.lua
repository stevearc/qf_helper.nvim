local Config = {
  prefer_loclist = true,
  sort_lsp_diagnostics = true,
  quickfix = {
    autoclose = true,
    default_bindings = true,
    default_options = true,
    max_height = 10,
    min_height = 1,
    track_location = true,
  },
  loclist = {
    autoclose = true,
    default_bindings = true,
    default_options = true,
    max_height = 10,
    min_height = 1,
    track_location = true,
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
