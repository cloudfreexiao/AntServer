package = "lredux"
version = "0.2.0-1"
source = {
    url = "git+https://github.com/pyericz/redux-lua",
    tag = "v0.2.0"
}
description = {
    summary = "Implement redux using Lua language.",
    detailed = "With lredux, all the redux features are available on your Lua projects. Try it out! :-D",
    homepage = "https://github.com/pyericz/redux-lua",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["lredux.createStore"] = "lredux/createStore.lua",
        ["lredux.applyMiddleware"] = "lredux/applyMiddleware.lua",
        ["lredux.combineReducers"] = "lredux/combineReducers.lua",
        ["lredux.compose"] = "lredux/compose.lua",
        ["lredux.null"] = "lredux/null.lua",
        ["lredux.object"] = "lredux/object.lua",
        ["lredux.env"] = "lredux/env.lua",
        ["lredux.helpers.array"] = "lredux/helpers/array.lua",
        ["lredux.helpers.table"] = "lredux/helpers/table.lua",
        ["lredux.utils.actionTypes"] = "lredux/utils/actionTypes.lua",
        ["lredux.utils.isPlainObject"] = "lredux/utils/isPlainObject.lua",
        ["lredux.utils.logger"] = "lredux/utils/logger.lua",
    }
}
dependencies = {
    "lua >= 5.1",
    "inspect >= 3.1.1"
}
