local socketdriver = require "skynet.socketdriver"
local netpack = require "skynet.netpack"

local tcplib = {}


--string.pack(">s2", pack)
function tcplib.send_text(fd, data)
    socketdriver.send(fd, netpack.pack(data))
end


return tcplib