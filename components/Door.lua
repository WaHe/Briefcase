--------------------------------------------------------------------------------
-- Door.lua
--
-- Component for doors.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local Input = require "engine.Input"
local Character = require "components.Character"

local Door = Class()

function Door:init()
	
end

function Door:update(dt)
	self.transform.pos = Vec2(self.body:getX(), self.body:getY())
	self.transform.rot = self.body:getAngle()
	local offset = Vec2.fromAngle(self.transform.rot) * 8
	local target = self.transform.pos + offset
	-- Pressed the door grab button
	if Input.getDoorGrabDown() then
		local cb = playerEnt:getComponent(Character)
		-- Is the door in range of the character?
		if #(playerEnt.transform.pos - target) < 30 and self.grabJoint == nil and not cb.holdingDoor then
			cb.holdingDoor = true
			-- Create the joint
			self.grabJoint = love.physics.newDistanceJoint(
				self.body,
				cb.body,
				target.x, target.y,
				playerEnt.transform.pos.x, playerEnt.transform.pos.y,
				true)
		end
	-- Released the door grab button
	elseif Input.getDoorGrabUp() and self.grabJoint then
		local cb = playerEnt:getComponent(Character)
		cb.holdingDoor = false
		self.grabJoint:destroy()
		self.grabJoint = nil
	elseif self.grabJoint then
		local cb = playerEnt:getComponent(Character)
		local reaction = Vec2(self.grabJoint:getReactionForce(1 / dt))
		-- Destroy the joint if there's too much force on the joint
		if #reaction > 3000 then
			print("destroying 2: " .. #reaction)
			local cb = playerEnt:getComponent(Character)
			cb.holdingDoor = false
			self.grabJoint:destroy()
			self.grabJoint = nil
		end
	end
end

function Door:draw()
	if self.grabJoint then
		love.graphics.line(self.grabJoint:getAnchors())
	end
end
return Door