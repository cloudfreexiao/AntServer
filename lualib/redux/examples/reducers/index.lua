local combineReducers = require 'src.combineReducers'
local profile = require 'examples.reducers.profile'

return combineReducers({
    profile = profile
})
