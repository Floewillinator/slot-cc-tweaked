-- Zeigt cherry.bimg auf bis zu 4 Monitoren an, nutzt den gesamten Monitorbereich (kein Basalt)

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

-- Draw the frame on a monitor, scaling to fill the monitor
local function drawFrameScaled(monitor)
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    local mw, mh = monitor.getSize()
    local fw = #(text[1] or "")
    local fh = #text

    -- Avoid division by zero
    if fw == 0 or fh == 0 then return end

    -- Calculate scaling factors
    local scaleX = mw / fw
    local scaleY = mh / fh

    for y = 1, mh do
        -- Map monitor y to frame y
        local fy = math.floor((y - 1) / scaleY) + 1
        local t = text[fy] or ""
        local fgLine = fg[fy] or ""
        local bgLine = bg[fy] or ""
        for x = 1, mw do
            local fx = math.floor((x - 1) / scaleX) + 1
            local ch = t:sub(fx, fx)
            local fgCol = charToColor(fgLine:sub(fx, fx))
            local bgCol = charToColor(bgLine:sub(fx, fx))
            monitor.setCursorPos(x, y)
            -- Only draw the character if it is not a space, otherwise draw a space with bg color
            if ch ~= "" and ch ~= " " and ch ~= "0" then
                monitor.setTextColor(fgCol)
                monitor.setBackgroundColor(bgCol)
                monitor.write(ch)
            else
                monitor.setTextColor(bgCol)
                monitor.setBackgroundColor(bgCol)
                monitor.write(" ")
            end
        end
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
