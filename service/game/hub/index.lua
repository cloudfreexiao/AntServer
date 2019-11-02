local redisx = require "redisx"
local settings = require "settings"

local max_uin_key = require "dbset".max_uin_key


local M = {}


local function fill_string(str, len, expr)
    if #str < len then
        for idx=1, len - #str do
            str =  expr .. str
        end
    end
    return str
end

--初始化玩家uin
local function init_agent_uin(serverId)
    --uin生成规则  platform_id + serverId(4) + id (10)]
    local first_uin = settings.platform_id .. string.format("%4s%10s", fill_string(tostring(serverId), 4, '0'), fill_string('0', 10, '0'))
    redisx.hsetnx(max_uin_key, serverId, tonumber(first_uin))
end

function M.init(skynet_node_name)
    local conf = settings.nodes[tostring(skynet_node_name)]
    local serverId = conf.server_id
    init_agent_uin(serverId)
end

return M