local M = {}

function M.band(a, b) return a & b end
function M.bor(a, b) return a | b end
function M.bxor(a, b) return a ~ b end
function M.rshift(a, b) return  a >> b end
function M.lshift(a, b) return  a << b end
function M.bnot(a) return ~a end

return M
