-- Zeigt cherry.nfp auf bis zu 4 Monitoren an, nutzt den gesamten Monitorbereich (kein Basalt)

local nfpFile = "cherry.nfp"

-- Find up to 4 monitors
local monitors = {}
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        table.insert(monitors, peripheral.wrap(name))
        if #monitors >= 4 then break end
    end
end

if #monitors == 0 then
    print("Keine Monitore gefunden!")
    return
end

-- Suche nach cherry.nfp im aktuellen Arbeitsverzeichnis (shell.dir())
local function findNfpFile()
    local dir = shell and shell.dir and shell.dir() or "."
    local files = fs.list(dir)
    for _, f in ipairs(files) do
        if f:lower() == "cherry.nfp" then
            return fs.combine(dir, f)
        end
    end
    return nil
end

local actualNfpFile = findNfpFile()
if not actualNfpFile or not fs.exists(actualNfpFile) then
    print("Datei cherry.nfp nicht gefunden! (Groß-/Kleinschreibung prüfen)")
    print("Gefundene Dateien im Ordner:")
    local dir = shell and shell.dir and shell.dir() or "."
    for _, f in ipairs(fs.list(dir)) do print(" - " .. f) end
    return
end

-- Load NFP file (each line is a row of color codes)
local nfpLines = {}
local file = fs.open(actualNfpFile, "r")
while true do
    local line = file.readLine()
    if not line then break end
    table.insert(nfpLines, line)
end
file.close()

if #nfpLines == 0 then
    print("cherry.nfp ist leer!")
    return
end

-- Helper: Convert char to color (0-9,a-f)
local function charToColor(c)
    local n = tonumber(c, 16)
    if n == nil then return colors.black end
    return 2 ^ n
end

-- Draw the NFP on a monitor, scaling to a slot box size (jetzt 30x24 für 3x3 Monitore)
local function drawNfpSlotBox(monitor, x0, y0, boxW, boxH)
    local fw = #(nfpLines[1] or "")
    local fh = #nfpLines
    if fw == 0 or fh == 0 then return end

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
                    monitor.setCursorPos(x0 + x - 1, y0 + y - 1)
                    monitor.setBackgroundColor(col)
                    monitor.write(" ")
                end
            end
        end
    end
end

-- Draw on all found monitors, 3 slot boxes nebeneinander (wie im Slot-Skript, aber größer)
for i, mon in ipairs(monitors) do
    mon.setTextScale(0.5)
    mon.setBackgroundColor(colors.black)
    mon.clear()
    local w, h = mon.getSize()
    local boxW, boxH = 30, 24 -- 3x3 Monitor: Slotbox 3x so groß
    local gap = 3
    -- Berechne Startpositionen für 3 Slot-Boxen mittig auf dem Monitor
    local totalWidth = boxW * 3 + gap * 2
    local xStart = math.floor((w - totalWidth) / 2) + 1
    local yStart = math.floor((h - boxH) / 2) + 1
    drawNfpSlotBox(mon, xStart, yStart, boxW, boxH)
    drawNfpSlotBox(mon, xStart + boxW + gap, yStart, boxW, boxH)
    drawNfpSlotBox(mon, xStart + (boxW + gap) * 2, yStart, boxW, boxH)
end

print(actualNfpFile .. " wurde als großes Slot-Symbol (3x) auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")

