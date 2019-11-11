require "inspect_api"
require "logger_api"

math.randomseed(os.time())

require "errorcode"
require "luaext"

class = require "class"
singleton = require "singleton"
handler = require "handler"


-- local items = {['1']= 1111,}
-- for _, item in pairs(items) do
--     if item < 1 then
--         do goto continue end
--     end

--     ::continue::
-- end