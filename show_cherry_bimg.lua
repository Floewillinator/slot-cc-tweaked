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

-- Draw the NFP on a monitor, scaling to a slot box size (angepasst für 3x3 Monitor wie im Slot-Skript)
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

-- Draw on all found monitors, 3 slot boxes nebeneinander (wie im Slot-Skript, aber für 3x3 Monitor)
for i, mon in ipairs(monitors) do
    mon.setTextScale(0.5)
    mon.setBackgroundColor(colors.black)
    mon.clear()
    local w, h = mon.getSize()
    -- Ziel: Slotboxen proportional wie im Original (10x8), aber für 3x3 Monitor (Breite ca. 48, Höhe ca. 27)
    -- 3 Boxen + 2 Gaps, Boxen ca. 13 breit, 11 hoch, Gap 4
    local boxW, boxH = 13, 11
    local gap = 4
    local totalWidth = boxW * 3 + gap * 2
    local xStart = math.floor((w - totalWidth) / 2) + 1
    local yStart = math.floor((h - boxH) / 2) + 1
    drawNfpSlotBox(mon, xStart, yStart, boxW, boxH)
    drawNfpSlotBox(mon, xStart + boxW + gap, yStart, boxW, boxH)
    drawNfpSlotBox(mon, xStart + (boxW + gap) * 2, yStart, boxW, boxH)
end

print(actualNfpFile .. " wurde als Slot-Symbol (3x, skaliert für 3x3 Monitor) auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")

