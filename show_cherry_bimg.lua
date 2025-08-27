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

-- Draw the NFP on a monitor, scaling to fill the monitor (Pixel-Block-Skalierung)
local function drawNfpScaled(monitor)
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    local mw, mh = monitor.getSize()
    local fw = #(nfpLines[1] or "")
    local fh = #nfpLines

    if fw == 0 or fh == 0 then return end

    for fy = 1, fh do
        local line = nfpLines[fy]
        local yStart = math.floor((fy - 1) * mh / fh) + 1
        local yEnd = math.floor(fy * mh / fh)
        for fx = 1, fw do
            local c = line:sub(fx, fx)
            local col = charToColor(c)
            local xStart = math.floor((fx - 1) * mw / fw) + 1
            local xEnd = math.floor(fx * mw / fw)
            for y = yStart, yEnd do
                for x = xStart, xEnd do
                    monitor.setCursorPos(x, y)
                    monitor.setBackgroundColor(col)
                    monitor.write(" ")
                end
            end
        end
    end
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
end

-- Draw on all found monitors, scaled to fill
for i, mon in ipairs(monitors) do
    drawNfpScaled(mon)
end

print(actualNfpFile .. " wurde skaliert auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")
    end
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
end

-- Draw on all found monitors, scaled to fill
for i, mon in ipairs(monitors) do
    drawFrameScaled(mon)
end

print(actualBimgFile .. " wurde skaliert auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")
