local singleton = class("singleton")


local _instance = nil
function singleton.instance()
	if not _instance then
		_instance = singleton.new()
	end
	return _instance
end

return singleton
