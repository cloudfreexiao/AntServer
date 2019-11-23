local createStore = require 'src.createStore'
local reducers = require 'examples.reducers.index'
local applyMiddleware = require 'src.applyMiddleware'
local middlewares = require 'examples.middlewares.index'

local unpack = unpack or table.unpack

local store = createStore(reducers, applyMiddleware(unpack(middlewares)))

return store
