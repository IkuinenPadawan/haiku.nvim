# haiku.nvim

*fleeting thought blossoms*  
*written in perfect stillness*  
*mind in harmony*

A minimalist note-taking plugin for Neovim that helps you capture fleeting thoughts without disrupting your flow.

## Philosophy

Deep focus is precious in any creative work. When ideas or reminders arise, switching contexts to capture them disrupts flow and taxes mental resources.

`haiku.nvim` provides a frictionless way to record thoughts directly within Neovim. Like haiku poems, `haiku.nvim` embraces simplicity and mindfulness, allowing you to capture ideas and retrieve them from anywhere in your workflow with minimal disruption.

## Features

- **Distraction-free capture**: Toggle a floating window, jot down thoughts, and return to work without breaking flow
- **Contextual breadcrumbs**: Automatically captures where each thought originated
- **Chronological order**: Recent haikus appear first with daily headers
- **Persistent thoughts**: Notes are saved to a markdown file
- **Instant recall**: Toggle your note collection from anywhere
- **Stay in Neovim**: Never leave where the heart is

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'IkuinenPadawan/haiku.nvim',
    config = function()
    require('haiku').setup()
  end
}
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

| Key           | Action                    |
|---------------|---------------------------|
| `<Leader>h`   | Toggle note taking window |
| `<Leader>H`   | Toggle notes panel        |
| `<Enter>`     | Save note and close       |
| `<Esc>`       | Save note and close       |
| `<C-c>`       | Discard note and close    |
| `:Haiku`      | Toggle note window        |

## Configure

```lua
require('haiku').setup({
  haikus_path = "~/.local/share/nvim/haiku/haikus.md",
  daily_headers = true, -- Organize haikus under date headers (default: true)
  capture_context = true, --Track where haikus were captured (default: true)
  keymaps = {
    toggle_add_haiku = "<Leader>h",
    toggle_haikus = "<Leader>H",
  }
})
```
---

## License

MIT
