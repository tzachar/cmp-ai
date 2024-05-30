local requests = require('cmp_ai.requests')

Codestral = requests:new(nil)
BASE_URL = 'https://codestral.mistral.ai/v1/fim/completions'

function Codestral:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', params or {}, {
    model = 'codestral-latest',
    temperature = 0.1,
    n = 1,
    max_tokens = 100,
  })

  self.api_key = os.getenv('CODESTRAL_API_KEY')
  if not self.api_key then
    vim.schedule(function()
      vim.notify('CODESTRAL_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    self.api_key = 'NO_KEY'
  end
  self.headers = {
    'Authorization: Bearer ' .. self.api_key,
  }
  return o
end

function Codestral:complete(lines_before, lines_after, cb)
  if not self.api_key then
    vim.schedule(function()
      vim.notify('CODESTRAL_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    return
  end
  local data = {
    prompt = lines_before,
  }
  data = vim.tbl_deep_extend('keep', data, self.params)
  self:Get(BASE_URL, self.headers, data, function(answer)
    local new_data = {}
    if answer.choices then
      for _, response in ipairs(answer.choices) do
        local entry = response.message.content
        table.insert(new_data, entry)
      end
    end
    cb(new_data)
  end)
end

function Codestral:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return Codestral
