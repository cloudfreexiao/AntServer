package = "redux-lua"
version = "0.1.0-1"
source = {
    url = "git+https://github.com/pyericz/redux-lua",
    tag = "v0.4.0"
}
description = {
    summary = "Implement redux using Lua language.",
    detailed = "With redux-lua, all the redux features are available on your Lua projects. Try it out! :-D",
    homepage = "https://github.com/pyericz/redux-lua",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["redux.createStore"] = "src/createStore.lua",
        ["redux.applyMiddleware"] = "src/applyMiddleware.lua",
        ["redux.combineReducers"] = "src/combineReducers.lua",
        ["redux.compose"] = "src/compose.lua",
        ["redux.null"] = "src/null.lua",
        ["redux.env"] = "src/env.lua",
        ["redux.helpers.array"] = "src/helpers/array.lua",
        ["redux.helpers.assign"] = "src/helpers/assign.lua",
        ["redux.utils.actionTypes"] = "src/utils/actionTypes.lua",
        ["redux.utils.isPlainObject"] = "src/utils/isPlainObject.lua",
        ["redux.utils.logger"] = "src/utils/logger.lua",
        ["redux.utils.inspect"] = "src/utils/inspect.lua",
    }
}
dependencies = {
    "lua >= 5.1"
}
