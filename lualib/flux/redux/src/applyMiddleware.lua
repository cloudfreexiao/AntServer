local directory = (...):match("(.-)[^%.]+$")
local Array = require(directory .. 'helpers.array')
local assign = require(directory .. 'helpers.assign')
local compose = require(directory .. 'compose')

local unpack = unpack or table.unpack
--[[
    Creates a store enhancer that applies middleware to the dispatch method
    of the Redux store. This is handy for a variety of tasks, such as expressing
    asynchronous actions in a concise manner, or logging every action payload.

    See `redux-thunk` package as an example of the Redux middleware.

    Because middleware is potentially asynchronous, this should be the first
    store enhancer in the composition chain.

    Note that each middleware will be given the `dispatch` and `getState` functions
    as named arguments.

    @param {...Function} middlewares The middleware chain to be applied.
    @returns {Function} A store enhancer applying the middleware.
--]]
local function applyMiddleware(...)
    local middlewares = {...}
    return function (createStore)
        return function (...)
            local store = createStore(...)
            local function dispatch()
                error(table.concat{
                    [[Dispatching while constructing your middleware is not allowed. ]],
                    [[Other middleware would not be applied to this dispatch.]]
                })
            end

            -- Expose only a subset of the store API to the middlewares:
            -- `dispatch(action)` and `getState()`
            local middlewareAPI = {
                getState = store.getState,
                dispatch = function (...)
                    return dispatch(...)
                end
            }
            local chain = Array.map(
                middlewares,
                function(middleware)
                    return middleware(middlewareAPI)
                end
            )
            dispatch = compose(unpack(chain))(store.dispatch)

            return assign({}, store, {
                dispatch = dispatch
            })
        end
    end
end

return applyMiddleware
