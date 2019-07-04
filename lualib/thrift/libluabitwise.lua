local M = {}

function M.band(a, b) return a & b end
function M.bor(a, b) return a | b end
function M.bxor(a, b) return a ~ b end
function M.rshift(a, b) return  a >> b end
function M.lshift(a, b) return  a << b end
function M.bnot(a) return ~a end

function M.shiftl(a, b)
  return M.lshift(a, b)
end

function M.shiftr(a, b)
  return M.rshift(a, b)
end

-- function M.arshift(x, disp) -- Lua5.2 inspired
--   local z = M.rshift(x, disp)
--   if x >= 0x80000000 then 
--     z = z + M.lshift(2^disp-1, 32-disp) 
--   end
--   return z
-- end

return M
