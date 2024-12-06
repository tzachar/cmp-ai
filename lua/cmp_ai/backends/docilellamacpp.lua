local requests = require('cmp_ai.requests')

DocileLlamaCpp = requests:new(nil)


function DocileLlamaCpp:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', o or {}, {
    base_url = 'http://localhost:5000/forward',
    -- model = 'codellama:7b-code',
    options = {
      temperature = 0.2,
    },
  })
  return o
end

function DocileLlamaCpp:complete(lines_before, lines_after, cb)
  local data = {
    -- model = self.params.model,
    -- prompt = '<PRE> ' .. lines_before .. ' <SUF>' .. lines_after .. ' <MID>', -- for codellama
    prompt = "<s><｜fim▁begin｜>" .. lines_before .. "<｜fim▁hole｜>" .. lines_after .. "<｜fim▁end｜>", -- for deepseek coder
    stream = false,
  }
  data = vim.tbl_extend('keep', data, self.params.options)
  data.prompt = self.params.prompt(lines_before, lines_after)

  self:Get(self.params.base_url, {}, data, function(answer)
    local new_data = {}
    -- vim.print('answer', answer)
    if answer.error ~= nil then
      vim.notify('Docile error: ' .. answer.error)
      return
    end
    if answer.stop then
      local result = answer.content:gsub('<EOT>', '')

      -- detect if 'CodeQwen' string in answer.generation_settings.model -- no longer there in llamap...
      -- if string.find(answer.generation_settings.model, 'CodeQwen') then
      --   -- also get rid first letter - which is always the same space - but only for CodeQwen....
      --   result = result:gsub('^.', '')
      -- end
      -- vim.print('results', result)
      table.insert(new_data, result)
    end
    cb(new_data)
  end)
end

function DocileLlamaCpp:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return DocileLlamaCpp
