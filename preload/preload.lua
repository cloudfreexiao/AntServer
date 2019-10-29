require "inspect_api"
require "logger_api"

require "errorcode"
require "luaext"
require "skynet_api"

class = require "class"
singleton = require("singleton")

math.randomseed(os.time())