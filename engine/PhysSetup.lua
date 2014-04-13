--------------------------------------------------------------------------------
-- PhysSetup.lua
--
-- Sets up physics callbacks for the LÖVE 2D physics engine.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

local Entity = require "engine.Entity"
local PhysSetup = {}

local function callBeginContact(data, other, coll)
	data:beginContact(other, coll)
end

local function callEndContact(data, other, coll)
	data:endContact(other, coll)
end

local function callPreSolve(data, other, coll)
	data:preSolve(other, coll)
end

local function callPostSolve(data, other, coll)
	data:postSolve(other, coll)
end

local function handleCollision(fn, a, b, coll)
	local aData = a:getUserData()
	local bData = b:getUserData()
	if aData ~= nil then
		local aMt = getmetatable(aData)
		if aMt == Entity then
			fn(aData, b, coll)
		end
	end
	if bData ~= nil then
		local bMt = getmetatable(bData)
		if bMt == Entity then
			fn(bData, a, coll)
		end
	end
end

local function beginContact(a, b, coll)
	handleCollision(callBeginContact, a, b, coll)
end

local function endContact(a, b, coll)
	handleCollision(callEndContact, a, b, coll)
end

local function preSolve(a, b, coll)
	handleCollision(callPreSolve, a, b, coll)
end

local function postSolve(a, b, coll)
	handleCollision(callPostSolve, a, b, coll)
end

function PhysSetup.new()
	local physWorld = love.physics.newWorld(0, 0, true)
	physWorld:setCallbacks(beginContact, endContact, preSolve, postSolve)
	return physWorld
end

return PhysSetup