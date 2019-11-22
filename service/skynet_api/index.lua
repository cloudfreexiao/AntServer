local lua_pre_path = "skynet_api."

return {
    skynet_helper = require(lua_pre_path .. "skynet_helper"),
    skynet_object = require(lua_pre_path .. "skynet_object"),
    skynet_message_dispatcher = require(lua_pre_path .. "skynet_message_dispatcher"),
    skynet_message_handler = require(lua_pre_path .. "skynet_message_handler"),
    skynet_event_dispatcher = require(lua_pre_path .. "skynet_event_dispatcher"),
    skynet_timermgr = require(lua_pre_path .. "skynet_timermgr"),
}