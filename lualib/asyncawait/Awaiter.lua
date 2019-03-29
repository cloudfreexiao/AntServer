return {
    new = function(tbl)
        if(tbl.__type=='Awaiter')then
            return tbl
        end
        local obj
        obj = {
            __type = 'Awaiter',
            __needRef = true,
            onSuccess= function(_,o)
                tbl.onSuccess(o)
            end,
            onError= function(_,e)
                tbl.onError(e)
            end
        }
        return obj
    end
}