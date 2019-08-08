local client = require "service.client_udp"

local M = {}

local auth = client.handler()
function auth.handshake(args)
    DEBUG("arena handshake:", inspect(args))
    return SYSTEM_ERROR.success, {ti = os.time()}
end

return M