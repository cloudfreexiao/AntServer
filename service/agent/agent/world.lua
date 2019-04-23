local skynet = require "skynet"

local World = {
    _world = nil,
    tm = skynet.time(),
}


function World.start(world)
    World._world = world

	skynet.fork(
		function ()
			while true do
				World._world:update()
				skynet.sleep(1 * 100)
            end
    end)

    skynet.fork(
		function ()
			while true do
				World._world:storage()
				skynet.sleep(30 * 100)
            end
    end)
end

return World

