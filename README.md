# cmp-ai

AI source for [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

This is a general purpose AI source for `cmp`, easily adapted to any restapi
supporting remote code completion.

For now, HuggingFace SantaCoder, OpenAI Chat and Google Bard are implemeted.

## Install

### Dependencies

- You will need `plenary.nvim` to use this plugin.
- For using OpenAI or HuggingFace, you will also need `curl`.
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
    prompt = function(lines_before, lines_after)
      -- prompt depends on the model you use. Here is an example for deepseek coder
      return prompt = '<PRE> ' .. lines_before .. ' <SUF>' .. lines_after .. ' <MID>', -- for codellama
    end,
  },
  debounce_delay = 600, -- ms llama may be GPU hungry, wait x ms after last key input, before sending request to it
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
Models for Ollama are available at [here](https://ollama.ai/library). For code completions use model that supports it - e.g. [DeepSeek Base 6.7b](https://ollama.ai/library/deepseek-coder)

To use with [LlamaCpp](https://github.com/ggerganov/llama.cpp):

```lua
local cmp_ai = require('cmp_ai.config')

cmp_ai:setup {
  max_lines = 30,
  provider = "LlamaCpp",
  provider_options = {
    options = {
      n_predict = 20,  -- number of generated predictions
      min_p = 0.05, -- default 0.05,  Cut off predictions with probability below  Max_prob * min_p
      -- repeat_last_n = 64, -- default 64
      -- repeat_penalty = 1.100, -- default 1.1
      -- see llama server link above - to see other options
    },
    prompt = function(lines_before, lines_after)
      -- prompt depends on the model you use. Here is an example for deepseek coder
      return "<s><｜fim▁begin｜>" .. lines_before .. "<｜fim▁hole｜>" .. lines_after .. "<｜fim▁end｜>" -- for deepseek coder
    end,
  },
  debounce_delay = 600, -- ms llama may be GPU hungry, wait x ms after last key input, before sending request to it
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = false,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
}
```


[LlamaCpp Server](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md) has to be started manually with:

```bash
./server -m ./models/deepseek-coder-6.7b-base.Q4_K_M.gguf -ngl 50 -c 2048 --log-disable
```

LlamaCpp requires model in GGUP format. Here is the current model I use for coding:
 - [DeepSeek Base 6.7b](https://huggingface.co/TheBloke/deepseek-coder-6.7B-base-GGUF/blob/main/deepseek-coder-6.7b-base.Q4_K_M.gguf)
 It is good to have at least 12GB of VRAM to run it (works best with NVIDIA - due to CUDA acceleration). If you want you can grab smaller models too (faster to run, but lower quality of completions)


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
local lspkind = require('lspkind')

local source_mapping = {
  buffer = '[Buffer]',
  nvim_lsp = '[LSP]',
  nvim_lua = '[Lua]',
  cmp_ai = '[AI]',
  path = '[Path]',
}

require('cmp').setup({
  sources = {
    { name = 'cmp_ai' },
  },
  formatting = {
    format = function(entry, vim_item)
      -- if you have lspkind installed, you can use it like
      -- in the following line:
      vim_item.kind = lspkind.symbolic(vim_item.kind, { mode = 'symbol' })
      vim_item.menu = source_mapping[entry.source.name]
      if entry.source.name == 'cmp_ai' then
        local detail = (entry.completion_item.labelDetails or {}).detail
        vim_item.kind = ''
        if detail and detail:find('.*%%.*') then
          vim_item.kind = vim_item.kind .. ' ' .. detail
        end

        if (entry.completion_item.data or {}).multiline then
          vim_item.kind = vim_item.kind .. ' ' .. '[ML]'
        end
      end
      local maxwidth = 80
      vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)
      return vim_item
    end,
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
