-- Simple Quarry Program for Mining Turtle (3-layer mining)
-- Place chest behind starting position
-- Turtle slot 1: fuel (coal), slots 2-16: storage

local width = 32  -- Quarry width
local length = 32 -- Quarry length
local depth = 64  -- Max depth to mine

local startX, startY, startZ = 0, 0, 0
local x, y, z = 0, 0, 0
local facing = 0 -- 0=forward, 1=right, 2=back, 3=left

-- Junk items to discard (not ores)
local junk = {
    ["minecraft:cobblestone"] = true,
    ["minecraft:stone"] = true,
    ["minecraft:dirt"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:sand"] = true,
    ["minecraft:netherrack"] = true,
    ["minecraft:granite"] = true,
    ["minecraft:diorite"] = true,
    ["minecraft:andesite"] = true,
    ["minecraft:deepslate"] = true,
    ["minecraft:cobbled_deepslate"] = true,
    ["minecraft:tuff"] = true,
}

-- Movement tracking
function turnRight()
    turtle.turnRight()
    facing = (facing + 1) % 4
end

function turnLeft()
    turtle.turnLeft()
    facing = (facing - 1) % 4
end

function moveForward()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            turtle.attack() -- Handle mobs
        end
        sleep(0.2)
    end
    
    if facing == 0 then z = z + 1
    elseif facing == 1 then x = x + 1
    elseif facing == 2 then z = z - 1
    elseif facing == 3 then x = x - 1
    end
end

function moveUp()
    while not turtle.up() do
        if turtle.detectUp() then
            turtle.digUp()
        else
            turtle.attackUp()
        end
        sleep(0.2)
    end
    y = y + 1
end

function moveDown()
    -- Check for bedrock
    local success, data = turtle.inspectDown()
    if success and data.name == "minecraft:bedrock" then
        return false
    end
    
    while not turtle.down() do
        if turtle.detectDown() then
            turtle.digDown()
        else
            turtle.attackDown()
        end
        sleep(0.2)
    end
    y = y - 1
    return true
end

-- Dig up and down while handling gravel
function digUpSafe()
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.2)
    end
end

function digDownSafe()
    local success, data = turtle.inspectDown()
    if success and data.name ~= "minecraft:bedrock" then
        turtle.digDown()
    end
end

-- Fuel management
function checkFuel()
    if turtle.getFuelLevel() < 100 then
        for slot = 1, 16 do
            turtle.select(slot)
            local item = turtle.getItemDetail()
            if item and (item.name == "minecraft:coal" or 
                        item.name == "minecraft:charcoal") then
                turtle.refuel(math.min(item.count, 32))
                if turtle.getFuelLevel() > 500 then
                    break
                end
            end
        end
    end
    turtle.select(1)
end

-- Inventory management
function cleanInventory()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and junk[item.name] then
            turtle.drop()
        end
    end
    turtle.select(1)
end

function isInventoryFull()
    for slot = 2, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

-- Navigation
function goToChest()
    local savedX, savedY, savedZ = x, y, z
    local savedFacing = facing
    
    -- Go to surface
    while y < 0 do
        moveUp()
    end
    
    -- Go to start X
    while x > 0 do
        while facing ~= 3 do turnRight() end
        moveForward()
    end
    
    -- Go to start Z
    while z > 0 do
        while facing ~= 2 do turnRight() end
        moveForward()
    end
    
    -- Face chest (behind start position)
    while facing ~= 2 do turnRight() end
    
    -- Deposit items
    for slot = 2, 16 do
        turtle.select(slot)
        turtle.drop()
    end
    
    -- Keep some coal for fuel
    turtle.select(1)
    local fuel = turtle.getItemDetail()
    if fuel and (fuel.name == "minecraft:coal" or 
                 fuel.name == "minecraft:charcoal") then
        if fuel.count > 32 then
            turtle.drop(fuel.count - 32)
        end
    end
    
    -- Return to mining position
    while facing ~= 0 do turnRight() end
    
    while z < savedZ do
        moveForward()
    end
    
    while facing ~= 1 do turnRight() end
    while x < savedX do
        moveForward()
    end
    
    while y > savedY do
        moveDown()
    end
    
    while facing ~= savedFacing do
        turnRight()
    end
end

-- Mine 3 layers at once
function mineThreeLayers()
    for i = 1, length do
        for j = 1, width - 1 do
            -- Mine forward, up, and down
            turtle.dig()
            digUpSafe()
            digDownSafe()
            moveForward()
            checkFuel()
            
            if isInventoryFull() then
                cleanInventory()
                if isInventoryFull() then
                    goToChest()
                end
            end
        end
        
        -- Mine the last block of the row
        digUpSafe()
        digDownSafe()
        
        if i < length then
            if i % 2 == 1 then
                turnRight()
                turtle.dig()
                digUpSafe()
                digDownSafe()
                moveForward()
                turnRight()
            else
                turnLeft()
                turtle.dig()
                digUpSafe()
                digDownSafe()
                moveForward()
                turnLeft()
            end
        end
    end
    
    -- Return to start of layer
    if length % 2 == 1 then
        turnRight()
        turnRight()
        for i = 1, width - 1 do
            moveForward()
        end
        turnRight()
    else
        turnLeft()
    end
    
    for i = 1, length - 1 do
        moveForward()
    end
    
    turnRight()
    turnRight()
end

-- Main program
print("Starting 3-layer quarry: " .. width .. "x" .. length .. "x" .. depth)
print("Place chest behind starting position")
print("Fuel level: " .. turtle.getFuelLevel())

checkFuel()

-- Start at y = -1 (one below surface)
if not moveDown() then
    print("Can't move down from start")
    return
end

local currentDepth = 1

while currentDepth <= depth do
    print("Mining layers " .. currentDepth .. " to " .. math.min(currentDepth + 2, depth))
    
    -- Mine 3 layers at current position
    mineThreeLayers()
    
    -- Check fuel before going deeper
    if turtle.getFuelLevel() < 200 then
        print("Low fuel, returning to chest")
        goToChest()
        checkFuel()
        
        if turtle.getFuelLevel() < 200 then
            print("Not enough fuel to continue")
            break
        end
    end
    
    -- Move down 3 layers for next iteration
    local movedDown = 0
    for i = 1, 3 do
        if currentDepth + 2 < depth then
            if not moveDown() then
                print("Hit bedrock at depth " .. (currentDepth + movedDown))
                break
            end
            movedDown = movedDown + 1
        end
    end
    
    if movedDown < 3 and currentDepth + 2 < depth then
        break -- Hit bedrock
    end
    
    currentDepth = currentDepth + 3
end

-- Return home
print("Quarry complete, returning to surface")
while y < 0 do
    moveUp()
end

while z > 0 do
    while facing ~= 2 do turnRight() end
    moveForward()
end

while x > 0 do
    while facing ~= 3 do turnRight() end
    moveForward()
end

-- Final deposit
while facing ~= 2 do turnRight() end
for slot = 1, 16 do
    turtle.select(slot)
    turtle.drop()
end

print("Mining complete!")
