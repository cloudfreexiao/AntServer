--
-- Author: Crh
-- Date: 2018-06-11 12:25:32
--

local Vector = class("Vector")

function Vector:ctor()
	self.vector = {}
	self.length = 0
end

function Vector:push( data )
	self.vector[ self.length ] = data
	self.length = self.length + 1
end

function Vector:get()
	return self.vector
end

function Vector:resize( num, data )
	self.length = num
end

return Vector