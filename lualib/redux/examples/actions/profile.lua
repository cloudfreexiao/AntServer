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

function actions.done()
    return {
        type = "PROFILE_DONE",
    }
end


function actions.thunkCall()
    return function (dispatch, state)
        return dispatch(actions.updateAge(3))
    end
end

return actions
