local requests = require('cmp_ai.requests')

Tabby = requests:new(nil)

function Tabby:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', o or {}, {
    base_url = 'http://127.0.0.1:8080/v1/completions',
    options = {},
  })

  self.api_key = os.getenv('TABBY_API_KEY')

  return o
end

function Tabby:complete(lines_before, lines_after, cb)
  if not self.api_key then
    vim.schedule(function()
      vim.notify('TABBY_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    return
  end

  local headers = {
    'Authorization: Bearer ' .. self.api_key,
  }

  local data = {
    language = vim.bo.filetype,
    segments = {
      prefix = lines_before,
      suffix = lines_after,
      filepath = vim.api.nvim_buf_get_name(0),
    },
    user = self.params.options.user,
    temperature = self.params.options.temperature,
    seed = self.params.options.seed,
  }

  self:Get(self.params.base_url, headers, data, function(answer)
    local new_data = {}
    if answer.error ~= nil then
      vim.notify('Tabby error: ' .. answer.error)
      return
    end
    if answer.choices ~= nil and answer.choices[1] ~= nil then
      table.insert(new_data, answer.choices[1].text)
    end
    cb(new_data)
  end)
end

function Tabby:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return Tabby
