

local service = require "service.service"

local client = require "client.client"

local protocol = ...
local Data = {}
local CMD = {}

service.init {
	command = CMD,
	info =  Data,
	init =  function ()
		client.init "proto"
	end,
}
