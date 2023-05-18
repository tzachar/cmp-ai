local requests = require('cmp_ai.requests')

HF = requests:new(nil)
BASE_URL = 'https://api-inference.huggingface.co/models/bigcode/santacoder'
-- BASE_URL = "https://api-inference.huggingface.co/models/bigcode/starcoder"

function HF:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  self.api_key = os.getenv('HF_API_KEY')
  if not self.api_key then
    vim.schedule(function()
      vim.notify('HF_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    self.api_key = 'NO_KEY'
  end
  self.headers = {
    'Authorization: Bearer ' .. self.api_key,
  }
  return o
end

function HF:complete(lines_before, lines_after, cb)
  if not self.api_key then
    vim.schedule(function()
      vim.notify('HF_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    return
  end
  local data = {
    inputs = '<fim-prefix>' .. lines_before .. '<fim-suffix>' .. lines_after .. '<fim-middle>',
    parameters = {
      num_return_sequences = 5,
      return_full_text = false,
      max_new_tokens = 160,
      temperature = 0.2,
      top_p = 0.95,
      stop = { '<|endoftext|>', '<fim-' },
    },
  }
  self:Get(BASE_URL, self.headers, data, function(answer)
    local new_data = {}
    if answer.error ~= nil then
      vim.notify('HuggingFace error: ' .. answer.error)
      return
    end
    for _, response in ipairs(answer) do
      if response.generated_text == nil then
        local result = response.generated_text:gsub('<|endoftext|>', '')
        table.insert(new_data, result)
      end
    end
    cb(new_data)
  end)
end

function HF:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return HF
