

local ldexp = math.ldexp or function (x, exp)
    return x * 2.0  ^ exp
end

local MOD = 2^32
local M = {}


function M.band(a, b) return a & b end
function M.bor(a, b) return a | b end
function M.bxor(a, b) return a ~ b end
function M.rshift(a, b) return  a >> b end
function M.lshift(a, b) return  a << b end
function M.bnot(a) return ~a end

local function rrotate(x, disp)  -- Lua5.2 inspired
    disp = disp % 32
    local low = M.band(x, 2^disp-1)
    return M.rshift(x, disp) + M.lshift(low, 32-disp)
end

function M.lrotate(x, disp)  -- Lua5.2 inspired
    return rrotate(x, -disp)
end

function M.rol(x, disp)
    return M.lrotate(x % MOD, disp)
end


return {
    ldexp = ldexp,
    bit = M,
}