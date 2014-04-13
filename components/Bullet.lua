--------------------------------------------------------------------------------
-- Bullet.lua
--
-- Component for things that go shooty shooty.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local Sprite = require "components.Sprite"

local Bullet = Class()

function Bullet:init(velocity)
	self.velocity = velocity
	self.randomBurnout = love.math.random() * 300 - 150
	self.framesAlive = 0
end

function Bullet:start()
	self.body:setLinearVelocity(self.velocity.x, self.velocity.y)
	self.entity:getComponent(Sprite).enabled = false
end

function Bullet:update(dt)
	local linearVelocity = Vec2(self.body:getLinearVelocity())
	local mag = #linearVelocity
	self.entity.transform.pos = Vec2(self.body:getX(),self.body:getY())
	self.entity.transform.rot = math.atan2(linearVelocity.y, linearVelocity.x)
	self.entity.transform.scale.x = mag / 300 + 1/20
	if mag < 500 + self.randomBurnout then
		self.entity:destroy()
	end
	self.framesAlive = self.framesAlive + 1
	if self.framesAlive > 1 then
		self.entity:getComponent(Sprite).enabled = true
	end
end

return Bullet