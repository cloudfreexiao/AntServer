local skynet = require "skynet"

--参考
--https://github.com/facebookarchive/scribe
--https://github.com/Applifier/node-scribe
--https://github.com/jakon89/go-scribe-client

require "base.thrift.TFramedTransport"
require "base.thrift.TBinaryProtocol"
require "base.thrift.TJsonProtocol"
require "base.thrift.TCompactProtocol"
require "base.thrift.TSocket"

require 'base.thrift.scribe.scribe'


local M = {
    buriedlst = {},
}

local function connect(host, port)
	local tsocket = TSocket:new{
        host=host,
        port=port,
	}

    local protocol = TBinaryProtocolFactory:getProtocol(tsocket)
    local client = ScribeClient:new {
        protocol = TBinaryProtocol:new {
            trans = TFramedTransport:new { trans = tsocket },
        },
    }

    tsocket:open()
    return client
end

function M.buriedpoint(host, port)
    M.buried_handle = connect(host, port)
end

function M.do_scribe_log(cate, msg)
    local e = LogEntry:new {
        category = cate,
        message = msg,
    }

    table.insert(M.buriedlst, e)
end

local function send_buried()
    skynet.timeout(5 * 100, send_buried)

    if #M.buriedlst >0 then
        local ok, ret = M.buried_handle:Log(M.buriedlst)
        if (not ok) or (ret ~= ResultCode.OK) then
            skynet.error("send scribe logenrty error")
        else
            M.buriedlst = {}
        end
    end
end

skynet.timeout(5 * 100, send_buried)

return M