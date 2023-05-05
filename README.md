# cmp-ai
AI source for [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

This is a general purpose AI source for `cmp`, easily adapted to any restapi
supporting remote code completion.

For now, HuggingFace SantaCoder and OpenAI Chat are implemeted.

# Install

## Dependencies

You will need `curl` and `plenary.nvim` to use this plugin.

## Using a plugin manager

Using [Lazy](https://github.com/folke/lazy.nvim/):
   ```lua
return require("lazy").setup({
    {'tzachar/cmp-ai'},
    {'hrsh7th/nvim-cmp', dependencies = {'tzachar/cmp-ai'}},
})
   ```

And later, tell `cmp` to use this plugin:

   ```lua
require'cmp'.setup {
	sources = {
		{ name = 'cmp_ai' },
	},
}
   ```

# Setup

Please note the use of `:` instead of a `.`

To use HuggingFace:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
	max_lines = 1000,
    provider = 'HF',
	run_on_every_keystroke = true,
	ignored_file_types = {
		-- default is not to ignore
		-- uncomment to ignore in lua:
		-- lua = true
	},
})
```
You will also need to make sure you have the Hugging Face api key in you
environment, `HF_API_KEY`.

To use OpenAI:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
	max_lines = 1000,
    provider = 'OpenAI',
    model = 'gpt-4',
	run_on_every_keystroke = true,
	ignored_file_types = {
		-- default is not to ignore
		-- uncomment to ignore in lua:
		-- lua = true
	},
})
```
You will also need to make sure you have the OpenAI api key in you
environment, `OPENAI_API_KEY`.

Available models for OpenAI are `gpt-4` and `gpt-3.5-turbo`.

## `max_lines`

How many lines of buffer context to use

## `run_on_every_keystroke`

Generate new completion items on every keystroke.

## `ignored_file_types` `(table: <string:bool>)`
Which file types to ignore. For example:
```lua
ignored_file_types = {
	html = true;
}
```
will make `cmp-ai` not offer completions when `vim.bo.filetype` is `html`.

# Multi-Line suggestions

Most backends support multi line completions. However, you can choose between
the first line only, or the full completion including all lines. To enable this,
each completion is duplicated such that the first line would appear as the first
option, and the entire multi line completion would appear as the second option.
Moreover, the multiline completion will also appear in the documentation window.
