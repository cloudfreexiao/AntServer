local socketdriver = require "skynet.socketdriver"
local netpack   = require "websocketnetpack"

local wslib = {}


function wslib.send_text(fd, data)
    socketdriver.send(fd, netpack.pack(data))
end


return wslib