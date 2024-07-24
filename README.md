# cmp-ai

AI source for [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

This is a general purpose AI source for `cmp`, easily adapted to any restapi
supporting remote code completion.

For now, HuggingFace SantaCoder, OpenAI Chat, Codestral and Google Bard are implemeted.

## Install

### Dependencies

- You will need `plenary.nvim` to use this plugin.
- For using Codestral, OpenAI or HuggingFace, you will also need `curl`.
- For using Google Bard, you will need [dsdanielpark/Bard-API](https://github.com/dsdanielpark/Bard-API).

### Using a plugin manager

Using [Lazy](https://github.com/folke/lazy.nvim/):

```lua
return require("lazy").setup({
    {'tzachar/cmp-ai', dependencies = 'nvim-lua/plenary.nvim'},
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

## Setup

Please note the use of `:` instead of a `.`

To use HuggingFace:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 1000,
  provider = 'HF',
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
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
  provider_options = {
    model = 'gpt-4',
  },
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
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

To use Codestral:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 1000,
  provider = 'Codestral',
  provider_options = {
    model = 'codestral-latest',
  },
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = true,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})
```

You will also need to make sure you have the Codestral api key in you
environment, `CODESTRAL_API_KEY`.

To use Google Bard:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 1000,
  provider = 'Bard',
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = true,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})
```

You will also need to follow the instructions on [dsdanielpark/Bard-API](https://github.com/dsdanielpark/Bard-API)
to get the `__Secure-1PSID` key, and set the environment variable `BARD_API_KEY`
accordingly (note that this plugin expects `BARD_API_KEY` without a leading underscore).

To use [Ollama](https://ollama.ai):

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 100,
  provider = 'Ollama',
  provider_options = {
    model = 'codellama:7b-code',
  },
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = true,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})
```

To use Tabby:

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 1000,
  provider = 'Tabby',
  notify = true,
  provider_options = {
    -- These are optional
    -- user = 'yourusername',
    -- temperature = 0.2,
    -- seed = 'randomstring',
  },
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = true,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})
```

You will also need to make sure you have the Tabby api key in your environment, `TABBY_API_KEY`.


### `notify`

As some completion sources can be quit slow, setting this to `true` will trigger
a notification when a completion starts and ends using `vim.notify`.

### `notify_callback`

The default notify function uses `vim.notify`, but an override can be configured.
For example:

```lua
notify_callback = function(msg)
  require('notify').notify(msg, vim.log.levels.INFO, {
    title = 'OpenAI',
    render = 'compact',
  })
end
```

### `max_lines`

How many lines of buffer context to use

### `run_on_every_keystroke`

Generate new completion items on every keystroke.

### `ignored_file_types` `(table: <string:bool>)`

Which file types to ignore. For example:

```lua
local ignored_file_types = {
  html = true,
}
```

`cmp-ai` will not offer completions when `vim.bo.filetype` is `html`.

## Dedicated `cmp` keybindings

As completions can take time, and you might not want to trigger expensive apis
on every keystroke, you can configure `cmp-ai` to trigger only with a specific
key press. For example, to bind `cmp-ai` to `<c-x>`, you can do the following:

```lua
cmp.setup({
  ...
  mapping = {
    ...
    ['<C-x>'] = cmp.mapping(
      cmp.mapping.complete({
        config = {
          sources = cmp.config.sources({
            { name = 'cmp_ai' },
          }),
        },
      }),
      { 'i' }
    ),
  },
})
```

Also, make sure you do not pass `cmp-ai` to the default list of `cmp` sources.

## Pretty Printing Menu Items

You can use the following to pretty print the completion menu (requires
[lspkind](https://github.com/onsails/lspkind-nvim) and patched fonts
(<https://www.nerdfonts.com>)):

```lua
require('cmp').setup({
  sources = {
    { name = 'cmp_ai' },
  },
  formatting = {
    format = require('lspkind').cmp_format({
      mode = "symbol_text",
      maxwidth = 50,
      ellipsis_char = '...',
      show_labelDetails = true,
      symbol_map = {
        HF = "",
        OpenAI = "",
        Codestral = "",
        Bard = "",
      }
    });
  },
})
```

## Sorting

You can bump `cmp-ai` completions to the top of your completion menu like so:

```lua
local compare = require('cmp.config.compare')
cmp.setup({
  sorting = {
    priority_weight = 2,
    comparators = {
      require('cmp_ai.compare'),
      compare.offset,
      compare.exact,
      compare.score,
      compare.recently_used,
      compare.kind,
      compare.sort_text,
      compare.length,
      compare.order,
    },
  },
})
```
