package = "lredux"
version = "0.1.0-1"
source = {
    url = "git+https://github.com/pyericz/redux-lua",
    tag = "v0.1.0"
}
description = {
    summary = "A redux implementation using Lua language.",
    homepage = "https://github.com/pyericz/redux-lua",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["lredux.createStore"] = "src/createStore.lua",
        ["lredux.applyMiddleware"] = "src/applyMiddleware.lua",
        ["lredux.combineReducers"] = "src/combineReducers.lua",
        ["lredux.compose"] = "src/compose.lua",
        ["lredux.null"] = "src/null.lua",
        ["lredux.object"] = "src/object.lua",
        ["lredux.env"] = "src/env.lua",
        ["lredux.helpers.array"] = "src/helpers/array.lua",
        ["lredux.helpers.table"] = "src/helpers/table.lua",
        ["lredux.utils.actionTypes"] = "src/utils/actionTypes.lua",
        ["lredux.utils.isPlainObject"] = "src/utils/isPlainObject.lua",
        ["lredux.utils.logger"] = "src/utils/logger.lua",
    }
}
dependencies = {
    "lua >= 5.1",
    "inspect >= 3.1.1"
}
