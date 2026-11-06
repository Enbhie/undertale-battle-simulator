local frame = 0
local captured = {}
local mem = emu.memType.nesMemory

local function capture(name)
    if captured[name] then return end
    captured[name] = true
    local png = emu.takeScreenshot()
    local bytes = {}
    for i = 1, #png do bytes[i] = string.format("%02x", png:byte(i)) end
    print("IMAGE", name, table.concat(bytes))
end

emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frame = frame + 1
    if frame == 340 then
        emu.write(0xE0, 1, mem)
        emu.write(0x69E, 2, mem)
    end
    if frame > 340 then
        emu.write(0xC5, 20, mem)
        local time = emu.read(0xDD, mem)
        if time == 30 then capture("ring") end
        if time == 80 then capture("cross") end
        if time == 106 then capture("cleared") end
    end
    if frame == 650 then
        capture("expanded")
        emu.stop()
    end
end, emu.eventType.endFrame)
