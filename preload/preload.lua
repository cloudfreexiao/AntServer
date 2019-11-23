-- local STP = require "StackTracePlus"
-- debug.traceback = STP.stacktrace

require "inspect_api"
require "logger_api"

math.randomseed(os.time())

require "errorcode"
require "luaext"

-- Class = require "class"
-- Singleton = require "singleton"
-- Handler = require "handler"
-- Date = require "date"

-- local items = {['1']= 1111,}
-- for _, item in pairs(items) do
--     if item < 1 then
--         do goto continue end
--     end

--     ::continue::
-- end