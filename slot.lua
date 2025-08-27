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

-- Slot symbols - jetzt NFP-Dateinamen
local symbols = {"cherry", "lemon", "bell", "pineapple", "seven"}

-- Current slot values - setze auf richtige Symbol-Namen
local slot1 = "cherry"
local slot2 = "lemon" 
local slot3 = "bell"

-- Animation state
local isSpinning = false

-- Create title
local title = main:addLabel()
    :setText("SLOT MACHINE")
    :setPosition(math.floor((w - 13) / 2) + 1, 2) -- 13 = Länge von "SLOT MACHINE"
    :setForeground(colors.yellow)

-- Passe SlotBox-Größen und Positionen für 3x3 Monitor an (z.B. 13x11, gap=4)
local boxW, boxH = 13, 11
local gap = 4
local totalWidth = boxW * 3 + gap * 2
local xStart = math.floor((w - totalWidth) / 2) + 1
local yStart = math.floor((h - boxH) / 2) + 1

-- Create slot display boxes - make them transparent (no background/border) for direct NFP rendering
local slotBox1 = main:addFrame()
    :setPosition(xStart, yStart)
    :setSize(boxW, boxH)

local slotBox2 = main:addFrame()
    :setPosition(xStart + boxW + gap, yStart)
    :setSize(boxW, boxH)

local slotBox3 = main:addFrame()
    :setPosition(xStart + (boxW + gap) * 2, yStart)
    :setSize(boxW, boxH)

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

-- Funktion: NFP laden und als "Pixelgrafik" in SlotBox anzeigen (angepasst für 3x3 Monitor, nutzt gesamten Screen)
local function setSlotSymbol(slotBox, slotLabel, symbolName)
    local nfpFile = symbolName .. ".nfp"
    local dir = shell and shell.dir and shell.dir() or "."
    local files = fs.list(dir)
    local foundFile = nil
    for _, f in ipairs(files) do
        if f:lower() == nfpFile:lower() then
            foundFile = fs.combine(dir, f)
            break
        end
    end
    slotBox:removeChildren()
    if not foundFile or not fs.exists(foundFile) then
        slotBox:addLabel()
            :setText("???")
            :setForeground(colors.red)
            :setBackground(colors.white)
            :setPosition(4, 4)
        return
    end

    local nfpLines = {}
    local file = fs.open(foundFile, "r")
    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(nfpLines, line)
    end
    file.close()

    -- Für 3x3 Monitor: SlotBox-Größe proportional größer wählen
    local boxW, boxH = slotBox:getSize()
    -- Wenn der Monitor sehr groß ist, nutze die tatsächliche SlotBox-Größe
    -- (z.B. 13x11 bei 3x3 Monitoren, siehe show_cherry_bimg)
    local fw = #(nfpLines[1] or "")
    local fh = #nfpLines
    if fw == 0 or fh == 0 then return end

    local function charToColor(c)
        local n = tonumber(c, 16)
        if n == nil then return colors.black end
        return 2 ^ n
    end

    local win = monitor
    local absX, absY = slotBox:getPosition()
    for fy = 1, fh do
        local line = nfpLines[fy]
        local yStart = math.floor((fy - 1) * boxH / fh) + 1
        local yEnd = math.floor(fy * boxH / fh)
        for fx = 1, fw do
            local c = line:sub(fx, fx)
            local col = charToColor(c)
            local xStart = math.floor((fx - 1) * boxW / fw) + 1
            local xEnd = math.floor(fx * boxW / fw)
            for y = yStart, yEnd do
                for x = xStart, xEnd do
                    win.setCursorPos(absX + x - 1, absY + y - 1)
                    win.setBackgroundColor(col)
                    win.write(" ")
                end
            end
        end
    end
end

-- Initiale Symbole setzen
setSlotSymbol(slotBox1, slotLabel1, slot1)
setSlotSymbol(slotBox2, slotLabel2, slot2)
setSlotSymbol(slotBox3, slotLabel3, slot3)

-- Passe Spin-Button an (zentriert unter den Slotboxen, größer)
local buttonW, buttonH = math.max(18, math.floor(w * 0.5)), 3
local buttonX = math.floor((w - buttonW) / 2) + 1
local buttonY = yStart + boxH + 2

-- Create spin button
local spinButton = main:addButton()
    :setText("SPIN!")
    :setPosition(buttonX, buttonY)
    :setSize(buttonW, buttonH)
    :setBackground(colors.green)
    :setForeground(colors.white)

-- Passe Ergebnis-Anzeige an (zentriert unter dem Button)
local resultLabel = main:addLabel()
    :setText("")
    :setPosition(math.floor((w - 24) / 2) + 1, buttonY + buttonH + 1)
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

    local function animate()
        for i = 1, 15 do
            if i <= 10 then
                slot1 = symbols[math.random(1, #symbols)]
                setSlotSymbol(slotBox1, slotLabel1, slot1)
            end
            if i <= 12 then
                slot2 = symbols[math.random(1, #symbols)]
                setSlotSymbol(slotBox2, slotLabel2, slot2)
            end
            slot3 = symbols[math.random(1, #symbols)]
            setSlotSymbol(slotBox3, slotLabel3, slot3)
            if i == 10 then
                slotBox1:setBackground(colors.lightGray)
            elseif i == 12 then
                slotBox2:setBackground(colors.lightGray)
            end
            if i <= 5 then
                os.sleep(0.1)
            elseif i <= 10 then
                os.sleep(0.2)
            else
                os.sleep(0.3)
            end
        end
        isSpinning = false
        checkWin()
    end

    local animationThread = main:addThread()
    animationThread:start(animate)
end

-- Spin button click event
spinButton:onClick(function()
    spin()
end)



-- Start the program
basalt.autoUpdate()
