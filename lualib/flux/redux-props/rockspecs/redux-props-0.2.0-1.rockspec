package = "redux-props"
version = "0.2.0-1"
source = {
    url = "git+https://github.com/pyericz/redux-props",
}
description = {
    summary = "Handle redux state changes.",
    detailed = "Map redux state and dispatch to props, and handle props changes when redux state is changed.",
    homepage = "https://github.com/pyericz/redux-props",
    license = "MIT <http://opensource.org/licenses/MIT>"
}
build = {
    type = "builtin",
    modules = {
        ["redux-props.connect"] = "src/connect.lua",
        ["redux-props.provider"] = "src/provider.lua",
        ["redux-props.component"] = "src/component.lua",
    }
}
dependencies = {
    "lua >= 5.1",
}
