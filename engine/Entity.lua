--------------------------------------------------------------------------------
-- Entity.lua
--
-- Lua Component-Entity system for LÖVE 2D.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Transform = require "engine.Transform"
local Vec2 = require "lib.Vec2_ffi"

local Entity = Class()
Entity.entities = {}

local entNum = 1

-- Entity constructor. Also adds the new entity to a list
function Entity:init()
	self.transform = Transform()
	self.components = {}
	self.shapes = {}
	self.fixtures = {}
	self.didStart = {}
	self.id = entNum
	entNum = entNum + 1
	table.insert(Entity.entities, self)
end

-- Calls the update functions of all the components on this entity
function Entity:update(dt)
	-- Update position to be the position of the body
	if self.body then
		self.transform.pos = Vec2(self.body:getX(), self.body:getY())
		self.transform.rot = self.body:getAngle()
	end
	for k,c in pairs(self.components) do
		if not self.didStart[k] then
			self:doCallback(c, "start")
			self.didStart[k] = true
		end
		self:doCallback(c, "update", dt)
	end
	-- If we moved this entity around, set the body to be at this position
	if self.body then
		self.body:setPosition(self.transform.pos:unpack())
		self.body:setAngle(self.transform.rot)
	end
end

-- Calls the draw functions of all the components on this entity
function Entity:draw()
	self:doAllCallbacks("draw")
end

-- beginContact callback
function Entity:beginContact(other, coll)
	self:doAllCallbacks("beginContact", other, coll)
end

-- endContact callback
function Entity:endContact(other, coll)
	self:doAllCallbacks("endContact", other, coll)
end

-- preSolve callback
function Entity:preSolve(other, coll)
	self:doAllCallbacks("preSolve", other, coll)
end

-- postSolve callback
function Entity:postSolve(other, coll)
	self:doAllCallbacks("postSolve", other, coll)
end

-- Destroys an entity
function Entity:destroy()
	self:doAllCallbacks("destroy")
	for k,v in pairs(Entity.entities) do
		if v == self then
			Entity.entities[k] = nil
		end
	end
	if self.body then
		self.body:destroy()
		self.body = nil
	end
end

-- Calls all the functions of a given name in the components on this entity
function Entity:doAllCallbacks(callback, ...)
	for _,c in pairs(self.components) do
		self:doCallback(c, callback, ...)
	end
end

function Entity:doCallback(component, callback, ...)
	local fn = component[callback]
	if fn and (type(fn) == "function") then
		fn(component, ...)
	end
end

-- Adds a component to an entity
function Entity:addComponent(c, ...)
	local newComp = c(...)
	newComp.entity = self
	newComp.transform = self.transform
	if not newComp.body then
		newComp.body = self.body
	end
	self.components[c] = newComp
	return newComp
end

function Entity:addBody(body, damping, bullet)
	self.body = body
	body:setPosition(self.transform.pos:unpack())
	body:setAngle(self.transform.rot)
	body:setLinearDamping(damping)
	self.body:setBullet(bullet)
	for _,c in pairs(self.components) do
		c.body = body
	end
	return body
end

function Entity:addShape(shape, density)--, restitution, friction)
	table.insert(self.shapes, shape)
	local newFixture = love.physics.newFixture(self.body, shape, density)
	newFixture:setUserData(self)
	table.insert(self.fixtures, newFixture)
	return newFixture
end

function Entity:removeBody()
	self.body:destroy()
	for _,c in pairs(self.components) do
		c.body = nil
	end
	self.body = nil
end

--- Removes a component from an entity
function Entity:removeComponent(c)
	self:doCallback(self.components[c], "destroy")
	self.didStart[c] = false
	table.remove(self.components, c)
end

--- Gets a component of a given class
function Entity:getComponent(c)
	return self.components[c]
end

--- Calls the update functions for all the components in all the entities
function Entity.doUpdates(dt)
	for k,v in pairs(Entity.entities) do
		v:update(dt)
	end
end

---Calls the draw functions for all the components in all the entities
function Entity.doDraws()
	for k,v in pairs(Entity.entities) do
		v:draw()
	end
end

return Entity