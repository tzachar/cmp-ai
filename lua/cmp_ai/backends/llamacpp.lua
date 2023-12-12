local requests = require('cmp_ai.requests')

LlamaCpp = requests:new(nil)

function LlamaCpp:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', o or {}, {
    base_url = 'http://localhost:8080/completion',
    -- model = 'codellama:7b-code',
    options = {
      temperature = 0.2,
    },
  })
  return o
end

function LlamaCpp:complete(lines_before, lines_after, cb)
  local data = {
    -- model = self.params.model,
    -- prompt = '<PRE> ' .. lines_before .. ' <SUF>' .. lines_after .. ' <MID>', -- for codellama
    prompt = "<s><｜fim▁begin｜>" .. lines_before .. "<｜fim▁hole｜>" .. lines_after .. "<｜fim▁end｜>", -- for deepseek coder
    stream = false,
  }
  data = vim.tbl_extend('keep', data, self.params.options)

  self:Get(self.params.base_url, {}, data, function(answer)
    local new_data = {}
    vim.print('answer', answer)
    if answer.error ~= nil then
      vim.notify('Llamacp error: ' .. answer.error)
      return
    end
    if answer.stop then
      local result = answer.content:gsub('<EOT>', '')
      vim.print('results', result)
      table.insert(new_data, result)
    end
    cb(new_data)
  end)
end

function LlamaCpp:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return LlamaCpp
