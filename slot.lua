-- Slot machine for ComputerCraft (ohne Basalt, Slotbilder wie in show_cherry_bimg.lua)

local monitor = peripheral.find("monitor")
if not monitor then error("No monitor found!") end

monitor.setTextScale(0.5)
local w, h = monitor.getSize()

-- Slot symbols (NFP-Dateinamen)
local symbols = {"cherry", "lemon", "bell", "pineapple", "seven"}
local slot1, slot2, slot3 = "cherry", "lemon", "bell"
local isSpinning = false

-- Slotbox-Layout (wie in show_cherry_bimg.lua)
local boxW, boxH = 13, 11
local gap = 4
local totalWidth = boxW * 3 + gap * 2
local xStart = math.floor((w - totalWidth) / 2) + 1
local yStart = math.floor((h - boxH) / 2) + 1

-- Button-Layout
local buttonW, buttonH = math.max(18, math.floor(w * 0.5)), 3
local buttonX = math.floor((w - buttonW) / 2) + 1
local buttonY = yStart + boxH + 2

-- Result-Label
local resultY = buttonY + buttonH + 1

-- Farbpalette setzen (wichtig für NFP)
local function setMonitorPalette(monitor)
    if monitor and monitor.setPaletteColor then
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
        for k, v in pairs(palette) do monitor.setPaletteColor(k, v) end
    end
end

setMonitorPalette(monitor)

-- Helper: Convert char to color (0-9,a-f)
local function charToColor(c)
    local n = tonumber(c, 16)
    if n == nil then return colors.black end
    return 2 ^ n
end

-- Draw NFP image at (x0, y0) with size (boxW, boxH) (wie in show_cherry_bimg.lua)
local function drawNfpSymbol(symbolName, x0, y0, boxW, boxH)
    local nfpFile = symbolName .. ".nfp"
    -- Suche im aktuellen Arbeitsverzeichnis (wie show_cherry_bimg)
    local dir = shell and shell.dir and shell.dir() or "."
    local files = fs.list(dir)
    local foundFile = nil
    for _, f in ipairs(files) do
        if f:lower() == nfpFile:lower() then
            foundFile = fs.combine(dir, f)
            break
        end
    end
    if not foundFile or not fs.exists(foundFile) then return end
    local nfpLines = {}
    local file = fs.open(foundFile, "r")
    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(nfpLines, line)
    end
    file.close()
    local fw = #(nfpLines[1] or "")
    local fh = #nfpLines
    if fw == 0 or fh == 0 then return end
    for fy = 1, fh do
        local line = nfpLines[fy]
        local yStartPix = math.floor((fy - 1) * boxH / fh) + 1
        local yEndPix = math.floor(fy * boxH / fh)
        for fx = 1, fw do
            local c = line:sub(fx, fx)
            local col = charToColor(c)
            local xStartPix = math.floor((fx - 1) * boxW / fw) + 1
            local xEndPix = math.floor(fx * boxW / fw)
            for y = yStartPix, yEndPix do
                for x = xStartPix, xEndPix do
                    monitor.setCursorPos(x0 + x - 1, y0 + y - 1)
                    monitor.setBackgroundColor(col)
                    monitor.write(" ")
                end
            end
        end
    end
end

-- Draw slot UI (symbols, button, result)
local function drawUI(resultText, resultColor)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    -- Title
    monitor.setCursorPos(math.floor((w - 13) / 2) + 1, 2)
    monitor.setTextColor(colors.yellow)
    monitor.write("SLOT MACHINE")
    -- Slotboxes
    drawNfpSymbol(slot1, xStart, yStart, boxW, boxH)
    drawNfpSymbol(slot2, xStart + boxW + gap, yStart, boxW, boxH)
    drawNfpSymbol(slot3, xStart + (boxW + gap) * 2, yStart, boxW, boxH)
    -- Button
    for by = 0, buttonH - 1 do
        monitor.setCursorPos(buttonX, buttonY + by)
        monitor.setBackgroundColor(colors.green)
        monitor.setTextColor(colors.white)
        monitor.write(string.rep(" ", buttonW))
    end
    monitor.setCursorPos(buttonX + math.floor((buttonW - 5) / 2), buttonY + math.floor(buttonH / 2))
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.green)
    monitor.write("SPIN!")
    -- Result
    if resultText then
        monitor.setCursorPos(math.floor((w - #resultText) / 2) + 1, resultY)
        monitor.setTextColor(resultColor or colors.yellow)
        monitor.setBackgroundColor(colors.black)
        monitor.write(resultText)
    end
end

-- Check if (mx, my) is inside the button
local function isInButton(mx, my)
    return mx >= buttonX and mx < buttonX + buttonW and my >= buttonY and my < buttonY + buttonH
end

-- Check for win
local function checkWin()
    if slot1 == slot2 and slot2 == slot3 then
        return "GEWONNEN! " .. string.upper(slot1) .. " x3", colors.lime
    else
        return "Versuchen Sie es nochmal!", colors.red
    end
end

-- Speaker support
local speaker = peripheral.find("speaker")

local function playSpinSound()
    if speaker then
        -- Play a short note block sound for spinning
        speaker.playSound("block.note_block.hat", 1, 1)
    end
end

local function playWinSound()
    if speaker then
        -- Play a level up sound for win
        speaker.playSound("entity.player.levelup", 1, 1)
    end
end

local function playLoseSound()
    if speaker then
        -- Play a bass note for lose
        speaker.playSound("block.note_block.bass", 1, 0.7)
    end
end

-- Animation/Spin
local function spin()
    if isSpinning then return end
    isSpinning = true
    drawUI("Spinning...", colors.white)
    for i = 1, 15 do
        if i <= 10 then slot1 = symbols[math.random(1, #symbols)] end
        if i <= 12 then slot2 = symbols[math.random(1, #symbols)] end
        slot3 = symbols[math.random(1, #symbols)]
        drawUI("Spinning...", colors.white)
        playSpinSound()
        if i <= 5 then sleep(0.1)
        elseif i <= 10 then sleep(0.2)
        else sleep(0.3) end
    end
    isSpinning = false
    local msg, col = checkWin()
    drawUI(msg, col)
    if col == colors.lime then
        playWinSound()
    else
        playLoseSound()
    end
end

-- Main event loop
drawUI()
while true do
    local e, side, x, y = os.pullEvent()
    if e == "monitor_touch" then
        if isInButton(x, y) and not isSpinning then
            spin()
        end
    elseif e == "mouse_click" then
        if isInButton(x, y) and not isSpinning then
            spin()
        end
    end
end

