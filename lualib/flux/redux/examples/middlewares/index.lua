local logger = require 'examples.middlewares.logger'
local thunk = require 'examples.middlewares.thunk'

local middlewares = {
    thunk,
    logger,
}

return middlewares
