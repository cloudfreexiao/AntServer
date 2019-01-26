--
-- Author: Crh
-- Date: 2018-06-11 11:44:28
--

local Vector2 = class( "Vector2" )

function Vector2:ctor( x, y )
	self.x = x
	self.y = y
end

function Vector2:plus( vector )
	return Vector2.new(self.x + vector.x, self.y + vector.y)
end

function Vector2:plusMe( vector )
	self.x = self.x + vector.x
	self.y = self.y + vector.y
end

function Vector2:minus( vector )
	return Vector2.new(self.x - vector.x, self.y - vector.y)
end

function Vector2:multiply( vector )
	return self.x * vector.x + self.y * vector.y
end

function Vector2:scale( k )
	return Vector2.new(self.x * k, self.y * k)
end

return Vector2