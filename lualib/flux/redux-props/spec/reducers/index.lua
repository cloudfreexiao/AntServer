local combineReducers = require 'redux.combineReducers'
local test1 = require 'spec.reducers.test1'

return combineReducers({
    test1 = test1,
})
