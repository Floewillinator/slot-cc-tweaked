-- Slot machine for ComputerCraft with Basalt UI

local basalt = require("basalt")

local monitor = peripheral.find("monitor")

-- Check if monitor is found
if not monitor then
    error("No monitor found!")
end

-- Configure monitor for 2x2 setup
monitor.setTextScale(0.5)
local w, h = monitor.getSize()

-- Create MonitorFrame using basalt.addMonitor()
local main = basalt.addMonitor()
    :setMonitor(monitor)
    :setSize(w, h)
    :setBackground(colors.black)

-- Slot symbols - jetzt Bildpfade anstatt Zahlen
local symbols = {"cherry", "lemon", "bell", "bar", "seven"}

-- Current slot values - setze auf richtige Symbol-Namen
local slot1 = "cherry"
local slot2 = "lemon" 
local slot3 = "bell"

-- Animation state
local isSpinning = false

-- Create title
local title = main:addLabel()
    :setText("SLOT MACHINE")
    :setPosition(14, 2)
    :setForeground(colors.yellow)

-- Create slot display boxes - make them bigger to better fit images
local slotBox1 = main:addFrame()
    :setPosition(3, 6)
    :setSize(10, 8)
    :setBackground(colors.white)
    :setBorder(colors.gray)

local slotBox2 = main:addFrame()
    :setPosition(14, 6)
    :setSize(10, 8)
    :setBackground(colors.white)
    :setBorder(colors.gray)

local slotBox3 = main:addFrame()
    :setPosition(25, 6)
    :setSize(10, 8)
    :setBackground(colors.white)
    :setBorder(colors.gray)

-- Create fallback labels for each slot (will be used if image loading fails)
local slotLabel1 = slotBox1:addLabel()
    :setText("")
    :setPosition(5, 4)
    :setForeground(colors.red)
    :setBackground(colors.white)

local slotLabel2 = slotBox2:addLabel()
    :setText("")
    :setPosition(5, 4)
    :setForeground(colors.yellow)
    :setBackground(colors.white)

local slotLabel3 = slotBox3:addLabel()
    :setText("")
    :setPosition(5, 4)
    :setForeground(colors.gray)
    :setBackground(colors.white)

-- Setzt die Standardpalette auf dem Monitor (wichtig für Basalt/NFP)
local function setMonitorPalette(monitor)
    if monitor and monitor.setPaletteColor then
        -- Standardfarben aus colors.lua
        local palette = {
            [colors.white]     = 0xF0F0F0,
            [colors.orange]    = 0xF2B233,
            [colors.magenta]   = 0xE57FD8,
            [colors.lightBlue] = 0x99B2F2,
            [colors.yellow]    = 0xDEDE6C,
            [colors.lime]      = 0x7FCC19,
            [colors.pink]      = 0xF2B2CC,
            [colors.gray]      = 0x4C4C4C,
            [colors.lightGray] = 0x999999,
            [colors.cyan]      = 0x4C99B2,
            [colors.purple]    = 0xB266E5,
            [colors.blue]      = 0x3366CC,
            [colors.brown]     = 0x7F664C,
            [colors.green]     = 0x57A64E,
            [colors.red]       = 0xCC4C4C,
            [colors.black]     = 0x111111,
        }
        for k, v in pairs(palette) do
            monitor.setPaletteColor(k, v)
        end
    end
end

setMonitorPalette(monitor)

-- Function to set symbols - use only Basalt BIMG images, force a redraw and add debug info
local function setSlotSymbol(slotBox, slotLabel, symbolName)
    local symbolData = {
        cherry = {text = "C", color = colors.red},
        lemon = {text = "L", color = colors.yellow},
        bell = {text = "B", color = colors.lightGray},
        bar = {text = "B", color = colors.white},
        seven = {text = "7", color = colors.orange}
    }
    local data = symbolData[symbolName] or {text = "?", color = colors.black}
    slotBox:removeChildren()
    local imageObject = slotBox:addImage()
        :setPosition(1, 1)
    local bimgPath = symbolName .. ".bimg"
    local loaded = false
    if fs.exists(bimgPath) then
        local ok, err = pcall(function()
            imageObject:loadImage(bimgPath)
            -- Force redraw by selecting frame (even if only one)
            if imageObject.getFrameCount and imageObject:getFrameCount() > 0 then
                imageObject:selectFrame(1)
            end
            -- Debug: print frame count and metadata
            if imageObject.getFrameCount then
                print(symbolName .. ".bimg frame count: " .. tostring(imageObject:getFrameCount()))
            end
            if imageObject.getMetadata then
                local meta = imageObject:getMetadata()
                print(symbolName .. ".bimg metadata: " .. textutils.serialize(meta))
            end
        end)
        if ok then
            print("Successfully loaded and displayed image: " .. bimgPath)
            loaded = true
        else
            print("Error rendering image: " .. tostring(err))
            imageObject:remove()
        end
    end
    if not loaded then
        print("BIMG image file not found or failed: " .. bimgPath)
        local label = slotBox:addLabel()
            :setText(data.text)
            :setForeground(data.color)
            :setBackground(colors.white)
            :setPosition(4, 3)
            :setSize(3, 3)
        return false
    end
    return true
end

-- DEBUG: Draw BIMG directly on the main frame (ohne slotBox) zum Test
local function debugDrawBimg(symbolName, x, y)
    local imageObject = main:addImage()
        :setPosition(x, y)
    local bimgPath = symbolName .. ".bimg"
    if fs.exists(bimgPath) then
        local ok, err = pcall(function()
            imageObject:loadImage(bimgPath)
            if imageObject.getFrameCount and imageObject:getFrameCount() > 0 then
                imageObject:selectFrame(1)
            end
        end)
        if ok then
            print("DEBUG: BIMG '"..bimgPath.."' drawn at ("..x..","..y..")")
        else
            print("DEBUG: Error rendering BIMG: " .. tostring(err))
            imageObject:remove()
        end
    else
        print("DEBUG: BIMG not found: " .. bimgPath)
    end
end

-- Initiale Symbole setzen
setSlotSymbol(slotBox1, slotLabel1, slot1)
setSlotSymbol(slotBox2, slotLabel2, slot2)
setSlotSymbol(slotBox3, slotLabel3, slot3)

-- DEBUG: Draw test images directly on the main frame (bypassing slotBox)
debugDrawBimg("cherry", 1, 1)
debugDrawBimg("lemon", 10, 1)
debugDrawBimg("bell", 19, 1)

-- Create spin button
local spinButton = main:addButton()
    :setText("SPIN!")
    :setPosition(12, 15)
    :setSize(12, 3)
    :setBackground(colors.green)
    :setForeground(colors.white)

-- Create result display
local resultLabel = main:addLabel()
    :setText("")
    :setPosition(5, 20)
    :setForeground(colors.yellow)

-- Function to check for win
local function checkWin()
    -- Define symbol values for scoring
    local symbolValues = {
        cherry = 1,
        lemon = 2,
        bell = 3,
        bar = 4,
        seven = 5
    }
    
    if slot1 == slot2 and slot2 == slot3 then
        local winValue = symbolValues[slot1] or 0
        local winMessage = "GEWONNEN! " .. string.upper(slot1) .. " x3"
        resultLabel:setText(winMessage)
        resultLabel:setForeground(colors.lime)
        -- Flash effect
        slotBox1:setBackground(colors.yellow)
        slotBox2:setBackground(colors.yellow)
        slotBox3:setBackground(colors.yellow)
    else
        resultLabel:setText("Versuchen Sie es nochmal!")
        resultLabel:setForeground(colors.red)
        slotBox1:setBackground(colors.white)
        slotBox2:setBackground(colors.white)
        slotBox3:setBackground(colors.white)
    end
end

-- Function to spin the slots
local function spin()
    if isSpinning then return end
    
    isSpinning = true
    resultLabel:setText("Spinning...")
    resultLabel:setForeground(colors.white)
    
    -- Animation function for the thread
    local function animate()
        for i = 1, 15 do
            -- All reels spin for first 10 iterations
            if i <= 10 then
                slot1 = symbols[math.random(1, #symbols)]
                setSlotSymbol(slotBox1, slotLabel1, slot1)
            end
            
            -- Middle reel spins for 12 iterations
            if i <= 12 then
                slot2 = symbols[math.random(1, #symbols)]
                setSlotSymbol(slotBox2, slotLabel2, slot2)
            end
            
            -- Last reel spins for all 15 iterations
            slot3 = symbols[math.random(1, #symbols)]
            setSlotSymbol(slotBox3, slotLabel3, slot3)
            
            -- Visual feedback when reels stop
            if i == 10 then
                slotBox1:setBackground(colors.lightGray)
            elseif i == 12 then
                slotBox2:setBackground(colors.lightGray)
            end
            
            -- Delay between spins
            if i <= 5 then
                os.sleep(0.1)
            elseif i <= 10 then
                os.sleep(0.2)
            else
                os.sleep(0.3)
            end
        end
        
        -- Final result
        isSpinning = false
        checkWin()
    end
    
    -- Create and start animation thread
    local animationThread = main:addThread()
    animationThread:start(animate)
end

-- Spin button click event
spinButton:onClick(function()
    spin()
end)


-- Remove the testImageRendering function that was causing issues
-- and simplify the debug output
local function printDebugInfo()
    local currentDir = shell.dir()
    print("Current directory: " .. currentDir)
    print("NFP files should be in: " .. currentDir)
    
    local fileCount = 0
    for _, name in ipairs(fs.list(currentDir)) do
        if name:match("%.nfp$") then
            fileCount = fileCount + 1
            print("Found: " .. name)
        end
    end
    
    print("Total NFP files found: " .. fileCount)
end
printDebugInfo()

-- Start the program
basalt.autoUpdate()
