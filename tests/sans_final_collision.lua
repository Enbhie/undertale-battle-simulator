local frame = 0
local beam_start = 0
local checked = false
local mem = emu.memType.nesMemory

emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frame = frame + 1
    if frame == 340 then
        emu.write(0x64C8, 22, mem)
        emu.write(0x69E, 2, mem)
    end
    local phase = emu.read(0x64CE, mem)
    if frame > 340 and phase ~= 4 then emu.write(0xC5, 20, mem) end
    if phase == 4 then
        if beam_start == 0 then beam_start = frame end
        local elapsed = frame - beam_start
        if elapsed < 6 then
            emu.write(0xBA, 70, mem)
            emu.write(0xBC, 130, mem)
            emu.write(0xC5, 20, mem)
        elseif elapsed == 6 then
            emu.write(0xBA, 120, mem)
            emu.write(0xBC, 156, mem)
        elseif elapsed == 7 and not checked then
            checked = true
            print("BEAM_HP", emu.read(0xC5, mem))
            emu.stop()
        end
    end
    if frame == 2000 then print("TIMEOUT"); emu.stop() end
end, emu.eventType.endFrame)
