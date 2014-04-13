--------------------------------------------------------------------------------
-- PlayerController.lua
--
-- Component for controlling the player character.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local Entity = require "engine.Entity"
local Character = require "components.Character"
local Sprite = require "components.Sprite"
local Bullet = require "components.Bullet"
local Input = require "engine.Input"

local PlayerController = Class()

function PlayerController:init()
	self.gunAudio = love.audio.newSource("res/sounds/gunshot.wav", "static")
	self.hasMouse = false
	self.mouseTimer = 0
	self.bulletCount = 0
	self.ROF = 13
	self.bulletOffset = Vec2(9, -3)
	self.accuracy = 5
	self.useJoystick = false
	self.lastDir = Vec2(1, 0)
	self.walkSpeed = 300
	self.runSpeed = 850
end

function PlayerController:start()
	self.character = self.entity:getComponent(Character)
end

function PlayerController:makeBullet(dir)
	-- Create a new bullet and place it properly
	local ent = Entity()
	local adj = self.bulletOffset:rotate(self.transform.rot)
	ent.transform.pos = self.transform.pos + adj
	ent.transform:setOrigin(Vec2(8, 0))
	-- Get a random angle to shoot at
	local angle = dir:asAngle()
	local rand = love.math.random()
	angle = angle + rand * (1 / self.accuracy) - (1 / self.accuracy ) / 2
	local charBody = self.body
	-- Get the velocity vector for the new bullet
	local velVector = Vec2.fromAngle(angle) * 1000
	velVector = velVector + Vec2(charBody:getLinearVelocity())
	-- Set up the new bullet's body
	ent:addBody(love.physics.newBody(physWorld, 0, 0, "dynamic"), 0, true)
	local fix = ent:addShape(love.physics.newCircleShape(3), 0.1)
	fix:setRestitution(0.03)
	ent:addComponent(Bullet, velVector)
	ent:addComponent(Sprite, "res/images/bullet.png")
end

function PlayerController:update(dt)
	-- Do movement
	local i = Input.getMovementVector()
	local speed = self.walkSpeed
	if Input.getSprint() then
		speed = self.runSpeed
	end
	self.character:push(speed * i)
	-- Change look direction
	local dir = Input.getLookVector()
	self.entity.transform.rot = dir:asAngle()
	-- Reset the bullet count
	if Input.getFireDown() then
		self.bulletCount = 3
	end
	-- Fire bulets if we have bullets to fire
	if self.bulletCount >0 then
		if love.timer.getTime() > self.mouseTimer + 1/self.ROF then
			self.hasMouse = true
			self.gunAudio:setVolume(0.25)
			love.audio.rewind(self.gunAudio)
			love.audio.play(self.gunAudio)
			self:makeBullet(dir)
			self.mouseTimer = love.timer.getTime()
			self.bulletCount = self.bulletCount - 1
		end
	end
end

return PlayerController