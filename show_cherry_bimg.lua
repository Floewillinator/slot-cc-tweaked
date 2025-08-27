-- Zeigt cherry.bimg auf bis zu 4 Monitoren an (sucht im aktuellen Ordner, robustes Parsen)

local bimgFile = "cherry.bimg"

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

-- Suche nach cherry.bimg im aktuellen Arbeitsverzeichnis (shell.dir())
local function findBimgFile()
    local dir = shell and shell.dir and shell.dir() or "."
    local files = fs.list(dir)
    for _, f in ipairs(files) do
        if f:lower() == "cherry.bimg" then
            return fs.combine(dir, f)
        end
    end
    return nil
end

local actualBimgFile = findBimgFile()
if not actualBimgFile or not fs.exists(actualBimgFile) then
    print("Datei cherry.bimg nicht gefunden! (Groß-/Kleinschreibung prüfen)")
    print("Gefundene Dateien im Ordner:")
    local dir = shell and shell.dir and shell.dir() or "."
    for _, f in ipairs(fs.list(dir)) do print(" - " .. f) end
    return
end

-- Load BIMG file (as Lua table, not JSON!)
local file = fs.open(actualBimgFile, "r")
local content = file.readAll()
file.close()

-- Try to parse as Lua table (BIMG-Export aus CC-Tools ist oft kein JSON!)
local ok, bimg = pcall(function() return textutils.unserialize(content) end)
if not ok or type(bimg) ~= "table" or not bimg[1] then
    print("Fehler beim Parsen von " .. actualBimgFile .. "!")
    return
end

local frame = bimg[1]
local text = frame[1] or {}
local fg = frame[2] or {}
local bg = frame[3] or {}

-- Helper: Convert char to color (accepts 0-9, a-f, fallback to black)
local function charToColor(c)
    local n = tonumber(c, 16)
    if n == nil then return colors.black end
    return 2 ^ n
end

-- Draw the frame on a monitor at (x0, y0)
local function drawFrame(monitor, x0, y0)
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    for y = 1, #text do
        local t = text[y] or ""
        local fgLine = fg[y] or ""
        local bgLine = bg[y] or ""
        for x = 1, #t do
            local ch = t:sub(x, x)
            -- If text is only spaces, draw a space with bg color only
            if ch == " " then
                monitor.setCursorPos(x0 + x - 1, y0 + y - 1)
                monitor.setTextColor(colors.white)
                monitor.setBackgroundColor(charToColor(bgLine:sub(x, x)))
                monitor.write(" ")
            else
                monitor.setCursorPos(x0 + x - 1, y0 + y - 1)
                monitor.setTextColor(charToColor(fgLine:sub(x, x)))
                monitor.setBackgroundColor(charToColor(bgLine:sub(x, x)))
                monitor.write(ch)
            end
        end
    end
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.setBackgroundColor(colors.black)
end

-- Draw on all found monitors, centered
for i, mon in ipairs(monitors) do
    local w, h = mon.getSize()
    local fw = #(text[1] or "")
    local fh = #text
    local x0 = math.floor((w - fw) / 2) + 1
    local y0 = math.floor((h - fh) / 2) + 1
    drawFrame(mon, x0, y0)
end

print(actualBimgFile .. " wurde auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")
