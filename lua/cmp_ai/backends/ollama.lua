local requests = require('cmp_ai.requests')

Ollama = requests:new(nil)

function Ollama:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', params or {}, {
    base_url = 'http://127.0.0.1:11434/api/generate',
    model = 'codellama:7b-code',
    options = {
      temperature = 0.2,
    },
  })

  return o
end

function Ollama:complete(lines_before, lines_after, cb)
  local data = {
    model = self.params.model,
    prompt = '<PRE> ' .. lines_before .. ' <SUF>' .. lines_after .. ' <MID>',
    stream = false,
    options = self.params.options,
  }

  self:Get(self.params.base_url, {}, data, function(answer)
    local new_data = {}
    if answer.error ~= nil then
      vim.notify('Ollama error: ' .. answer.error)
      return
    end
    if answer.done then
      local result = answer.response:gsub('<EOT>', '')
      table.insert(new_data, result)
    end
    cb(new_data)
  end)
end

function Ollama:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return Ollama
