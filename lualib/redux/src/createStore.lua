local directory = (...):match("(.-)[^%.]+$")
local Logger = require(directory..'utils.logger')
local assign = require(directory..'helpers.assign')
local Array = require(directory..'helpers.array')
local ActionTypes = require(directory..'utils.actionTypes')
local isPlainObject = require(directory..'utils.isPlainObject')

local concat = table.concat

--[[
    Creates a Redux store that holds the state tree.
    The only way to change the data in the store is to call `dispatch()` on it.

    There should only be a single store in your app. To specify how different
    parts of the state tree respond to actions, you may combine several reducers
    into a single reducer function by using `combineReducers`.

    @param {function} reducer A function that returns the next state tree, given
    the current state tree and the action to handle.

    @param {any} [preloadedState] The initial state. You may optionally specify it
    to hydrate the state from the server in universal apps, or to restore a
    previously serialized user session.
    If you use `combineReducers` to produce the root reducer function, this must be
    an object with the same shape as `combineReducers` keys.

    @param {function} [enhancer] The store enhancer. You may optionally specify it
    to enhance the store with third-party capabilities such as middleware,
    time travel, persistence, etc. The only store enhancer that ships with Redux
    is `applyMiddleware()`.

    @returns {store} A Redux store that lets you read the state, dispatch actions
    and subscribe to changes.
--]]
local function createStore(reducer, preloadState, enhancer)
    if (type(preloadState) == 'function' and type(enhancer) == 'function') or
        (type(enhancer) == 'function' and type(arg[4]) == 'function') then
        error(concat{
            [[It looks like you are passing several store enhancers to ]],
            [[createStore(). This is not supported. Instead, compose them ]],
            [[together to a single function.]]
        })
    end

    if (type(preloadState) == 'function' and type(enhancer) == 'nil') then
        enhancer = preloadState
        preloadState = nil
    end

    if enhancer ~= nil then
        assert(type(enhancer) == 'function','Expected the enhancer to be a function.')
        return enhancer(createStore)(reducer, preloadState)
    end

    assert(type(reducer) == 'function', 'Expected the reducer to be a function.')

    local currentReducer = reducer
    local currentState = preloadState
    local currentListeners = {}
    local nextListeners = currentListeners
    local isDispatching = false

    --[[
        This makes a shallow copy of currentListeners so we can use
        nextListeners as a temporary list while dispatching.

        This prevents any bugs around consumers calling
        subscribe/unsubscribe in the middle of a dispatch.
    --]]
    local function ensureCanMutateNextListeners()
        if nextListeners == currentListeners then
            nextListeners = assign({}, currentListeners)
        end
    end


    --[[
        Reads the state tree managed by the store.
        @returns {any} The current state tree of your application.
    --]]
    local function getState()
        if isDispatching then
            error(concat{
                [[You may not call store.getState() while the reducer is executing. ]],
                [[The reducer has already received the state as an argument. ]],
                [[Pass it down from the top reducer instead of reading it from the store.]]
            })
        end
        return currentState
    end


    --[[
        Adds a change listener. It will be called any time an action is dispatched,
        and some part of the state tree may potentially have changed. You may then
        call `getState()` to read the current state tree inside the callback.

        You may call `dispatch()` from a change listener, with the following
        caveats:

        1. The subscriptions are snapshotted just before every `dispatch()` call.
        If you subscribe or unsubscribe while the listeners are being invoked, this
        will not have any effect on the `dispatch()` that is currently in progress.
        However, the next `dispatch()` call, whether nested or not, will use a more
        recent snapshot of the subscription list.

        2. The listener should not expect to see all state changes, as the state
        might have been updated multiple times during a nested `dispatch()` before
        the listener is called. It is, however, guaranteed that all subscribers
        registered before the `dispatch()` started will be called with the latest
        state by the time it exits.

        @param {function} listener A callback to be invoked on every dispatch.
        @returns {function} A function to remove this change listener.
    --]]
    local function subscribe(listener)
        assert(type(listener) == 'function', 'Expected the listener to be a function.')

        if isDispatching then
            error(concat{
                [[You may not call store.subscribe() while the reducer is executing. ]],
                [[If you would like to be notified after the store has been updated, subscribe from a ]],
                [[component and invoke store.getState() in the callback to access the latest state. ]],
                [[See https://redux.js.org/api-reference/store#subscribe(listener) for more details.]]
            })
        end

        local isSubscribed = true
        ensureCanMutateNextListeners()
        table.insert(nextListeners, listener)

        return function()
            if not isSubscribed then
                return
            end
            if isDispatching then
                error(table.concat{
                    [[You may not unsubscribe from a store listener while the reducer is executing. ]],
                    [[See https://redux.js.org/api-reference/store#subscribe(listener) for more details.]]
                })
            end
            isSubscribed = false
            ensureCanMutateNextListeners()
            local index = Array.indexOf(nextListeners, listener)
            if index then
                table.remove(nextListeners, index)
            end
        end
    end

    --[[
        Dispatches an action. It is the only way to trigger a state change.

        The `reducer` function, used to create the store, will be called with the
        current state tree and the given `action`. Its return value will
        be considered the **next** state of the tree, and the change listeners
        will be notified.

        The base implementation only supports table actions. If you want to
        dispatch something else, you need to
        wrap your store creating function into the corresponding middleware. Even the
        middleware will eventually dispatch table actions using this method.

        @param {table} action A table representing “what changed”. It is
        a good idea to keep actions serializable so you can record and replay user
        sessions. An action must have
        a `type` property which may not be `nil`. It is a good idea to use
        string constants for action types.

        @returns {table} For convenience, the same action table you dispatched.

        Note that, if you use a custom middleware, it may wrap `dispatch()` to
        return something else.
    --]]
    local function dispatch(action)
        if not isPlainObject(action) then
            error(concat{
                [[Actions must be plain objects. ]],
                [[Use custom middleware for async actions.]]
            })
        end
        assert(type(action.type) ~= 'nil', "Actions may not have an nil 'type' key. Have you misspelled a constant?")

        if isDispatching then
            error('Reducers may not dispatch actions.')
        end

        isDispatching = true
        local status, err = pcall(currentReducer, currentState, action)
        if status then
            currentState = err
        else
            Logger.error(err)
        end
        isDispatching = false

        currentListeners = nextListeners
        for i=1,#currentListeners do
            local listener = currentListeners[i]
            listener()
        end
        return action
    end

    --[[
        Replaces the reducer currently used by the store to calculate the state.

        You might need this if your app implements code splitting and you want to
        load some of the reducers dynamically. You might also need this if you
        implement a hot reloading mechanism for Redux.

        @param {function} nextReducer The reducer for the store to use instead.
        @returns {nil}
    --]]
    local function replaceReducer(nextReducer)
        assert(type(nextReducer) == 'function', 'Expected the nextReducer to be a function.')

        currentReducer = nextReducer

        -- This action has a similiar effect to ActionTypes.INIT.
        -- Any reducers that existed in both the new and old rootReducer
        -- will receive the previous state. This effectively populates
        -- the new state tree with any relevant data from the old one.
        dispatch( {type = ActionTypes.REPLACE} )
    end

    local function observable()
        local outerSubscribe = subscribe
        return {
            subscribe = function (observer)
                assert(type(observer) == 'table', "Expected the observer to be an table.")
                local function observeState()
                    if (observer.next) then
                        observer.next(getState())
                    end
                end
                observeState()
                return {
                    unsubscribe = outerSubscribe(observeState)
                }
            end
        }
    end

    -- When a store is created, an "INIT" action is dispatched so that every
    -- reducer returns their initial state. This effectively populates
    -- the initial state tree.
    dispatch( {type = ActionTypes.INIT} )

    return {
        dispatch = dispatch,
        subscribe = subscribe,
        getState = getState,
        replaceReducer = replaceReducer,
        observable = observable
    }
end

return createStore
