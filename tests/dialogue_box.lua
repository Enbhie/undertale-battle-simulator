local frame = 0
local mem = emu.memType.nesMemory
local stage = 0
local stage_frame = 0
local stopped = false
local saw_dialog = false

local function read(address)
    return emu.read(address, mem)
end

local function capture(name)
    local png = emu.takeScreenshot()
    local bytes = {}
    for i = 1, #png do bytes[i] = string.format("%02x", png:byte(i)) end
    print("IMAGE", name, table.concat(bytes))
    print("LAYOUT", name, read(0x480), read(0x481), read(0x48B))
end

emu.addEventCallback(function()
    local input = {}
    local elapsed = frame - stage_frame
    if stage == 0 and frame > 240 and read(0xC3) ~= 0 and frame % 30 < 3 then input.a = true end
    if stage == 1 and ((elapsed >= 10 and elapsed < 13) or (elapsed >= 50 and elapsed < 53)) then input.a = true end
    if stage == 3 and read(0x695) ~= 3 and frame % 30 < 3 then input.a = true end
    if stage == 4 and ((elapsed >= 10 and elapsed < 13) or (elapsed >= 50 and elapsed < 53) or (elapsed >= 90 and elapsed < 93)) then input.a = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    if stopped then return end
    frame = frame + 1
    local fight, soul = read(0x695), read(0xC3)
    if stage == 0 and frame > 240 and fight == 2 and soul == 0 then
        stage = 0.5
    elseif stage == 0.5 and read(0x06) == 0 then
        stage, stage_frame = 1, frame
        emu.write(0x6B5, 2, mem)
        emu.write(0xC5, 5, mem)
    elseif stage == 1 then
        if read(0xA5) ~= 0 or read(0xA6) ~= 0 then saw_dialog = true end
        if saw_dialog and read(0x06) == 0 then
            capture("bandage")
            print("BANDAGE_HP", read(0xC5))
            stage, stage_frame, saw_dialog = 2, frame, false
        end
    elseif stage == 2 and frame - stage_frame > 30 then
        stage = 3
    elseif stage == 3 then
        emu.write(0xC5, 20, mem)
        if fight == 2 then
            emu.write(0x4C2, 1, mem)
            emu.write(0x4C3, 0, mem)
            emu.write(0xC6, 40, mem)
        elseif fight == 3 and soul == 0 and frame > 600 then
            stage = 3.5
        end
    elseif stage == 3.5 and read(0x06) == 0 then
        stage, stage_frame = 4, frame
        emu.write(0x6B5, 1, mem)
    elseif stage == 4 then
        if read(0x69E) == 5 and read(0x06) ~= 0 then saw_dialog = true end
        if saw_dialog and read(0x06) == 0 then
            capture("ember")
            stopped = true
            emu.stop()
            return
        end
    end
    if frame >= 3000 then
        print("TIMEOUT", stage, fight, soul, read(0x69E), read(0x6B5), read(0x48A))
        stopped = true
        emu.stop()
    end
end, emu.eventType.endFrame)
