--
-- Author: Crh
-- Date: 2018-06-11 11:39:11
--

local RVOMath = {}

RVOMath.RVO_EPSILON = 0.01
-- 无限大
RVOMath.Infinity = 1e309

RVOMath.M_PI = 3.14159265358979323846

RVOMath.absSq = function(v)
    return v:multiply(v)
end

RVOMath.normalize = function(v)
	return v:scale(1 / RVOMath.abs(v))
end

RVOMath.distSqPointLineSegment = function(a, b, c)
	local aux1 = c:minus(a)
	local aux2 = b:minus(a)
	
	local r = aux1:multiply(aux2) / RVOMath.absSq(aux2)
	
	if r < 0 then
		return RVOMath.absSq(aux1)
	elseif r > 1 then
		return RVOMath.absSq(aux2)
	else
		return RVOMath.absSq( c:minus(a:plus(aux2:scale(r))) )
	end

end

RVOMath.sqr = function(p)
	return p * p
end

RVOMath.det = function(v1, v2)
	return v1.x * v2.y - v1.y* v2.x
end

RVOMath.abs = function(v)
	return math.sqrt(RVOMath.absSq(v))
end

RVOMath.leftOf = function(a, b, c)
	return RVOMath.det(a:minus(c), b:minus(a))
end

RVOMath.KeyValuePair = function(key, value)
	return {
		key = key,
		value = value
	}
end

RVOMath.judgeReturn = function( judgeValue, a, b )
	if judgeValue then
		return a
	end
	return b
end

return RVOMath