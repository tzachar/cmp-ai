local cmp = require('cmp')
local api = vim.api
local conf = require('cmp_ai.config')
local async = require('plenary.async')

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
    local cb = conf:get('notify_callback')
    if type(cb) == "table" then
      if cb["on_start"] == nil then
        return
      else
        async.run(function() cb["on_start"]('Completion started') end)
      end
    else
      async.run(function() cb('Completion started', true) end)
    end
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
    if conf:get('notify') then
      local cb = conf:get('notify_callback')
      if type(cb) == "table" then
        if cb["on_end"] == nil then
          return
        else
          async.run(function() cb["on_end"]('Completion ended') end)
        end
      else
        async.run(function() cb('Completion ended', false) end)
      end
    end
  end)
end

--- complete
function Source:complete(ctx, callback)
  if conf:get('ignored_file_types')[vim.bo.filetype] then
    callback()
    return
  end
  self:_do_complete(ctx, callback)
end

function Source:end_complete(data, ctx, cb)
  local items = {}
  for _, response in ipairs(data) do
    local prefix = string.sub(ctx.context.cursor_before_line, ctx.offset)
    local result = prefix .. response
    table.insert(items, {
      cmp = {
        kind_hl_group = 'CmpItemKind' .. conf:get('provider').name,
        kind_text = conf:get('provider').name,
      },
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
