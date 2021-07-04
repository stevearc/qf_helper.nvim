# qf_helper.nvim
A collection of improvements for the quickfix buffer.

**Goals:**
* Be **small**. This is not a kitchen sink plugin.
* Be **configurable**. It is easy to turn off or override any feature.
* Provide **enhancements** for standard workflows involving quickfix. We don't want to *change* how you use quickfix, we want to make your current experience *better*.
* **No new workflows**. Because we're not changing how you use quickfix. Other plugins can provide that functionality.

## Why another quickfix plugin?

Why not just use [vim-qf](https://github.com/romainl/vim-qf),
[nvim-bqf](https://github.com/kevinhwang91/nvim-bqf),
[QFEnter](https://github.com/yssl/QFEnter), etc?

I wanted two things that I could not find in any existing plugins:
1. Update my position in the quickfix when I navigate
2. Have one keybinding for next/prev that intelligently chooses between quickfix and loclist

![qf](https://user-images.githubusercontent.com/506791/122135288-0e910a00-cdf5-11eb-9273-2f68a2b23157.gif)
*position tracking in action*

## Installation

It's a standard neovim plugin. Follow your plugin manager's instructions.

Need a plugin manager? Try [pathogen](https://github.com/tpope/vim-pathogen), [packer.nvim](https://github.com/wbthomason/packer.nvim), [vim-packager](https://github.com/kristijanhusak/vim-packager), [dein](https://github.com/Shougo/dein.vim), or [Vundle](https://github.com/VundleVim/Vundle.vim)

## Configuration

All features can be disabled to play nice with any other quickfix plugins or
personal customizations you have. Configuration is done by calling `setup()`:

```lua
-- Set up qf_helper with the default config
require'qf_helper'.setup()

-- Or you can customize the config
require'qf_helper'.setup({
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
})
```

I also recommend setting up some useful keybindings
```vim
" use <C-N> and <C-P> for next/prev. Will intelligently infer if you want the
" loclist or quickfix based on which has items and/or is open. If they both have
" items and are both open/closed, will use the 'prefer_loclist' setup() option
nnoremap <silent> <C-N> <cmd>lua require'qf_helper'.navigate(1)<CR>
nnoremap <silent> <C-P> <cmd>lua require'qf_helper'.navigate(-1)<CR>
" toggle the quickfix open/closed without jumping to it
nnoremap <silent> <leader>q <cmd>lua require'qf_helper'.toggle('c')<CR>
nnoremap <silent> <leader>l <cmd>lua require'qf_helper'.toggle('l')<CR>
```

## Bindings
When `default_bindings = true`, the following keybindings are set in the
quickfix/loclist buffer:

Key     | Command
---     | -------
`<C-t>` | open in a new tab
`<C-s>` | open in a horizontal split
`<C-v>` | open in a vertical split
`<C-p>` | open the entry but keep the cursor in the quickfix window
`<C-k>` | scroll up and open entry while keeping the cursor in the quickfix window
`<C-j>` | scroll down and open entry while keeping the cursor in the quickfix window
`{`     | scroll up to the previous file
`}`     | scroll down to the next file

## FAQ

**Q: Why isn't the location tracking working?**

Tracking your location requires that the quickfix or loclist items are
**sorted** by both row and col. Chances are you have some items that are out of
order.
