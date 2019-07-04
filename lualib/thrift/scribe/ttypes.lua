
require 'thrift.Thrift'

ResultCode = {
    OK = 0,
    RY_LATER = 1
}

LogEntry = __TObject:new{
}

function LogEntry:read(iprot)
    iprot:readStructBegin()
    while true do
        local fname, ftype, fid = iprot:readFieldBegin()
        if ftype == TType.STOP then
            break
        elseif fid == 1 then
            self:read_field_1(iprot, ftype)
        elseif fid == 2 then
            self:read_field_2(iprot, ftype)
        else
            iprot:skip(ftype)
        end

        iprot:readFieldEnd()
    end
    iprot:readStructEnd()
end

-- category
function LogEntry:read_field_1(iprot, ftype)
    if ftype == TType.STRING then
        self.category = iprot:readString()
    else
        iprot:skip(ftype)
    end
end

-- message
function LogEntry:read_field_2(iprot, ftype)
    if ftype == TType.STRING then
        self.message = iprot:readString()
    else
        iprot:skip(ftype)
    end
end

function LogEntry:write(oprot)
    oprot:writeStructBegin('LogEntry')
    self:write_field_1(oprot)
    self:write_field_2(oprot)
    oprot:writeFieldStop()
    oprot:writeStructEnd()
end

-- category
function LogEntry:write_field_1(oprot)
    oprot:writeFieldBegin('category', TType.STRING, 1)
    oprot:writeString(self.category)
    oprot:writeFieldEnd()
end

-- message
function LogEntry:write_field_2(oprot)
    oprot:writeFieldBegin('message', TType.STRING, 2)
    oprot:writeString(self.message)
    oprot:writeFieldEnd()
end

