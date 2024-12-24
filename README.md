# qf_helper.nvim

> [!CAUTION]
> This plugin is deprecated. It is recommended to use [quicker.nvim](https://github.com/stevearc/quicker.nvim) instead.

A collection of improvements for neovim quickfix.

The goal of this plugin is to be **small** and **unobtrusive**. It should make
your normal quickfix workflows smoother, but it does not aim to _change_ your
workflows.

## Why another quickfix plugin?

Why not just use [vim-qf](https://github.com/romainl/vim-qf),
[nvim-bqf](https://github.com/kevinhwang91/nvim-bqf),
[QFEnter](https://github.com/yssl/QFEnter), etc?

Those are all great plugins, but I wanted two features that I could not find:

1. Keep the quickfix location in sync with cursor location in the file
2. Have one keybinding for next/prev that intelligently chooses between quickfix and loclist

https://user-images.githubusercontent.com/506791/124833569-3de9f100-df33-11eb-9e3e-7b956c821cce.mp4

_position tracking in action_

## Installation

It's a standard neovim plugin. Follow your plugin manager's instructions.

Need a plugin manager? Try [pathogen](https://github.com/tpope/vim-pathogen), [paq](https://github.com/savq/paq-nvim), [packer.nvim](https://github.com/wbthomason/packer.nvim), [vim-packager](https://github.com/kristijanhusak/vim-packager), [dein](https://github.com/Shougo/dein.vim), or [vim-plug](https://github.com/junegunn/vim-plug)

## Configuration

All features can be disabled to play nice with any other quickfix plugins or
personal customizations you have. Configuration is done by calling `setup()`:

```lua
-- Set up qf_helper with the default config
require("qf_helper").setup()
```

That one line is all you need, but if you want to change some options you can
pass them in like so:

```lua
require("qf_helper").setup({
  prefer_loclist = true,       -- Used for QNext/QPrev (see Commands below)
  sort_lsp_diagnostics = true, -- Sort LSP diagnostic results
  quickfix = {
    autoclose = true,          -- Autoclose qf if it's the only open window
    default_bindings = true,   -- Set up recommended bindings in qf window
    default_options = true,    -- Set recommended buffer and window options
    max_height = 10,           -- Max qf height when using open() or toggle()
    min_height = 1,            -- Min qf height when using open() or toggle()
    track_location = true,     -- Keep qf updated with your current location
  },
  loclist = {                  -- The same options, but for the loclist
    autoclose = true,
    default_bindings = true,
    default_options = true,
    max_height = 10,
    min_height = 1,
    track_location = true,
  },
})
```

I also recommend setting up some useful keybindings

```lua
-- use <C-N> and <C-P> for next/prev.
vim.keymap.set("n", "<C-N>", "<CMD>QNext<CR>")
vim.keymap.set("n", "<C-P>", "<CMD>QPrev<CR>")
-- toggle the quickfix open/closed without jumping to it
vim.keymap.set("n", "<leader>q", "<CMD>QFToggle!<CR>")
vim.keymap.set("n", "<leader>l", "<CMD>LLToggle!<CR>")
```

## Commands

| Command       | arg     | description                                                                                                                                 |
| ------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `QNext[!]`    | N=1     | Go to next quickfix or loclist entry, choosing based on which is non-empty and which is open. Uses `prefer_loclist` option to tiebreak.     |
| `QPrev[!]`    | N=1     | Go to previous quickfix or loclist entry, choosing based on which is non-empty and which is open. Uses `prefer_loclist` option to tiebreak. |
| `QFNext[!]`   | N=1     | Same as `cnext`, but wraps at the end of the list                                                                                           |
| `QFPrev[!]`   | N=1     | Same as `cprev`, but wraps at the beginning of the list                                                                                     |
| `LLNext[!]`   | N=1     | Same as `lnext`, but wraps at the end of the list                                                                                           |
| `LLPrev[!]`   | N=1     | Same as `lprev`, but wraps at the beginning of the list                                                                                     |
| `QFOpen[!]`   |         | Same as `copen`, but dynamically sizes the window. With `[!]` cursor stays in current window.                                               |
| `LLOpen[!]`   |         | Same as `lopen`, but dynamically sizes the window. With `[!]` cursor stays in current window.                                               |
| `QFToggle[!]` |         | Open or close the quickfix window. With `[!]` cursor stays in current window.                                                               |
| `LLToggle[!]` |         | Open or close the loclist window. With `[!]` cursor stays in current window.                                                                |
| `Cclear`      |         | Clear the entries in the quickfix list                                                                                                      |
| `Lclear`      |         | Clear the entries in the loclist                                                                                                            |
| `Keep`        | <range> | (In qf buffer) Keep the item or range of items, remove the rest                                                                             |
| `Reject`      | <range> | (In qf buffer) Remove the item or range of items                                                                                            |

## Bindings

When `default_bindings = true`, the following keybindings are set in the
quickfix/loclist buffer:

| Key     | Command                                                                    |
| ------- | -------------------------------------------------------------------------- |
| `<C-t>` | open in a new tab                                                          |
| `<C-s>` | open in a horizontal split                                                 |
| `<C-v>` | open in a vertical split                                                   |
| `<C-p>` | open the entry but keep the cursor in the quickfix window                  |
| `<C-k>` | scroll up and open entry while keeping the cursor in the quickfix window   |
| `<C-j>` | scroll down and open entry while keeping the cursor in the quickfix window |
| `{`     | scroll up to the previous file                                             |
| `}`     | scroll down to the next file                                               |

## FAQ

**Q: Why isn't the location tracking working?**

Tracking your location requires that the quickfix or loclist items are
**sorted** by both row and col. Chances are you have some items that are out of
order.
