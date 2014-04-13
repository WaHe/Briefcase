--------------------------------------------------------------------------------
-- main.lua
--
-- Main Lua file for Get in, Get the Briefcase, Get Out.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

local Vec2 = require "lib.Vec2_ffi"
local Entity = require "engine.Entity"
local Input = require "engine.Input"
local Sprite = require "components.Sprite"
local Character = require "components.Character"
local PlayerController = require "components.PlayerController"
local Tileset = require "components.Tileset"
local MapGenerator = require "components.MapGenerator"
local PathFollower = require "components.PathFollower"
local PhysSetup = require "engine.PhysSetup"
local PathManager = require "engine.PathManager"

physWorld = PhysSetup.new()

local mapGen = MapGenerator(10, 10)
local ts = Tileset(mapGen:getMap(), mapGen:getWidth(), mapGen:getHeight())

local path
pathManager = PathManager(ts.map)

playerEnt = Entity()
playerEnt.transform.pos = Vec2(80, 80)
playerEnt.transform:setOrigin(Vec2(12, 18))
playerEnt:addBody(love.physics.newBody(physWorld, 0, 0, "dynamic"), 5, true)
local fix = playerEnt:addShape(love.physics.newCircleShape(9), 3)
fix:setRestitution(0.2)
playerEnt:addComponent(Character, 9)
playerEnt:addComponent(PlayerController)
playerEnt:addComponent(Sprite, "res/images/player/pistol/idle.png")

local follower = Entity()
follower.transform.pos = Vec2(160, 160)
follower.transform:setOrigin(Vec2(12, 18))
follower:addBody(love.physics.newBody(physWorld, 0, 0, "dynamic"), 5, true)
fix = follower:addShape(love.physics.newCircleShape(9), 3)
fix:setRestitution(0.2)
follower:addComponent(Character, 9)
follower:addComponent(Sprite, "res/images/player/pistol/idle.png")



local function updatePath(p)
	path = p
end

scaling = 1

w, h = love.window.getDimensions()
canvas = love.graphics.newCanvas(w / scaling, h / scaling)
canvas:setFilter("nearest", "nearest")

function love.load(args)
	pathManager:start()
	follower:addComponent(PathFollower)
end
function love.update(dt)
	local mousePos = Vec2(love.mouse.getPosition()) / scaling + playerEnt.transform.pos - Vec2(w/(2 * scaling), h/(2 * scaling))
	pathManager:update()
	Input:updateJoysticks()
	physWorld:update(dt)
	Entity.doUpdates(dt)
	if Input.getKeyDown("escape") then
		love.event.quit()
	end
	Input:updateKeys()
end

function love.draw()
	canvas:clear()
	love.graphics.setCanvas(canvas)
	love.graphics.push()
	local x = playerEnt.transform.pos.x
	local y = playerEnt.transform.pos.y
	love.graphics.translate(
		math.floor(w/(2 * scaling) - x),
		math.floor(h/(2 * scaling) - y))
	ts:draw()
	if path ~= nil then
		drawPath(path, 32)
	end
	Entity.doDraws()
	love.graphics.pop()
	love.graphics.setCanvas()
	love.graphics.draw(canvas, 0, 0, 0, scaling, scaling)
	love.graphics.print("FPS: ".. love.timer.getFPS(), 10, 20)
end