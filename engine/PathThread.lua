--------------------------------------------------------------------------------
-- PathThread.lua
--
-- A system for processing pathfinding jobs in a separate thread.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

require "love.filesystem"

-- Special function to load files since 'require' doesn't work for some reason
local load = love.filesystem.load
local function loadClass(file)
	local chunk = load(file)
	return chunk()
end

-- Require necessary files
local Class = loadClass("lib/Class.lua")
local PriorityQueue = loadClass("lib/PriorityQueue.lua")
local Pathfinder = loadClass("lib/Pathfinder.lua")

local inbox = love.thread.getChannel("pathfinder_inbox")
local outbox = love.thread.getChannel("pathfinder_outbox")
local map = {...}
local pf = Pathfinder(map)

-- Process requests
while(true) do
	local request = inbox:demand()
	local path = pf:getPath(
		request.startX,
		request.startY,
		request.endX,
		request.endY)
	outbox:push(path)
	pf:cleanUp()
end