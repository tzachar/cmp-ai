local requests = require('cmp_ai.requests')

LlamaCpp = requests:new(nil)

function LlamaCpp:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', o, {
    base_url = 'http://127.0.0.1:8080',
    temperature = 0.2,
    max_tokens = 100,
  })

  self.api_key = os.getenv('LLAMA_CPP_API_KEY')

  return o
end

function LlamaCpp:complete(lines_before, lines_after, cb)
  local headers = {}
  if self.api_key then
    table.insert(headers, 'Authorization: Bearer ' .. self.api_key)
  end

  local data = {
    input_prefix = lines_before,
    input_suffix = lines_after,
    temperature = self.params.temperature,
    max_tokens = self.params.max_tokens,
    model = self.params.model,
  }

  local url = self.params.base_url .. '/infill'
  self:Get(url, headers, data, function(answer)
    local new_data = {}
    if answer.error ~= nil then
      vim.notify('Llama.cpp error: ' .. tostring(answer.error))
      return
    end
    if answer.content then
      table.insert(new_data, answer.content)
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
