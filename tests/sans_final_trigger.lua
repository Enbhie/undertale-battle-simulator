local frame = 0
local mem = emu.memType.nesMemory
emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    if frame > 240 and frame < 330 and frame % 30 < 3 then input.a = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)
emu.addEventCallback(function()
    frame = frame + 1
    if frame == 260 then emu.write(0x64C8, 21, mem) end
    if emu.read(0x64CE, mem) == 1 then
        print("TRIGGER", emu.read(0x64C8, mem), emu.read(0x9E, mem))
        emu.stop()
    end
    if frame == 900 then print("TIMEOUT"); emu.stop() end
end, emu.eventType.endFrame)
