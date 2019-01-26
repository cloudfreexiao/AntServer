RVO2 port to Lua
=======================

RVO2 Library: Reciprocal Collision Avoidance for Real-Time Multi-Agent Simulation.

This is an **alpha release** of a RVO2 port from the [C# version](http://gamma.cs.unc.edu/RVO2/) to Lua, only for
research purposes and still not intended to be used in production environments. Paper with full details as well as C++
code can be found at the [original authors' site](http://gamma.cs.unc.edu/RVO2/).


Basic Usage
-----------
use in the cocos2dx-lua

### Use

~~~~lua
local RVOSimulator = import(".RVO2.RVOSimulator")
local Vector2 = import(".RVO2.Vector2")
local RVOMath = import(".RVO2.RVOMath")
local Vector = import(".RVO2.Vector")

local _sim = RVOSimulator.new()
_sim:setTimeStep(1)
_sim:setAgentDefaults(400, 30, 600, 600, 20, 10.0, Vector2.new(1, 1))

-- add some more Agent. Agent is move point.
local NUM_AGENTS = 20
for i=0,NUM_AGENTS-1 do
    local angle = i * (2*RVOMath.M_PI) / NUM_AGENTS
    local x = math.cos(angle) * 200
    local y = math.sin(angle) * 200
     _sim:addAgent(Vector2.new(x,y))
end

local goals = Vector.new()
for i=0,_sim:getNumAgents()-1 do
    goals:push(_sim:getAgentPosition(i):scale(-1))
end
_sim:addGoals(goals)

local vertices = Vector.new()

local t3 = {}

-- a Triangle Obstacle.
for i=0,3-1 do
    local angle = i * (2*RVOMath.M_PI) / 3
    local x = math.cos(angle) * 50
    local y = math.sin(angle) * 50
    vertices:push(Vector2.new(x,y))
    table.insert( t3, cc.p( x, y ) )
end

-- add a Triangle Obstacle.
_sim:addObstacle( vertices )

-- init all Obstacle.
_sim:processObstacles()

~~~~

in the cocos2dx-lua schedule function loop

~~~~lua

for i=0,self._sim:getNumAgents()-1 do
	print( i, _sim:getAgentPosition(i).x, _sim:getAgentPosition(i).y )
end

_sim:doStep()

~~~~

