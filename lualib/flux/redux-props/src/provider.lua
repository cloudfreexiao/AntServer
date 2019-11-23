local Provider = {}

function Provider.setStore(store)
    if type(store) ~= 'table' and store ~= nil then
        error('Unknown store type')
    end
    if type(store) == 'table' then
        assert(type(store.getState) == 'function' and
            type(store.dispatch) == 'function' and
            type(store.subscribe) == 'function', 'Invalid store.')
    end
    Provider.store = store
end

return Provider
