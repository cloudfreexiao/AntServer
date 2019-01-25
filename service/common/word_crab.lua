
local skynet = require 'skynet'
require "skynet.manager"

local word_crab_mod = require "word_crab.word_crab_mod"

local word_crab_file = ...

local CMD = {}

function CMD.is_valid(input)
    return word_crab_mod.is_valid(input)
end 


skynet.start(function()
    word_crab_mod.init(word_crab_file)

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if not f then
            assert(f, string.format("unknow command : %s", cmd))
        end
        if session ~= 0 then
            skynet.retpack(f(...))
        else
            f(...)
        end
    end)

    skynet.register("." .. SERVICE_NAME)
end)