local job = require('plenary.job')
local requests = require('cmp_ai.requests')

Bard = requests:new(nil)

function Bard:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', params or {}, {
    n = 1,
  })

  self.api_key = os.getenv('BARD_API_KEY')
  if not self.api_key then
    error('BARD_API_KEY environment variable not set')
  end
  return o
end

function Bard:complete(lines_before, lines_after, cb)
  local message = table.concat({
    'You are a coding companion.',
    ' You need to suggest code completions for the language ',
    vim.o.filetype,
    '. Given some code prefix and suffix for context, output code which should follow the prefix code.',
    ' You should only output valid code in ',
    vim.o.filetype,
    '. To clearly define a code block, including white space, we will wrap the code block with tags.',
    ' Make sure to respect the white space and indentation rules of the language.',
    ' Do not output anything in plain language, make sure you only use the relevant programming language verbatim.',
    ' OUTPUT ONLY CODE, DO NOT USE MARKUP! and follow the instructions appearing next.',
    ' For example, consider the following request:',
    ' <begin_code_prefix>def print_hello():<end_code_prefix><begin_code_suffix>\n    return<end_code_suffix><begin_code_middle>',
    ' Your answer should be:',
    [=[     print('Hello')<end_code_middle>]=],
    ' Now for the users request: ',
    '    <begin_code_prefix>',
    lines_before,
    '<end_code_prefix> <begin_code_suffix>',
    lines_after,
    '<end_code_suffix><begin_code_middle>',
  }, '\n')

  local command = table.concat({
    'from bardapi import Bard',
    'import json',
    'import os',
    'os.environ["_BARD_API_KEY"] = "' .. self.api_key .. '"',
    'print(json.dumps(Bard(timeout=10).get_answer("""' .. message .. '""")))'
  }, '\n')
  local tmpfname = os.tmpname()
  local f = io.open(tmpfname, 'w+')
  if f == nil then
    vim.notify('Cannot open temporary message file: ' .. tmpfname, vim.log.levels.ERROR)
    return
  end
  f:write(command)
  f:close()
  job
    :new({
      command = '/home/tzachar/.pyenv/shims/python',
      args = { tmpfname },
      on_exit = vim.schedule_wrap(function(response, exit_code)
        os.remove(tmpfname)
        local result = table.concat(response:result(), '\n')
        if exit_code ~= 0 then
          vim.notify('An Error Occurred: ' .. result, vim.log.levels.ERROR)
          cb({ { error = 'ERROR: API Error' } })
        end
        local json = self:json_decode(result)
        local new_data = {}
        if json ~= nil then
          for _, choice in ipairs(json.choices) do
            if #choice.content > 0 then
              local entry = table.concat(choice.content, '\n'):gsub('<end_code_middle>', '')
              if entry:find('```') then
                -- extract the code inside ```
                entry = entry:match('```[^\n]*\n(.*)```')
              end
              table.insert(new_data, entry)
            end
          end
        cb(new_data)
        end
      end)
    }):start()
end

function Bard:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return Bard
