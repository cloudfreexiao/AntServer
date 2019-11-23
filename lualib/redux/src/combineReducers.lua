local directory = (...):match("(.-)[^%.]+$")
local Logger = require(directory..'utils.logger')
local Env = require(directory..'env')
local inspect = require(directory..'utils.inspect')
local ActionTypes = require(directory..'utils.actionTypes')
local isPlainObject = require(directory..'utils.isPlainObject')
local Null = require(directory..'null')

local concat = table.concat

local function keys(tbl)
    assert(type(tbl) == 'table', 'expected a table value.')
    local ret = {}
    for k, _ in pairs(tbl) do
        table.insert(ret, k)
    end
    return ret
end

local function getNilStateErrorMessage(key, action)
    local actionType = action and action.type or nil
    local actionDesc = actionType and string.format([[action "%s"]], actionType) or 'an action'

    return string.format(concat{
        [[Given %s, reducer "%s" returned nil. ]],
        [[To ignore an action, you must explicitly return the previous state. ]],
        [[If you want this reducer to hold no value, you can return Null instead of nil.]]
    }, actionDesc, key)
end

local function getUnexpectedStateShapeWarningMessage(
    inputState,
    reducers,
    action,
    unexpectedKeyCache
    )

    local reducerKeys = keys(reducers)
    local argumentName = 'previous state received by the reducer'
    if action and action.type == ActionTypes.INIT then
        argumentName = 'preloadedState argument passed to createStore'
    end

    if #reducerKeys == 0 then
        return concat{
            "Store does not have a valid reducer. Make sure the argument passed ",
            "to combineReducers is an object whose values are reducers."
        }
    end

    if not isPlainObject(inputState) then
        return string.format(concat{
            [[The %s has unexpected type of "%s". ]],
            [[Expected argument to be an object with the following keys: "%s".]]
        },
            argumentName,
            inspect(inputState, {depth = 1}),
            table.concat(reducerKeys, '", "')
        )
    end

    local unexpectedKeys = {}
    for key, _ in pairs(inputState) do
        if reducers[key] == nil and unexpectedKeyCache[key] == nil then
            table.insert(unexpectedKeys, key)
        end
    end

    for _, key in ipairs(unexpectedKeys) do
        unexpectedKeyCache[key] = true
    end

    if type(action) == 'table' and action.type == ActionTypes.REPLACE then return end

    if #unexpectedKeys > 0 then
        return string.format(concat{
            [[Unexpected %s "%s" found in %s. ]],
            [[Expected to find one of the known reducer keys instead: ]],
            [["%s". Unexpected keys will be ignored.]]
        },
            #unexpectedKeys > 1 and 'keys' or 'key',
            table.concat(unexpectedKeys, '", "'),
            argumentName,
            table.concat(reducerKeys, '", "')
        )
    end
end

local function assertReducerShape(reducers)
    for key, reducer in pairs(reducers) do
        local initState = reducer(nil, { type = ActionTypes.INIT })

        if initState == nil then
            error(string.format(concat{
                [[Reducer "%s" returned nil during initialization. ]],
                [[If the state passed to the reducer is nil, you must ]],
                [[explicitly return the initial state. The initial state may ]],
                [[not be nil. If you don't want to set a value for this reducer, ]],
                [[you can use Null instead of nil.]]
            }, key))
        end

        local state = reducer(nil, { type = ActionTypes.PROBE_UNKNOWN_ACTION() })
        if state == nil then
            error(string.format(concat{
                [[Reducer "%s" returned nil when probed with a random type. ]],
                [[Don't try to handle %s or other actions in "redux/*" ]],
                [[namespace. They are considered private. Instead, you must return the ]],
                [[current state for any unknown actions, unless it is nil, ]],
                [[in which case you must return the initial state, regardless of the ]],
                [[action type. The initial state may not be nil, but can be Null. ]]
            }, key, ActionTypes.INIT))
        end
    end
end

--[[
    Turns an object whose values are different reducer functions, into a single
    reducer function. It will call every child reducer, and gather their results
    into a single state object, whose keys correspond to the keys of the passed
    reducer functions.

    @param {table} reducers An object whose values correspond to different
    reducer functions that need to be combined into one. One handy way to obtain
    it is to use ES6 `import * as reducers` syntax. The reducers may never return
    undefined for any action. Instead, they should return their initial state
    if the state passed to them was undefined, and the current state for any
    unrecognized action.

    @returns {Function} A reducer function that invokes every reducer inside the
    passed object, and builds a state object with the same shape.
--]]
local function combineReducers(reducers)
    local finalReducers = {}
    for k,v in pairs(reducers) do
        if type(v) ~= 'function' then
            Logger.warn(string.format('Reducer type `%s` is not supported for key `%s`.', type(v), k))
        else
            finalReducers[k] = v
        end
    end

    local finalReducerKeys = keys(finalReducers)

    -- This is used to make sure we don't warn about the same
    -- keys multiple times.
    local unexpectedKeyCache
    if Env.isDebug() then
        unexpectedKeyCache = {}
    end

    local _, shapeAssertionError = pcall(assertReducerShape, finalReducers)

    return function(state, action)
        if state == nil then state = {} end
        if shapeAssertionError then
            Logger.error(shapeAssertionError)
            return
        end

        if Env.isDebug() then
            local warningMessage = getUnexpectedStateShapeWarningMessage(
                state,
                finalReducers,
                action,
                unexpectedKeyCache
            )
            if warningMessage then
                Logger.warn(warningMessage)
            end
        end

        local hasChanged = false
        local nextState = {}
        for i=1, #finalReducerKeys do
            local key = finalReducerKeys[i]
            local reducer = finalReducers[key]
            local previousStateForKey = state[key]
            local nextStateForKey = reducer(previousStateForKey, action)
            if nextStateForKey == nil then
                local errorMessage = getNilStateErrorMessage(key, action)
                error(errorMessage)
            end
            if nextStateForKey == Null then
                nextStateForKey = nil
            end
            nextState[key] = nextStateForKey
            hasChanged = hasChanged or nextStateForKey ~= previousStateForKey
        end
        return hasChanged and nextState or state
    end
end

return combineReducers
