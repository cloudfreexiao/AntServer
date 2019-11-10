require "inspect_api"
require "logger_api"

math.randomseed(os.time())

require "errorcode"
require "luaext"

class = require "class"
singleton = require "singleton"
handler = require "handler"


-- https://blog.codingnow.com/2006/10/aoi.html
-- https://blog.codingnow.com/2012/03/dev_note_13.html

-- https://www.cnblogs.com/Lifehacker/p/skynet_systemtap_for_service.html

-- local items = {['1']= 1111,}
-- for _, item in pairs(items) do
--     if item < 1 then
--         do goto continue end
--     end

--     ::continue::
-- end