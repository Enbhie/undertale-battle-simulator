local frame = 0
local mem = emu.memType.nesMemory
local previous_soul = -1
local first_strike = {}
local saw_slash = false
local saw_miss = false

emu.addEventCallback(function()
    local input = {}
    if frame > 240 and frame % 30 < 3 then input.a = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frame = frame + 1
    local fight = emu.read(0x695, mem)
    local soul = emu.read(0xC3, mem)

    -- Shorten the first two battles without bypassing their winning strikes.
    if fight == 2 or fight == 3 then
        emu.write(0x4C2, 1, mem)
        emu.write(0x4C3, 0, mem)
        emu.write(0xC6, 40, mem)
    end
    emu.write(0xC5, 20, mem)

    if soul == 3 and previous_soul ~= 3 and not first_strike[fight] then
        first_strike[fight] = true
        print("FIRST_STRIKE", fight, emu.read(0x9D, mem), emu.read(0x9C, mem))
    end
    previous_soul = soul

    if fight == 4 and soul == 3 and emu.read(0x9D, mem) == 1 then
        local timer = emu.read(0x9C, mem)
        if timer > 0 and timer < 54 then saw_slash = true end
        if timer >= 54 and emu.read(0x9E, mem) == 0 then saw_miss = true end
    end
    if fight == 4 and soul == 1 and emu.read(0x64C8, mem) == 1 then
        print("SANS_TURN", saw_slash and 1 or 0, saw_miss and 1 or 0)
        emu.stop()
        return
    end
    if frame >= 6000 then
        print("TIMEOUT")
        emu.stop()
    end
end, emu.eventType.endFrame)
