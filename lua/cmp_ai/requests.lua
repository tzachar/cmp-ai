local job = require('plenary.job')
Service = {}

function Service:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Service:complete(
  lines_before, ---@diagnostic disable-line
  lines_after, ---@diagnostic disable-line
  cb
) ---@diagnostic disable-line
  error('Not Implemented!')
end

function Service:json_decode(data)
  local status, result = pcall(vim.fn.json_decode, data)
  if status then
    return result
  else
    return nil, result
  end
end

local lastjob = nil

function Service:Get(url, headers, data, cb)
  headers = headers or {}
  headers[#headers + 1] = 'Content-Type: application/json'

  local tmpfname = os.tmpname()
  local f = io.open(tmpfname, 'w+')
  if f == nil then
    vim.notify('Cannot open temporary message file: ' .. tmpfname, vim.log.levels.ERROR)
    return
  end
  f:write(vim.fn.json_encode(data))
  f:close()

  local args = { url, '-d', '@' .. tmpfname }
  for _, h in ipairs(headers) do
    args[#args + 1] = '-H'
    args[#args + 1] = h
  end

  if lastjob ~= nil then
    lastjob = job
      :new({
        command = 'kill',
        args = { '-9', lastjob.pid }
    }):start()
  end

  lastjob = job
    :new({
      command = 'curl',
      args = args,
      on_stdout = vim.schedule_wrap(function(error, data, self)
        if error then
          vim.notify('An Error Occurred ...', vim.log.levels.ERROR)
          cb({ { error = 'ERROR: API Error' } })
	end
        local json = Service:json_decode(data)
        if json == nil then
          cb({ { error = 'No Response.' } })
        else
          cb(json)
        end
      end),
      on_exit = vim.schedule_wrap(function(response, exit_code)
        os.remove(tmpfname)
        if exit_code ~= 0 then
          vim.notify('An Error Occurred ...', vim.log.levels.ERROR)
          cb({ { error = 'ERROR: API Error' } })
        end

        local result = table.concat(response:result(), '\n')
        local json = self:json_decode(result)
        if json == nil then
          cb({ { error = 'No Response.' } })
        else
          cb(json)
        end
      end),
    })
  lastjob:start()
end

return Service
