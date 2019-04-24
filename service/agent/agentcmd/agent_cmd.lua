
local Rx = require "rx.rx"


local AgentCMD = class("AgentCMD")

function AgentCMD:ctor()
end


function AgentCMD:hello(...)
    local param = {...}
    local a, b, c = table.unpack(param)

    Rx.Observable.fromRange(a, b)
    :filter(function(x) return x % 2 == 0 end)
    :concat(Rx.Observable.of('who do we appreciate'))
    :map(function(value) return value .. '!' end)
    :subscribe(DEBUG)

end

return AgentCMD