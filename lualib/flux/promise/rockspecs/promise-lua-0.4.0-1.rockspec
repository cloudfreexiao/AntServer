package = "promise-lua"
version = "0.4.0-1"
source = {
    url = "git+https://github.com/pyericz/promise-lua",
    tag = "v0.4.0"
}
description = {
    summary = "An es6 Promise mechanism in Lua.",
    detailed = "promise-lua is an es6 Promise mechanism in Lua, with the exception that then function is replaced by thenCall since then is a keyword of Lua languange.",
    homepage = "https://github.com/pyericz/promise-lua",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["promise"] = "src/promise.lua",
    }
}
dependencies = {
    "lua >= 5.1",
}
