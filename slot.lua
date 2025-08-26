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


-- Funktion um .nfp Bilder zu erstellen
local function createImages()
    -- Cherry (Kirsche) - rot
    local cherry = "eeeeeeee\ne4444eee\n44444444\n44444444\n44444444\n44444444\ne4444eee\neeeeeeee"
    
    -- Lemon (Zitrone) - gelb
    local lemon = "eeeeeeee\neeefffee\neef444fe\nef44444f\nf444444f\nef44444e\neef44fee\neeeeeeee"
    
    -- Bell (Glocke) - grau/silber
    local bell = "eeeeeeee\neee88eee\nee8888ee\ne888888e\ne888888e\ne888888e\nee8888ee\neeeeeeee"
    
    -- Bar - weiß
    local bar = "eeeeeeee\nefffffff\nefffffff\nefffffff\nefffffff\nefffffff\nefffffff\neeeeeeee"
    
    -- Seven (7) - gold/gelb
    local seven = "eeeeeeee\ne444444e\neeeeee4e\neeeee4ee\neee4eee\neee4eeee\nee4eeeee\ne4eeeeee"
    
    -- Bilder als Dateien speichern
    local images = {
        cherry = cherry,
        lemon = lemon,
        bell = bell,
        bar = bar,
        seven = seven
    }
    
    for name, data in pairs(images) do
        local file = fs.open(name .. ".nfp", "w")
        file.write(data)
        file.close()
    end
end

-- Erstelle Bilder beim ersten Start
if not fs.exists("cherry.nfp") then
    createImages()
end

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

-- Create slot display boxes
local slotBox1 = main:addFrame()
    :setPosition(3, 6)
    :setSize(8, 6)
    :setBackground(colors.white)
    :setBorder(colors.gray)

local slotBox2 = main:addFrame()
    :setPosition(14, 6)
    :setSize(8, 6)
    :setBackground(colors.white)
    :setBorder(colors.gray)

local slotBox3 = main:addFrame()
    :setPosition(25, 6)
    :setSize(8, 6)
    :setBackground(colors.white)
    :setBorder(colors.gray)

-- Create slot symbol labels - verwende einfache Labels anstatt Frames mit Texturen
local slotLabel1 = slotBox1:addLabel()
    :setText("C")
    :setPosition(4, 3)
    :setForeground(colors.red)
    :setBackground(colors.white)

local slotLabel2 = slotBox2:addLabel()
    :setText("L")
    :setPosition(4, 3)
    :setForeground(colors.yellow)
    :setBackground(colors.white)

local slotLabel3 = slotBox3:addLabel()
    :setText("B")
    :setPosition(4, 3)
    :setForeground(colors.gray)
    :setBackground(colors.white)

-- Funktion um Symbol-Buchstaben und Farben zu setzen
local function setSlotSymbol(slotLabel, symbolName)
    local symbolData = {
        cherry = {text = "C", color = colors.red},
        lemon = {text = "L", color = colors.yellow},
        bell = {text = "B", color = colors.gray},
        bar = {text = "B", color = colors.white},
        seven = {text = "7", color = colors.orange}
    }
    
    local data = symbolData[symbolName] or {text = "?", color = colors.black}
    print("Setting symbol: " .. symbolName .. " -> " .. data.text) -- Debug
    slotLabel:setText(data.text)
    slotLabel:setForeground(data.color)
end

-- Initiale Symbole setzen (nach der Funktion definiert)
setSlotSymbol(slotLabel1, slot1)
setSlotSymbol(slotLabel2, slot2)
setSlotSymbol(slotLabel3, slot3)

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
    if slot1 == slot2 and slot2 == slot3 then
        resultLabel:setText("GEWONNEN! " .. slot1 .. slot1 .. slot1)
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
                setSlotSymbol(slotLabel1, slot1)
            end
            
            -- Middle reel spins for 12 iterations
            if i <= 12 then
                slot2 = symbols[math.random(1, #symbols)]
                setSlotSymbol(slotLabel2, slot2)
            end
            
            -- Last reel spins for all 15 iterations
            slot3 = symbols[math.random(1, #symbols)]
            setSlotSymbol(slotLabel3, slot3)
            
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

-- Start the program
basalt.autoUpdate()


