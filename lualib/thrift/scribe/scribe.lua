require 'base.thrift.Thrift'
require 'base.thrift.scribe.ttypes'

ScribeClient = __TObject.new(__TClient, {
	__type = 'ScribeClient'
})

function ScribeClient:Log(entry)
	self._seqid = self._seqid + 1
	local ok = self:sendLog(entry)
	if not ok then
		return ok, ResultCode.RY_LATER
	end
	return ok, self:recvLog() --ResultCode.OK
end

-- messages -> LogEntry数组
function ScribeClient:sendLog(messages)
	self.oprot:writeMessageBegin('Log', TMessageType.CALL, self._seqid)
	local args = ScribeLogArgs:new{}
	args.messages = messages
	args:write(self.oprot)
	self.oprot:writeMessageEnd()
	return self.oprot.trans:flush()
end

function ScribeClient:recvLog()
	local fname, mtype, rseqid = self.iprot:readMessageBegin()
	if mtype == TMessageType.EXCEPTION then
		local x = TApplicationException:new{}
		x:read(self.iprot)
		self.iprot:readMessageEnd()
		error(x)
	end

	local result = ScribeLogResult:new{}
	result:read(self.iprot)
	self.iprot:readMessageEnd()
	if result.success then
		return result.success
	end
	error(TApplicationException:new{errorCode = TApplicationException.MISSING_RESULT})
end

-- TODO: process
ScribeServiceIface = __TObject:new {
	__type = 'ScribeServiceIface'
}

ScribeServiceProcessor = __TObject.new(__TProcessor, {
	__type = 'ScribeServiceProcessor'
})

function ScribeServiceProcessor:process(iprot, oprot, server_ctx)
	local name, mtype, seqid = iprot:readMessageBegin()
	local func_name = 'process_' .. name
	if not self[func_name] or ttype(self[func_name]) ~= 'function' then
		iprot:skip(TType.STRUCT)
		iprot:readMessageEnd()
		local x = TApplicationException:new{
			errorCode = TApplicationException.UNKNOWN_METHOD
		}
		oprot:writeMessageBegin(name, TMessageType.EXCEPTION, seqid)
		x:write(oprot)
		oprot:writeMessageEnd()
		oprot.trans:flush()
	else
		self[func_name](self, seqid, iprot, oprot, server_ctx)
	end
end

function ScribeServiceProcessor:process_Log(seqid, iprot, oprot, server_ctx)
	local args = ScribeLogArgs:new{}
	local reply_type = TMessageType.REPLY
	args:read(iprot)
	iprot:readMessageEnd()
	local result = ScribeLogResult:new{}
	local status, res = pcall(self.handler.Log, self.handler, args.messages)
	if not status then
		reply_type = TMessageType.EXCEPTION
		result = TApplicationException:new{message = res}
	else
		result.success = res
	end
	oprot:writeMessageBegin('Log', reply_type, seqid)
	result:write(oprot)
	oprot:writeMessageEnd()
	oprot.trans:flush()
end


-- HELPER FUNCTIONS AND STRUCTURES
ScribeLogArgs = __TObject:new {
	messages = {},
}

function ScribeLogArgs:read(iprot)
	iprot:readStructBegin()
	while true do
		local fname, ftype, fid = iprot:readFieldBegin()
		if ftype == TType.STOP then
			break
		elseif fid == 1 then
			self:read_field_1(iprot, ftype)
		else
			iprot:skip(ftype)
		end
	end
end

function ScribeLogArgs:read_field_1(iprot, ftype)
	if ftype == TType.LIST then
		local _, size = iprot:readListBegin()
		for n=1, size do
			local msg = LogEntry:new{}
			msg:read(iprot)
			table.insert(self.messages, msg)
		end
		iprot:readListEnd()	
	end
end

function ScribeLogArgs:write(oprot)
	oprot:writeStructBegin('Log_args')
	self:write_field_1(oprot)
	oprot:writeFieldStop()
	oprot:writeStructEnd()
end

function ScribeLogArgs:write_field_1(oprot)
	oprot:writeFieldBegin('messages', TType.LIST, 1)
	oprot:writeListBegin(TType.STRUCT, ttable_size(self.messages))
	for _, v in ipairs(self.messages) do
		v:write(oprot)
	end
	oprot:writeListEnd()
	oprot:writeFieldEnd()
end


ScribeLogResult = __TObject:new{
}

function ScribeLogResult:read(iprot)
	iprot:readStructBegin()
	while true do
		local fname, ftype, fid = iprot:readFieldBegin()
		if ftype == TType.STOP then
			break
		elseif fid == 0 then
			self:read_field_0(iprot, ftype)
		else
			iprot:skip(ftype)
		end
		iprot:readFieldEnd()
	end
	iprot:readStructEnd()
end

function ScribeLogResult:read_field_0(iprot, ftype)
	if ftype == TType.I32 then
		self.success = iprot:readI32()
	else
		self.success = ResultCode.OK
		iprot:skip(ftype)
	end
end

function ScribeLogResult:write(oprot)
	oprot:writeStructBegin('Log_result')
	self:write_field_0(oprot)
	oprot:writeFieldStop()
	oprot:writeStructEnd()
end

function ScribeLogResult:write_field_0(oprot)
	oprot:writeFieldBegin('success', TType.I32, 0)
    oprot:writeI32(self.success)
    oprot:writeFieldEnd()
end