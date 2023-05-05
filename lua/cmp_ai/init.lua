local cmp = require('cmp')
local source = require('cmp_ai.source')

local M = {}

M.setup = function()
  M.ai_source = source:new()
  cmp.register_source('cmp_ai', M.ai_source)
end

return M
