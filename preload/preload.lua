require "errorcode"
require "luaext"
require "logger_api"
require "skynet_api"
require "inspect_api"
class = require "class"
singleton = require('singleton')

math.randomseed(os.time())