-- Zeigt cherry.bimg auf bis zu 4 Monitoren an (Basalt nicht benötigt)

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

-- Load BIMG file (as JSON)
if not fs.exists(bimgFile) then
    print("Datei cherry.bimg nicht gefunden!")
    return
end

local file = fs.open(bimgFile, "r")
local content = file.readAll()
file.close()

local ok, bimg = pcall(textutils.unserializeJSON, content)
if not ok or type(bimg) ~= "table" or not bimg.frames or not bimg.frames[1] then
    print("Fehler beim Parsen von cherry.bimg!")
    return
end

local frame = bimg.frames[1]
local text = frame.text or {}
local fg = frame.fg or {}
local bg = frame.bg or {}

-- Helper: Convert char to color
local function charToColor(c)
    local n = tonumber(c)
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
            local fgCol = charToColor(fgLine:sub(x, x))
            local bgCol = charToColor(bgLine:sub(x, x))
            monitor.setCursorPos(x0 + x - 1, y0 + y - 1)
            monitor.setTextColor(fgCol)
            monitor.setBackgroundColor(bgCol)
            monitor.write(ch ~= " " and ch or " ")
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

print("cherry.bimg wurde auf " .. #monitors .. " Monitor(en) angezeigt.")
print("Drücke eine Taste zum Beenden.")
os.pullEvent("key")
