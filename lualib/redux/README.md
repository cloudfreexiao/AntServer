# redux-lua
[![Build Status](https://api.travis-ci.org/pyericz/redux-lua.svg?branch=master)](https://travis-ci.org/pyericz/redux-lua)

Originally, [redux](https://redux.js.org/) is a predictable state container for JavaScript apps. From now on, all the redux features are available on your Lua projects. Try it out! :-D

## Install 
redux-lua can be installed using [LuaRocks](http://luarocks.org/modules/pyericz/redux-lua):
```
$ luarocks install redux-lua
```

## Usage
Here is an example of profile updating. To handle redux state changes, it is recommended to use [redux-props](https://github.com/pyericz/redux-props). To get more usages, please checkout [examples](https://github.com/pyericz/redux-lua/tree/master/examples). 

### Define actions
```lua
--[[
    actions/profile.lua
--]]
local actions = {}

function actions.updateName(name)
    return {
        type = "PROFILE_UPDATE_NAME",
        name = name
    }
end

function actions.updateAge(age)
    return {
        type = "PROFILE_UPDATE_AGE",
        age = age
    }
end

function actions.remove()
    return {
        type = "PROFILE_REMOVE"
    }
end

function actions.thunkCall()
    return function (dispatch, state)
        return dispatch(actions.remove())
    end
end

return actions
```

### Define reducer
```lua
--[[
    reducers/profile.lua
--]]
local assign = require 'redux.helpers.assign'
local Null = require 'redux.null'

local initState = {
    name = '',
    age = 0
}

local handlers = {
    ["PROFILE_UPDATE_NAME"] = function (state, action)
        return assign(initState, state, {
            name = action.name
        })
    end,
    
    ["PROFILE_UPDATE_AGE"] = function (state, action)
        return assign(initState, state, {
            age = action.age
        })
    end,
    
    ["PROFILE_REMOVE"] = function (state, action)
        return Null
    end,
}

return function (state, action)
    state = state or Null
    local handler = handlers[action.type]
    if handler then
        return handler(state, action)
    end
    return state
end
```

### Combine reducers
```lua
--[[
    reducers/index.lua
--]]
local combineReducers = require 'redux.combineReducers'
local profile = require 'reducers.profile'

return combineReducers({
    profile = profile
})
```

### Create store
```lua
--[[
    store.lua
--]]
local createStore = require 'redux.createStore'
local reducers = require 'reducers.index'

local store = createStore(reducers)

return store
```

### Create store with middlewares
Here is an example about how to define a middleware.
```lua
--[[
    middlewares/logger.lua
--]]
local Logger = require 'redux.utils.logger'

local function logger(store)
    return function (nextDispatch)
        return function (action)
            Logger.info('WILL DISPATCH:', action)
            local ret = nextDispatch(action)
            Logger.info('STATE AFTER DISPATCH:', store.getState())
            return ret

        end
    end
end

return logger
```

Compose all defined middlewares to `middlewares` array.
```lua
--[[
    middlewares/index.lua
--]]
local logger = require 'middlewares.logger'
local thunk = require 'middlewares.thunk'

local middlewares = {
    thunk,
    logger,
}

return middlewares
```

Finally, pass middlewares to `applyMiddleware`, which is provided as an enhancer to `createStore`, and create our store instance.
```lua
--[[
    store.lua
--]]
local createStore = require 'redux.createStore'
local reducers = require 'reducers.index'
local applyMiddleware = require 'redux.applyMiddleware'
local middlewares = require 'middlewares.index'

local store = createStore(reducers, applyMiddleware(table.unpack(middlewares)))

return store
```
### Dispatch & Subscription
```lua
--[[
    main.lua
--]]
local ProfileActions = require 'actions.profile'
local inspect = require 'redux.helpers.inspect'
local store = require 'store'

local function callback()
    print(inspect(store.getState()))
end

-- subscribe dispatching
local unsubscribe = store.subscribe(callback)

-- dispatch actions
store.dispatch(ProfileActions.updateName('Jack'))
store.dispatch(ProfileActions.updateAge(10))
store.dispatch(ProfileActions.thunkCall())

-- unsubscribe
unsubscribe()
```

### Debug mode
redux-lua is on `Debug` mode by default. Messages with errors and warnings will be output when `Debug` mode is on. Use following code to turn it off.
```lua
local Env = require 'redux.env'

Env.setDebug(false)
```

### Null vs. nil
`nil` is not allowed as a reducer result. If you want any reducer to hold no value, you can return `Null` instead of `nil`.
```lua
local Null = require 'redux.null'
```


## License
[MIT License](https://github.com/pyericz/redux-lua/blob/master/LICENSE)
