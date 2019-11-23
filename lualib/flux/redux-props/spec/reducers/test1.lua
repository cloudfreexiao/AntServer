local assign = require 'redux.helpers.assign'

local initState = {
    title = '',
    url = '',
    num = 0,
    flag = false
}

local handlers = {
    ['TEST1_UPDATE_TITLE'] = function(state, action)
        return assign({}, initState, state, {
            title = action.title
        })
    end,
    ['TEST1_UPDATE_URL'] = function(state, action)
        return assign({}, initState, state, {
            url = action.url
        })
    end,
    ['TEST1_UPDATE_NUM'] = function(state, action)
        return assign({}, initState, state, {
            num = action.num
        })
    end,
    ['TEST1_UPDATE_FLAG'] = function(state, action)
        return assign({}, initState, state, {
            flag = action.flag
        })
    end,
    ['TEST1_DONE'] = function()
        return assign({}, initState)
    end
}

return function (state, action)
    state = state or initState
    local ret = handlers[action.type]
    if ret then
        return ret(state, action)
    end
    return state
end

