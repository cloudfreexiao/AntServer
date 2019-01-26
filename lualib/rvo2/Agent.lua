--
-- Author: Crh
-- Date: 2018-06-11 14:27:46
--
local Vector = require "rvo2.Vector"
local Vector2 = require "rvo2.Vector2"
local RVOMath = require "rvo2.RVOMath"
local Line = require "rvo2.Line"

local Agent = class("Agent")

function Agent:ctor( sim )
	self.simulator = sim

	self.agentNeighbors = Vector.new() --  new List<KeyValuePair<float, Agent>>()
	self.maxNeighbors = 0
	self.maxSpeed = 0.0
	self.neighborDist = 0.0
	self.newVelocity = Vector2.new(0,0) -- Vector 2
	self.obstaclNeighbors = Vector.new() -- new List<KeyValuePair<float, Obstacle>>()
	self.orcaLines = Vector.new() -- new List<Line>()
	self.position = Vector2.new(0,0) -- Vector2

	self.prefVelocity = Vector2.new(0,0) -- Vector2

	self.radius = 0.0
	self.timeHorizon = 0.0
	self.timeHorizonObst = 0.0
	self.velocity = Vector2.new(0,0) -- Vector2
	self.id = 0
    self.rnd = Vector2.new(0,0)
end

function Agent:computeNeighbors()
	self.obstaclNeighbors = Vector.new()
    local rangeSq = RVOMath.sqr(self.timeHorizonObst * self.maxSpeed + self.radius)
    self.simulator.kdTree:computeObstacleNeighbors(self, rangeSq)

    self.agentNeighbors = Vector.new()
    if self.maxNeighbors > 0 then
    	rangeSq = RVOMath.sqr(self.neighborDist)
    	self.simulator.kdTree:computeAgentNeighbors(self, rangeSq)
    end
end

function Agent:computeNewVelocity()
	self.orcaLines = Vector.new()

	local invTimeHorizonObst = 1.0 / self.timeHorizonObst

	for i=0,self.obstaclNeighbors.length-1 do
		local obstacle1 = self.obstaclNeighbors:get()[i].value
        local obstacle2 = obstacle1.nextObstacle

        local relativePosition1 = obstacle1.point:minus(self.position)
        local relativePosition2 = obstacle2.point:minus(self.position)
        local alreadyCovered = false

        for j=0,self.orcaLines.length-1 do
        	if RVOMath.det(relativePosition1:scale(invTimeHorizonObst):minus(self.orcaLines:get()[j].point), self.orcaLines:get()[j].direction) - invTimeHorizonObst * self.radius >= -RVOMath.RVO_EPSILON and RVOMath.det(relativePosition2:scale(invTimeHorizonObst):minus(self.orcaLines:get()[j].point), self.orcaLines:get()[j].direction) - invTimeHorizonObst * self.radius >= -RVOMath.RVO_EPSILON then
        		alreadyCovered = true
        		break
        	end
        end

        while true do
        	if alreadyCovered then
	        	break
	        end

	        local distSq1 = RVOMath.absSq(relativePosition1)
            local distSq2 = RVOMath.absSq(relativePosition2)

            local radiusSq = RVOMath.sqr(self.radius)

            local obstacleVector = obstacle2.point:minus(obstacle1.point)
            local s = relativePosition1:scale(-1):multiply(obstacleVector) / RVOMath.absSq(obstacleVector)
            local distSqLine = RVOMath.absSq(relativePosition1:scale(-1):minus(obstacleVector:scale(s)))

            local line = Line.new()

            if s < 0 and distSq1 <= radiusSq then
            	if obstacle1.isConvex then
            		line.point = Vector2.new(0, 0)
                    line.direction = RVOMath.normalize(Vector2.new(-relativePosition1.y, relativePosition1.x))
                    self.orcaLines:push(line)
            	end
            	break
            elseif s > 1 and distSq2 <= radiusSq then
            	if obstacle2.isConvex and RVOMath.det(relativePosition2, obstacle2.unitDir) >= 0 then
            		line.point = Vector2.new(0, 0)
                    line.direction = RVOMath.normalize(Vector2.new(-relativePosition2.y, relativePosition2.x))
                    self.orcaLines:push(line)
            	end
            	break
            elseif s >= 0 and s < 1 and distSqLine <= radiusSq then
            	line.point = Vector2.new(0, 0)
                line.direction = obstacle1.unitDir:scale(-1)
                self.orcaLines:push(line)
                break
            end

            local leftLegDirection, rightLegDirection

            if s < 0 and distSqLine <= radiusSq then
            	if not obstacle1.isConvex then
            		break
            	end

            	obstacle2 = obstacle1

            	local leg1 = math.sqrt(distSq1 - radiusSq)
                leftLegDirection = (Vector2.new(relativePosition1.x * leg1 - relativePosition1.y * self.radius, relativePosition1.x * self.radius + relativePosition1.y * leg1)):scale(1 / distSq1)
                rightLegDirection = (Vector2.new(relativePosition1.x * leg1 + relativePosition1.y * self.radius, -relativePosition1.x * self.radius + relativePosition1.y * leg1)):scale(1 / distSq1)
            elseif s > 1 and distSqLine <= radiusSq then
            	if not obstacle2.isConvex then
            		break
            	end

            	obstacle1 = obstacle2

            	local leg2 = math.sqrt(distSq2 - radiusSq)
                leftLegDirection = (Vector2.new(relativePosition2.x * leg2 - relativePosition2.y * self.radius, relativePosition2.x * self.radius + relativePosition2.y * leg2)):scale(1 / distSq2)
                rightLegDirection = (Vector2.new(relativePosition2.x * leg2 + relativePosition2.y * self.radius, -relativePosition2.x * self.radius + relativePosition2.y * leg2)):scale(1 / distSq2)
            else
            	
            	if obstacle1.isConvex then
            		local leg1 = math.sqrt(distSq1 - radiusSq)
                    leftLegDirection = (Vector2.new(relativePosition1.x * leg1 - relativePosition1.y * self.radius, relativePosition1.x * self.radius + relativePosition1.y * leg1)):scale(1 / distSq1)
            	else
            		leftLegDirection = obstacle1.unitDir:scale(-1)
            	end

            	if obstacle2.isConvex then
            		local leg2 = math.sqrt(distSq2 - radiusSq)
                    rightLegDirection = (Vector2.new(relativePosition2.x * leg2 + relativePosition2.y * self.radius, -relativePosition2.x * self.radius + relativePosition2.y * leg2)):scale(1 / distSq2)
            	else
            		rightLegDirection = obstacle1.unitDir
            	end

            end

            local leftNeighbor = obstacle1.prevObstacle
            local isLeftLegForeign = false
            local isRightLegForeign = false

            if obstacle1.isConvex and RVOMath.det(leftLegDirection, leftNeighbor.unitDir:scale(-1)) >= 0.0 then
            	leftLegDirection = leftNeighbor.unitDir:scale(-1)
                isLeftLegForeign = true
            end

            if obstacle2.isConvex and RVOMath.det(rightLegDirection, obstacle2.unitDir) <= 0.0 then
            	rightLegDirection = obstacle2.unitDir
                isRightLegForeign = true
            end

            local leftCutoff = obstacle1.point:minus(self.position):scale(invTimeHorizonObst)
            local rightCutoff = obstacle2.point:minus(self.position):scale(invTimeHorizonObst)
            local cutoffVec = rightCutoff:minus(leftCutoff)

            local t = RVOMath.judgeReturn(obstacle1 == obstacle2, 0.5, self.velocity:minus(leftCutoff):multiply(cutoffVec) / RVOMath.absSq(cutoffVec))
            local tLeft = self.velocity:minus(leftCutoff):multiply(leftLegDirection)
            local tRight = self.velocity:minus(rightCutoff):multiply(rightLegDirection)

            if (t < 0.0 and tLeft < 0.0) or (obstacle1 == obstacle2 and tLeft < 0.0 and tRight < 0.0) then
            	local unitW = RVOMath.normalize(self.velocity:minus(leftCutoff))

                line.direction = Vector2.new(unitW.y, -unitW.x)
                line.point = leftCutoff:plus(unitW:scale(self.radius * invTimeHorizonObst))
                self.orcaLines:push(line)
                break
            elseif t > 1.0 and tRight < 0.0 then
            	local unitW = RVOMath.normalize(self.velocity:minus(rightCutoff))

                line.direction = Vector2.new(unitW.y, -unitW.x)
                line.point = rightCutoff:plus(unitW:scale(self.radius * invTimeHorizonObst))
                self.orcaLines:push(line)
                break
            end

            local distSqCutoff = RVOMath.judgeReturn((t < 0.0 or t > 1.0 or obstacle1 == obstacle2), RVOMath.Infinity, RVOMath.absSq(self.velocity:minus(cutoffVec:scale(t):plus(leftCutoff))))
            local distSqLeft = RVOMath.judgeReturn((tLeft < 0.0), RVOMath.Infinity, RVOMath.absSq(self.velocity:minus(leftLegDirection:scale(tLeft):plus(leftCutoff))))
            local distSqRight = RVOMath.judgeReturn((tRight < 0.0), RVOMath.Infinity, RVOMath.absSq(self.velocity:minus(rightLegDirection:scale(tRight):plus(rightCutoff))))

            if distSqCutoff <= distSqLeft and distSqCutoff <= distSqRight then
            	line.direction = obstacle1.unitDir:scale(-1)
                local aux = Vector2.new(-line.direction.y, line.direction.x)
                line.point = aux:scale(self.radius * invTimeHorizonObst):plus(leftCutoff) 
                self.orcaLines:push(line)
                break
            elseif distSqLeft <= distSqRight then
            	if isLeftLegForeign then
            		break
            	end
            	line.direction = leftLegDirection
                local aux = Vector2.new(-line.direction.y, line.direction.x)
                line.point = aux:scale(self.radius * invTimeHorizonObst):plus(leftCutoff)
                self.orcaLines:push(line)
                break
            else
            	if isRightLegForeign then
            		break
            	end

            	line.direction = rightLegDirection:scale(-1)
                local aux = Vector2.new(-line.direction.y, line.direction.x)
                line.point = aux:scale(self.radius * invTimeHorizonObst):plus(leftCutoff)
                self.orcaLines:push(line)
                break
            end
            break
        end
        
	end

	local numObstLines = self.orcaLines.length

    local invTimeHorizon = 1.0 / self.timeHorizon

    for i=0,self.agentNeighbors.length-1 do
    	local other = self.agentNeighbors:get()[i].value

    	local relativePosition = other.position:minus(self.position)
        local relativeVelocity = self.velocity:minus(other.velocity)
        local distSq = RVOMath.absSq(relativePosition)
        local combinedRadius = self.radius + other.radius
        local combinedRadiusSq = RVOMath.sqr(combinedRadius)

        local line = Line.new()
        local u

        if distSq > combinedRadiusSq then
        	local w = relativeVelocity:minus(relativePosition:scale(invTimeHorizon))
        	local wLengthSq = RVOMath.absSq(w)
 			local dotProduct1 = w:multiply(relativePosition)

 			if dotProduct1 < 0.0 and RVOMath.sqr(dotProduct1) > combinedRadiusSq * wLengthSq then
 				local wLength = math.sqrt(wLengthSq)
                local unitW = w:scale(1 / wLength)

                line.direction = Vector2.new(unitW.y, -unitW.x)
                u = unitW:scale(combinedRadius * invTimeHorizon - wLength)
            else
            	local leg = math.sqrt(distSq - combinedRadiusSq)

            	if RVOMath.det(relativePosition, w) > 0.0 then
            		local aux = Vector2.new(relativePosition.x * leg - relativePosition.y * combinedRadius, relativePosition.x * combinedRadius + relativePosition.y * leg)
                    line.direction = aux:scale(1 / distSq)
            	else
            		local aux = Vector2.new(relativePosition.x * leg + relativePosition.y * combinedRadius, -relativePosition.x * combinedRadius + relativePosition.y * leg)
                    line.direction = aux:scale(-1 / distSq)
            	end

            	local dotProduct2 = relativeVelocity:multiply(line.direction)

                u = line.direction:scale(dotProduct2):minus(relativeVelocity)
 			end
 		else
 			local invTimeStep = 1.0 / self.simulator.timeStep

            local w = relativeVelocity:minus(relativePosition:scale(invTimeStep))

            local wLength = RVOMath.abs(w)
            local unitW = w:scale(1 / wLength)

            line.direction = Vector2.new(unitW.y, -unitW.x)
            u = unitW:scale(combinedRadius * invTimeStep - wLength)
        end
        line.point = u:scale(0.5):plus(self.velocity)
        self.orcaLines:push(line)
    end

    local lineFail = self:linearProgram2(self.orcaLines, self.maxSpeed, self.prefVelocity, false)
    if lineFail < self.orcaLines.length then
    	self:linearProgram3(self.orcaLines, numObstLines, lineFail, self.maxSpeed)
    end

end

function Agent:insertAgentNeighbor( agent, rangeSq )
	if self ~= agent then
		local distSq = RVOMath.absSq(self.position:minus(agent.position))

		if distSq < rangeSq then
			if self.agentNeighbors.length < self.maxNeighbors then
				self.agentNeighbors:push(RVOMath.KeyValuePair(distSq, agent))
			end
			local i = self.agentNeighbors.length - 1
			while (i ~= 0 and distSq < self.agentNeighbors:get()[i - 1].key) do
				self.agentNeighbors:get()[i] = self.agentNeighbors:get()[i - 1]
				i = i - 1
			end
			self.agentNeighbors:get()[i] = RVOMath.KeyValuePair(distSq, agent)
			if self.agentNeighbors.length == self.maxNeighbors then
				rangeSq = self.agentNeighbors[self.agentNeighbors.length-1].key
			end
		end
	end
end

function Agent:insertObstacleNeighbor( obstacle, rangeSq )
	local nextObstacle = obstacle.nextObstacle
	local distSq = RVOMath.distSqPointLineSegment(obstacle.point, nextObstacle.point, self.position)
	if distSq < rangeSq then
		self.obstaclNeighbors:push(RVOMath.KeyValuePair(distSq, obstacle))

		local i = self.obstaclNeighbors.length - 1
		while (i ~= 0 and distSq < self.obstaclNeighbors:get()[i - 1].key) do
			self.obstaclNeighbors:get()[i] = self.obstaclNeighbors:get()[i - 1]
			i = i - 1
		end

		self.obstaclNeighbors:get()[i] = RVOMath.KeyValuePair(distSq, obstacle)
	end
end

function Agent:update()
    self.velocity = self.newVelocity:plus(self.rnd)
    self.position:plusMe(self.newVelocity:scale(self.simulator.timeStep))
end

function Agent:linearProgram1( lines, lineNo, radius, optVelocity, directionOpt )
	local dotProduct = lines:get()[lineNo].point:multiply(lines:get()[lineNo].direction)
    local discriminant = RVOMath.sqr(dotProduct) + RVOMath.sqr(radius) - RVOMath.absSq(lines:get()[lineNo].point)

    if discriminant < 0.0 then
    	return false
    end

    local sqrtDiscriminant = math.sqrt(discriminant)
    local tLeft = -dotProduct - sqrtDiscriminant
    local tRight = -dotProduct + sqrtDiscriminant

    for i=0,lineNo-1 do
    	local denominator = RVOMath.det(lines:get()[lineNo].direction, lines:get()[i].direction)
        local numerator = RVOMath.det(lines:get()[i].direction, lines:get()[lineNo].point:minus(lines:get()[i].point))

        while true do
        	if math.abs(denominator) <= RVOMath.RVO_EPSILON then
	        	if numerator < 0.0 then
	        		return false
	        	else
	        		break
	        	end
	        end

	        local t = numerator / denominator

	        if denominator >= 0.0 then
	        	tRight = math.min(tRight, t)
	        else
	        	tLeft = math.max(tLeft, t)
	        end

	        if tLeft > tRight then
	        	return false
	        end
	        break
        end
    end

    if directionOpt then
    	if optVelocity:multiply(lines:get()[lineNo].direction) > 0.0 then
    		self.newVelocity = lines:get()[lineNo].direction:scale(tRight):plus(lines:get()[lineNo].point)
    	else
    		self.newVelocity = lines:get()[lineNo].direction:scale(tLeft):plus(lines:get()[lineNo].point)
    	end
    else
    	local t = lines:get()[lineNo].direction:multiply(optVelocity:minus(lines:get()[lineNo].point))

    	if t < tLeft then
    		self.newVelocity = lines:get()[lineNo].direction:scale(tLeft):plus(lines:get()[lineNo].point)
    	elseif t > tRight then
    		self.newVelocity = lines:get()[lineNo].direction:scale(tRight):plus(lines:get()[lineNo].point)
    	else
    		self.newVelocity = lines:get()[lineNo].direction:scale(t):plus(lines:get()[lineNo].point)
    	end
    end

    if type( self.newVelocity.x ) ~= "number" or type( self.newVelocity.y ) ~= "number" then
    	return false
    end

    return true
end

function Agent:linearProgram2( lines, radius, optVelocity, directionOpt )
	if directionOpt then
		self.newVelocity = optVelocity:scale(radius)
	elseif RVOMath.absSq(optVelocity) > RVOMath.sqr(radius) then
		self.newVelocity = RVOMath.normalize(optVelocity):scale(radius)
	else
		self.newVelocity = optVelocity
	end

	for i=0,lines.length-1 do
		if RVOMath.det(lines:get()[i].direction, lines:get()[i].point:minus(self.newVelocity)) > 0.0 then
			local tempResult = self.newVelocity
			if not self:linearProgram1(lines, i, self.radius, optVelocity, directionOpt) then
				self.newVelocity = tempResult
				return i
			end
		end
	end
	return lines.length
end

function Agent:linearProgram3( lines, numObstLines, beginLine, radius )
	local distance = 0.0

	for i=beginLine,lines.length-1 do
		if RVOMath.det(lines:get()[i].direction, lines:get()[i].point:minus(self.newVelocity)) > distance then
			local projLines = Vector.new()
			for ii=0,numObstLines-1 do
				projLines:push(lines:get()[ii])
			end

			for j=numObstLines,i-1 do
				local line = Line.new()

				local determinant = RVOMath.det(lines:get()[i].direction, lines:get()[j].direction)
                while true do
                	if math.abs(determinant) <= RVOMath.RVO_EPSILON then
						if lines:get()[i].direction:multiply(lines:get()[j].direction) > 0.0 then
							break
						else
							line.point =lines:get()[i].point:plus(lines:get()[j].point):scale(0.5)
						end
					else
						local aux = lines:get()[i].direction:scale(RVOMath.det(lines:get()[j].direction, lines:get()[i].point:minus(lines:get()[j].point)) / determinant) 
	                    line.point = lines:get()[i].point:plus(aux)
					end

					line.direction = RVOMath.normalize(lines:get()[j].direction:minus(lines:get()[i].direction))
	                projLines:push(line)
                	break
                end
			end

			local tempResult = self.newVelocity
			if self:linearProgram2(projLines, radius, Vector2.new(-lines:get()[i].direction.y, lines:get()[i].direction.x), true) < projLines.length then
				self.newVelocity = tempResult
			end

			distance = RVOMath.det(lines:get()[i].direction, lines:get()[i].point:minus(self.newVelocity))
		end
	end
end

return Agent