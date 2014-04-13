--------------------------------------------------------------------------------
-- PathManager.lua
--
-- Runs and keeps track of a pathfinding system running in a separate thread.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local List = require "lib.List"

local PathManager = Class()

local tileSize = 32

-- PathManager constructor
function PathManager:init(map)
	self.thread = love.thread.newThread("engine/PathThread.lua")
	self.inChannel = love.thread.getChannel("pathfinder_inbox")
	self.outChannel = love.thread.getChannel("pathfinder_outbox")
	self.map = map
	self.continueUpdate = true
	self.queue = List()
end

-- Called when the game loads
function PathManager:start()
	self.thread:start(unpack(self.map))
end

-- Creates a new pathfinding request
function PathManager:queuePath(startPos, endPos, callee, callback)
	-- Convert world coordinates to nood coordinates
	startPos = startPos / tileSize
	endPos = endPos / tileSize
	local startX, startY = math.floor(startPos.x), math.floor(startPos.y)
	local endX, endY = math.floor(endPos.x), math.floor(endPos.y)
	self.inChannel:push({
		startX = startX,
		startY = startY,
		endX = endX,
		endY = endY
	})
	self.queue:pushLeft({callee=callee, callback=callback})
end

-- Called every frame, does callbacks if finished path requests are ready
function PathManager:update()
	if self.continueUpdate then
		local err = self.thread:getError()
		if err then
			print("Thread error: " .. tostring(err))
			self.continueUpdate = false
		end
		-- Pop off all finished requests and do callbacks
		local res = self.outChannel:pop()
		while res ~= nil do
			local call = self.queue:popRight()
			call.callback(call.callee, res)
			res = self.outChannel:pop()
		end
	end
end

return PathManager