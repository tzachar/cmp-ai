local M = {}

local conf = {
  max_lines = 50,
  run_on_every_keystroke = true,
  provider = 'HF',
  provider_options = {},
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },

  log_errors = true,
}

function M:setup(params)
  for k, v in pairs(params or {}) do
    conf[k] = v
  end
  local status, provider = pcall(require, 'cmp_ai.backends.' .. conf.provider:lower())
  if status then
    local name = conf.provider
    conf.provider = provider:new(conf.provider_options)
    conf.provider.name = name
  else
    vim.notify('Bad provider in config: ' .. conf.provider, vim.log.levels.ERROR)
  end
end

function M:get(what)
  return conf[what]
end

return M
