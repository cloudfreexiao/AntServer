

local ldexp = math.ldexp or function (x, exp)
    return x * 2.0  ^ exp
end


return {
    ldexp = ldexp,
}