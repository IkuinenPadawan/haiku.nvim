# haiku.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io)

*fleeting thought blossoms*
*written in perfect stillness*
*mind in harmony*

A minimalist note-taking plugin for Neovim that helps you capture fleeting thoughts without disrupting your flow.

## Philosophy

Deep focus is precious in any creative work. When ideas or reminders arise, switching contexts to capture them disrupts flow and taxes mental resources.

`haiku.nvim` provides a frictionless way to record thoughts directly within Neovim. Like haiku poems, `haiku.nvim` embraces simplicity and mindfulness, allowing you to capture ideas and retrieve them from anywhere in your workflow with minimal disruption.

## Features

- **Distraction-free capture**: Toggle a floating window, jot down thoughts, and return to work without breaking flow
- **Visual selection capture**: Save highlighted text directly as a haiku without opening the capture window
- **Contextual breadcrumbs**: Automatically captures where each thought originated, with keymapping to jump back to the source
- **Chronological order**: Recent haikus appear first with daily headers
- **Persistent thoughts**: Notes are saved to a markdown file
- **Instant recall**: Toggle your note collection as a floating side panel from anywhere
- **Stay in Neovim**: Never leave where the heart is

## Workflow

You're deep in code. A thought surfaces, a bug to revisit, an idea to explore, something to remember. Press `<Leader>h`, type your thought, hit `<Esc><Esc>`. You're back exactly where you were, flow unbroken. Or highlight a snippet of code, press `<Leader>h`, and it's captured instantly, no window, no interruption. Later, open the notes panel with `<Leader>H` and press `gr` on any entry to jump straight back to where it was captured.

## Requirements

- Neovim 0.8+

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'IkuinenPadawan/haiku.nvim',
  opts = {
    -- your configuration here
  }
}
```

### Using vim.pack (Neovim 0.11+)

```lua
vim.pack.add('IkuinenPadawan/haiku.nvim')
require('haiku').setup()
```

### Using [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'IkuinenPadawan/haiku.nvim',
  config = function()
    require('haiku').setup()
  end
}
```

## Usage

| Key           | Mode          | Action                          |
|---------------|---------------|---------------------------------|
| `<Leader>h`   | Normal        | Toggle note taking window       |
| `<Leader>h`   | Visual        | Save selection as haiku         |
| `<Leader>H`   | Normal        | Toggle notes panel              |
| `<Enter>`     | Normal        | Save note and close             |
| `<Esc>`       | Normal        | Save note and close             |
| `<C-c>`       | Insert        | Discard note and close          |
| `gr`          | Normal        | Jump to haiku's source location |
| `:Haiku`      | Command       | Toggle note window              |

## Output

Notes are saved to a plain markdown file, readable without Neovim. Haikus captured from the terminal or the notes panel itself will not include a source breadcrumb.

```markdown
# Haikus

## 11-04-2026

refactor auth module before the release
`→ /home/user/project/src/auth.lua:42`

check if this edge case is handled upstream
`→ /home/user/project/src/parser.lua:117`

buy quality coffee beans on the way home

## 10-04-2026

...
```

## Configure

```lua
require('haiku').setup({
  haikus_path = "~/.local/share/nvim/haiku/haikus.md",
  daily_headers = true,    -- Organize haikus under date headers (default: true)
  capture_context = true,  -- Track where haikus were captured (default: true)
  date_format = "%d-%m-%Y", -- Date format for daily headers (default: "%d-%m-%Y")
  notify = true,           -- Show notifications on save/discard (default: true)
  keymaps = {
    toggle_add_haiku = "<Leader>h",
    toggle_haikus = "<Leader>H",
  },
  ui = {
    border = "rounded",  -- Capture window border style (default: "rounded")
    winblend = 0,        -- Capture window transparency (default: 0)
    win_width = 0.3,     -- Capture window width as fraction of screen (default: 0.3)
    win_height = 3,      -- Capture window height in lines (default: 3)
    panel_width = 0.33,  -- Notes panel width as fraction of window (default: 0.33)
    panel_border = "none", -- Notes panel border style (default: "none")
  },
})
```
---

## License

MIT
