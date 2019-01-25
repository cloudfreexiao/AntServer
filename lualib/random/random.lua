local skynet = require "skynet"

local random = {}

local random_type = ""--"linux_urandom"
local random_seed = os.time() + skynet.self()

function random.rand(i, j)
    random_seed = random_seed + 1
    if random_type == "linux_urandom" then --随机性中 快
        local data = io.open("/dev/urandom", "r"):read(4)
        math.randomseed(os.time() + data:byte(1) + (data:byte(2) * 256) + (data:byte(3) * 65536) + (data:byte(4) * 4294967296))
        return math.random(i, j)
    else
        math.randomseed(random_seed)
        return math.random(i, j)
    end
end

function random.random_one(lst)
    return lst[random.rand(1, #lst)]
end

function random.random_shuffle(a)
    local c = #a 
    for i=1, c do
        local ndx0 = random.rand(1, c)
        a[ndx0], a[i] = a[i], a[ndx0]
    end
    return a
end

return random
