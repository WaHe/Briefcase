--------------------------------------------------------------------------------
-- Input.lua
--
-- Manages button presses and joystick input.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------


local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"

local Input = {}

local wasPressed = {}
local isPressed = {}

local joyWasFiring = false
local joyIsFiring = false

local keyBindings = {
	moveUp = "w",
	moveLeft = "a",
	moveDown = "s",
	moveRight = "d",
	sprint = "lshift",
	fire = "mouse_l",
	grabDoor = "e",
}

local axisBindings = {
	moveHorizontal = 1,
	moveVertical = 2,
	lookHorizontal = 3,
	lookVertical = 6,
	sprint = 4,
	fire = 5,
	grabDoor = 1,
}

local useMouseAndKeys = true
local useJoy = false
local joyIdx = 1
local joys = love.joystick.getJoysticks()
local joyDeadzone = 0.1

local lastDir = Vec2(1, 0)

function love.keypressed(key)
	isPressed[key] = true
end

function love.keyreleased(key)
	isPressed[key] = false
end

function love.mousepressed(x, y, button)
	isPressed["mouse_" .. button] = true
end

function love.mousereleased(x, y, button)
	isPressed["mouse_" .. button] = false
end

function Input.updateJoysticks()
	if useJoy then
		joys = love.joystick.getJoysticks()
		joyIsFiring = joys[joyIdx]:getAxis(axisBindings.fire) > 0
	end
end

function Input.updateKeys()
	-- Copy the current values to be used as the next values
	for k,v in pairs(isPressed) do
		wasPressed[k] = v
	end
	wasPressed["mouse_wu"] = false
	wasPressed["mouse_wd"] = false
	joyWasFiring = joyIsFiring
end

-- Returns true if the key was pressed during this frame
function Input.getKeyDown(key)
	return (not wasPressed[key]) and isPressed[key]
end

-- Returns true if the key was released during this frame
function Input.getKeyUp(key)
	return wasPressed[key] and (not isPressed[key])
end

-- Gets whether a key is pressed
function Input.getKey(key)
	return isPressed[key]
end

local function hatToVector(s)
	if s == "c" then
		return Vec2(0, 0)
	elseif s == "r" then
		return Vec2(1, 0)
	elseif s == "ru" then
		return Vec2(1, -1)
	elseif s == "u" then
		return Vec2(0, -1)
	elseif s == "lu" then
		return Vec2(-1, -1)
	elseif s == "l" then
		return Vec2(-1, 0)
	elseif s == "ld" then
		return Vec2(-1, 1)
	elseif s == "d" then
		return Vec2(0, 1)
	elseif s == "rd" then
		return Vec2(1, 1)
	end
	return Vec2(0, 0)
end

function Input.getHatDirection()
	return hatToVector(joys[joyIdx]:getHat(1)):normalized()
end

function Input.getMovementVector()
	local i = Vec2(0, 0)
	if useMouseAndKeys then
		if Input.getKey(keyBindings.moveRight) then
			i.x = i.x + 1
		end
		if Input.getKey(keyBindings.moveLeft) then
			i.x = i.x - 1
		end
		if Input.getKey(keyBindings.moveDown) then
			i.y = i.y + 1
		end
		if Input.getKey(keyBindings.moveUp) then
			i.y = i.y - 1
		end
	end
	if useJoy and joys[joyIdx] then
		local joyMovement = Vec2(
			joys[joyIdx]:getAxis(axisBindings.moveHorizontal),
			joys[joyIdx]:getAxis(axisBindings.moveVertical)
		)
		if joyMovement:lengthSquared() < joyDeadzone * joyDeadzone then
			joyMovement.x = 0
			joyMovement.y = 0
		end
		i = i + joyMovement
		i = i + Input.getHatDirection()
	end
	i = i:clampTo(1)
	return i
end

function Input.getLookVector()
	if useJoy then
		local dir = Vec2(
			joys[joyIdx]:getAxis(axisBindings.lookHorizontal),
			joys[joyIdx]:getAxis(axisBindings.lookVertical)
		)
		if #dir > 0.2 then
			lastDir = dir
		else
			dir = lastDir
		end
		return dir
	end
	local mousePos = Vec2(love.mouse.getPosition()) / scaling
	return Vec2(mousePos.x - w / (2 * scaling), mousePos.y - h / (2 * scaling))
end

function Input.getSprint()
	local keyInput = useMouseAndKeys and Input.getKey(keyBindings.sprint)
	local joyInput = useJoy and (joys[joyIdx]:getAxis(axisBindings.sprint) > 0)
	return keyInput or joyInput
end

function Input.getFire()
	local keyInput = useMouseAndKeys and Input.getKey(keyBindings.fire) 
	local joyInput = useJoy and (joys[joyIdx]:getAxis(axisBindings.fire) > 0)
	return keyInput or joyInput
end

function Input.getFireDown()
	local keyInput = useMouseAndKeys and Input.getKeyDown(keyBindings.fire)
	local joyInput = useJoy and (joyIsFiring and (not joyWasFiring)) 
	return keyInput or joyInput
end

function Input.getDoorGrabDown()
	local keyInput = useMouseAndKeys and Input.getKeyDown(keyBindings.grabDoor) 
	local joyInput = useJoy and (joys[joyIdx]:isDown(axisBindings.grabDoor))
	return keyInput or joyInput
end

function Input.getDoorGrabUp()
	local keyInput = useMouseAndKeys and Input.getKeyUp(keyBindings.grabDoor) 
	local joyInput = useJoy and (joys[joyIdx]:isDown(axisBindings.grabDoor))
	return keyInput or joyInput
end

function Input.getJoystick()
	return joys[joyIdx]
end

return Input