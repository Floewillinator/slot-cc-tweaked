-- Slot machine for ComputerCraft (ohne Basalt, Slotbilder wie in show_cherry_bimg.lua)

local monitor = peripheral.find("monitor")
if not monitor then error("No monitor found!") end

monitor.setTextScale(0.5)
local w, h = monitor.getSize()

-- Slot symbols (NFP-Dateinamen)
local symbols = {"cherry", "lemon", "bell", "pineapple", "seven"}
local slot1, slot2, slot3 = "cherry", "lemon", "bell"
local isSpinning = false

-- Slotbox-Layout (weiter nach unten schieben, Platz für Logo und Auszahlungstabelle oben)
local boxW, boxH = 13, 11
local gap = 4
local totalWidth = boxW * 3 + gap * 2

-- Logo (ASCII-Art, 7 Zeilen, "AMK" in gelb)
local logoLines = {
    "   #    #     # #    # ",
    "  # #   ##   ## #   #  ",
    " #   #  # # # # #  #   ",
    "#     # #  #  # ###    ",
    "####### #     # #  #   ",
    "#     # #     # #   #  ",
    "#     # #     # #    # "
}
local logoHeight = #logoLines
local auszahlungY = logoHeight + 2 -- Startzeile für Auszahlungstabelle (nach Logo)
local auszahlungHeight = 5 -- Zeilen für Auszahlungstabelle
local yStart = auszahlungY + auszahlungHeight + 2 -- +2 für Abstand

-- Korrigiere xStart für echte horizontale Zentrierung
local xStart = math.floor((w - totalWidth) / 2) + 1

-- Button-Layout (weiter nach unten)
local buttonW, buttonH = math.max(18, math.floor(w * 0.5)), 3
local buttonX = math.floor((w - buttonW) / 2) + 1
local buttonY = yStart + boxH + 2
local einsatzLabelY = buttonY + buttonH + 1
local einsatzButtonW, einsatzButtonH = 7, 3
local einsatzButtonX = math.floor((w - einsatzButtonW) / 2) + 1
local einsatzButtonY = einsatzLabelY + 2
local resultY = einsatzButtonY + einsatzButtonH + 1

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
    -- Sicherstellen, dass alle Parameter gesetzt sind
    x0 = tonumber(x0) or 1
    y0 = tonumber(y0) or 1
    boxW = tonumber(boxW) or 1
    boxH = tonumber(boxH) or 1

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

-- Symbolwerte-Tabelle (Multiplikator für Gewinn, kann mit variablem Einsatz umgehen)
local symbolValues = {
    cherry = 2,      -- 2x Einsatz
    lemon = 3,       -- 3x Einsatz
    bell = 5,        -- 5x Einsatz
    pineapple = 10,  -- 10x Einsatz
    seven = 20       -- 20x Einsatz
}

-- Auszahlungstabelle als Text generieren
local function drawAuszahlungstabelle()
    local tabelle = {
        {"Symbol", "Multiplikator"},
        {"Kirsche", "x" .. symbolValues.cherry},
        {"Zitrone", "x" .. symbolValues.lemon},
        {"Glocke", "x" .. symbolValues.bell},
        {"Ananas", "x" .. symbolValues.pineapple},
        {"Sieben", "x" .. symbolValues.seven}
    }
    local startX = math.floor((w - 22) / 2) + 1
    for i, row in ipairs(tabelle) do
        monitor.setCursorPos(startX, auszahlungY + i - 1)
        monitor.setTextColor(i == 1 and colors.yellow or colors.white)
        monitor.setBackgroundColor(colors.black)
        monitor.write(string.format("%-12s %8s", row[1], row[2]))
    end
end

-- Draw logo at the top (ASCII "AMK" in gelb)
local function drawLogo()
    local nameText = "AMK Slot"
    local nameX = math.floor((w - #nameText) / 2) + 1
    monitor.setCursorPos(nameX, 1)
    monitor.setTextColor(colors.yellow)
    monitor.setBackgroundColor(colors.black)
    monitor.write(nameText)
    for i, line in ipairs(logoLines) do
        local x = math.floor((w - #line) / 2) + 1
        monitor.setCursorPos(x, 1 + i)
        monitor.setTextColor(colors.yellow)
        monitor.setBackgroundColor(colors.black)
        monitor.write(line)
    end
end

-- Hilfsfunktion: Zählt Items in einer Chest (fix: nutze .getItemDetail statt .list für modded Chests)
local function countItemInChest(chest, itemName)
    if not chest then return 0 end
    local total = 0
    for slot = 1, chest.size() do
        local item = chest.getItemDetail(slot)
        if item and item.name == itemName then
            total = total + item.count
        end
    end
    return total
end

-- Draw slot UI (symbols, button, einsatz, result, auszahlungstabelle)
local function drawUI(resultText, resultColor)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    -- Logo oben
    drawLogo()
    -- Auszahlungstabelle darunter
    drawAuszahlungstabelle()
    -- Slotboxes (jetzt mit korrekt berechnetem xStart)
    local safe_xStart = tonumber(xStart) or 1
    local safe_yStart = tonumber(yStart) or 1
    local safe_boxW = tonumber(boxW) or 1
    local safe_boxH = tonumber(boxH) or 1
    local safe_gap = tonumber(gap) or 0
    drawNfpSymbol(slot1, safe_xStart, safe_yStart, safe_boxW, safe_boxH)
    drawNfpSymbol(slot2, safe_xStart + safe_boxW + safe_gap, safe_yStart, safe_boxW, safe_boxH)
    drawNfpSymbol(slot3, safe_xStart + (safe_boxW + safe_gap) * 2, safe_yStart, safe_boxW, safe_boxH)
    -- Spin Button
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
    -- Einsatz-Anzeige + Bestand
    local einsatzVal = tonumber(_G.einsatz) or 0
    local bestand = countItemInChest(CHEST_EINSATZ, EINSATZ_ITEM)
    local einsatzText = "Einsatz: " .. tostring(einsatzVal) .. "   Bestand: " .. tostring(bestand)
    monitor.setCursorPos(math.floor((w - #einsatzText) / 2) + 1, einsatzLabelY)
    monitor.setTextColor(colors.cyan)
    monitor.setBackgroundColor(colors.black)
    monitor.write(einsatzText)
    -- Einsatz-Button
    for by = 0, einsatzButtonH - 1 do
        monitor.setCursorPos(einsatzButtonX, einsatzButtonY + by)
        monitor.setBackgroundColor(colors.blue)
        monitor.setTextColor(colors.white)
        monitor.write(string.rep(" ", einsatzButtonW))
    end
    monitor.setCursorPos(einsatzButtonX + 1, einsatzButtonY + math.floor(einsatzButtonH / 2))
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.blue)
    monitor.write("EINSATZ")
    -- Result
    if resultText then
        monitor.setCursorPos(math.floor((w - #resultText) / 2) + 1, resultY)
        monitor.setTextColor(resultColor or colors.yellow)
        monitor.setBackgroundColor(colors.black)
        monitor.write(resultText)
    end
end

-- Check if (mx, my) is inside the spin button
local function isInButton(mx, my)
    return mx >= buttonX and mx < buttonX + buttonW and my >= buttonY and my < buttonY + buttonH
end

-- Check if (mx, my) is inside the einsatz button
local function isInEinsatzButton(mx, my)
    return mx >= einsatzButtonX and mx < einsatzButtonX + einsatzButtonW and my >= einsatzButtonY and my < einsatzButtonY + einsatzButtonH
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

-- Einsatz-Konfiguration
local EINSATZ_ITEM = "minecraft:emerald_block"
local EINSATZ_MIN = 1
local EINSATZ_MAX = 20
_G.einsatz = 5 -- global, damit drawUI immer den aktuellen Wert sieht

local CHEST_EINSATZ = peripheral.wrap("front")
local CHEST_AUSZAHLUNG = peripheral.wrap("back")
local CHEST_AUSGABE = peripheral.wrap("left")





-- Hilfsfunktion: Entnimmt eine bestimmte Anzahl Items aus einer Chest
local function takeItemFromChest(chest, itemName, count)
    if not chest then return 0 end
    local left = count
    for slot, item in pairs(chest.list()) do
        if item.name == itemName then
            local toMove = math.min(item.count, left)
            local moved = chest.pushItems(peripheral.getName(CHEST_AUSZAHLUNG), slot, toMove)
            left = left - moved
            if left <= 0 then return count end
        end
    end
    return count - left
end

-- Überprüft ob genug Einsatz vorhanden ist
local function einsatzMoeglich()
    return CHEST_EINSATZ and CHEST_AUSZAHLUNG and countItemInChest(CHEST_EINSATZ, EINSATZ_ITEM) >= _G.einsatz
end

-- Zieht Einsatz ab und verschiebt ihn in die Auszahlungskiste
local function einsatzEinziehen()
    if not einsatzMoeglich() then return false end
    local moved = takeItemFromChest(CHEST_EINSATZ, EINSATZ_ITEM, _G.einsatz)
    return moved == _G.einsatz
end

-- Gewinn auszahlen (verschiebt Gewinnmenge in CHEST_AUSGABE)
local function gewinnAuszahlen(symbol, einsatzWert)
    if not CHEST_AUSGABE then return end
    local multi = symbolValues[symbol] or 0
    local gewinn = einsatzWert * multi
    local left = gewinn
    for slot, item in pairs(CHEST_AUSZAHLUNG.list()) do
        if item.name == EINSATZ_ITEM then
            local toMove = math.min(item.count, left)
            local moved = CHEST_AUSZAHLUNG.pushItems(peripheral.getName(CHEST_AUSGABE), slot, toMove)
            left = left - moved
            if left <= 0 then break end
        end
    end
end

-- Animation/Spin (angepasst: Gewinn auszahlen bei Win)
local function spin()
    if isSpinning then return end
    if not einsatzEinziehen() then
        drawUI("Nicht genug Einsatz!", colors.red)
        sleep(1)
        drawUI()
        return
    end
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
        gewinnAuszahlen(slot1, _G.einsatz)
    else
        playLoseSound()
    end
end

-- Main event loop (mit Einsatz-Button)
drawUI()
while true do
    local e, side, x, y = os.pullEvent()
    if e == "monitor_touch" then
        if isInButton(x, y) and not isSpinning then
            spin()
        elseif isInEinsatzButton(x, y) and not isSpinning then
            _G.einsatz = tonumber(_G.einsatz) or 1
            _G.einsatz = _G.einsatz + 1
            if _G.einsatz > EINSATZ_MAX then _G.einsatz = EINSATZ_MIN end
            drawUI()
        end
    elseif e == "mouse_click" then
        if isInButton(x, y) and not isSpinning then
            spin()
        elseif isInEinsatzButton(x, y) and not isSpinning then
            _G.einsatz = tonumber(_G.einsatz) or 1
            _G.einsatz = _G.einsatz + 1
            if _G.einsatz > EINSATZ_MAX then _G.einsatz = EINSATZ_MIN end
            drawUI()
        end
    end
end

