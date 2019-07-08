local socket = require "skynet.socket"

local wslib = {}

function wslib.send_frame(fd, opcode, data)
    local finbit, mask_bit = 0x80, 0
    -- if fin then finbit = 0x80 else finbit = 0 end
    -- if self.mask_outgoing then mask_bit = 0x80 else mask_bit = 0 end
    local frame = string.pack("B", finbit | opcode)
    local len = #data
    if len < 126 then
        frame = frame .. string.pack("B", len | mask_bit)
    elseif len < 0xFFFF then
        frame = frame .. string.pack(">BH", 126 | mask_bit, len)
    else 
        frame = frame .. string.pack(">BL", 127 | mask_bit, len)
    end
    frame = frame .. data
    socket.write(fd, frame)
end


function wslib.send_text(fd,data)
	wslib.send_frame(fd, 0x1, data)
end