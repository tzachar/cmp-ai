local cmp = require('cmp')
local api = vim.api
local conf = require('cmp_ai.config')

local Source = {}
function Source:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Source:get_debug_name()
  return 'AI'
end

function Source:_do_complete(ctx, cb)
  if conf:get('notify') then
    conf:get('notify_callback')('Completion started')
  end
  local max_lines = conf:get('max_lines')
  local cursor = ctx.context.cursor
  local cur_line = ctx.context.cursor_line
  -- properly handle utf8
  -- local cur_line_before = string.sub(cur_line, 1, cursor.col - 1)
  local cur_line_before = vim.fn.strpart(cur_line, 0, math.max(cursor.col - 1, 0), true)

  -- properly handle utf8
  -- local cur_line_after = string.sub(cur_line, cursor.col) -- include current character
  local cur_line_after = vim.fn.strpart(cur_line, math.max(cursor.col - 1, 0), vim.fn.strdisplaywidth(cur_line), true) -- include current character

  local lines_before = api.nvim_buf_get_lines(0, math.max(0, cursor.line - max_lines), cursor.line, false)
  table.insert(lines_before, cur_line_before)
  local before = table.concat(lines_before, '\n')

  local lines_after = api.nvim_buf_get_lines(0, cursor.line + 1, cursor.line + max_lines, false)
  table.insert(lines_after, 1, cur_line_after)
  local after = table.concat(lines_after, '\n')

  local service = conf:get('provider')
  service:complete(before, after, function(data)
    self:end_complete(data, ctx, cb)
    -- why 2x ?
    -- if conf:get('notify') then
    --   conf:get('notify_callback')('Completion started')
    -- end
  end)
end

function Source:trigger(ctx, callback)
  if vim.fn.mode() == 'i' then
    self:_do_complete(ctx, callback)
  end
end

-- based on https://github.com/runiq/neovim-throttle-debounce/blob/main/lua/throttle-debounce/init.lua (MIT)
local function debounce_trailing(fn, ms)
	local timer = vim.loop.new_timer()
	local wrapped_fn

    function wrapped_fn(...)
      local argv = {...}
      local argc = select('#', ...)
      -- timer:stop() -- seems not needed?
      timer:start(ms, 0, function()
        pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
      end)
    end
	return wrapped_fn, timer
end

local bounce_complete, ret_tim =  debounce_trailing(
  Source.trigger,
  conf:get('debounce_delay')
)

local self_cp, ctx_cp, call_cp -- variables to store last completion context

local bounce_autogroup = vim.api.nvim_create_augroup("BounceCompletion", { clear = true })
vim.api.nvim_create_autocmd({"TextChangedI","InsertEnter","TextChangedP"},{
  pattern = "*",
  callback = function()
    if self_cp ~= nil then
      bounce_complete(self_cp, ctx_cp, call_cp)
    end
  end,
  group = bounce_autogroup
})

vim.api.nvim_create_autocmd({"InsertLeave"},{
  pattern = "*",
  callback = function()
    ret_tim:stop()
  end,
 group = bounce_autogroup
})


--- complete
function Source:complete(ctx, callback)
  if conf:get('ignored_file_types')[vim.bo.filetype] then
    callback()
    return
  end
  self_cp, ctx_cp, call_cp = self, ctx, callback
  bounce_complete(self_cp, ctx, callback)
end

function Source:end_complete(data, ctx, cb)
  local items = {}
  for _, response in ipairs(data) do
    local prefix = string.sub(ctx.context.cursor_before_line, ctx.offset)
    local result = prefix .. response
    table.insert(items, {
      label = result,
      documentation = {
        kind = cmp.lsp.MarkupKind.Markdown,
        value = '```' .. (vim.filetype.match({ buf = 0 }) or '') .. '\n' .. result .. '\n```',
      },
    })
  end
  cb({
    items = items,
    isIncomplete = conf:get('run_on_every_keystroke'),
  })
end

return Source
