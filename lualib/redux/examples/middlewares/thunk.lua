local function thunk(store)
    return function (nextDispatch)
        return function (action)
            if type(action) == 'function' then
                return action(store.dispatch, store.getState)
            end
            return nextDispatch(action)
        end
    end
end

return thunk
