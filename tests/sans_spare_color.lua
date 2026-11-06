local frame, stage, stage_frame = 0, 0, 0
local recorded_final = false
local mem = emu.memType.nesMemory
local function read(address) return emu.read(address, mem) end
local function capture(label)
    local png, bytes = emu.takeScreenshot(), {}
    for i = 1, #png do bytes[i] = string.format("%02x", png:byte(i)) end
    print("SPARE_IMAGE", label, table.concat(bytes))
    print("SPARE_STATE", label, read(0x698), read(0x6d8))
end

emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    local elapsed = frame - stage_frame
    if (stage == 1 or stage == 4 or stage == 8) and elapsed == 5 then input.a = true end
    if (stage == 2 or stage == 5) and elapsed == 20 then input.b = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frame = frame + 1
    if frame > 240 then emu.write(0xC5, 20, mem) end
    if stage == 0 and frame == 340 then
        emu.write(0x6B5, 3, mem)
        stage, stage_frame = 1, frame
    elseif stage == 1 and frame - stage_frame == 15 then
        capture("initial")
        stage, stage_frame = 2, frame
    elseif stage == 2 and frame - stage_frame == 35 then
        emu.write(0x64C8, 10, mem)
        emu.write(0x69E, 2, mem)
        stage = 3
    elseif stage == 3 and read(0x698) % 32 >= 16 and
           read(0xDC) == 0 and read(0xB8) == 0 and
           read(0xBF) == 8 and read(0xC1) == 246 and read(0xC3) == 0 then
        emu.write(0x6B5, 3, mem)
        stage, stage_frame = 4, frame
    elseif stage == 4 and frame - stage_frame == 15 then
        capture("sweat")
        stage, stage_frame = 5, frame
    elseif stage == 5 and frame - stage_frame == 35 then
        emu.write(0x64C8, 22, mem)
        emu.write(0x69E, 2, mem)
        stage = 6
    elseif stage == 6 then
        if read(0x64CE) >= 1 and read(0x64CE) <= 4 then
            if not recorded_final then
                recorded_final = true
                print("FINAL_IN_PROGRESS", read(0x698))
            end
            emu.write(0xC3, 4, mem)
            emu.write(0xBA, 0, mem)
            emu.write(0xBC, 0, mem)
        end
        if read(0x64CE) == 5 and read(0xDC) == 0 and read(0xB8) == 0 then
            stage, stage_frame = 7, frame
        end
    elseif stage == 7 and frame - stage_frame == 30 then
        emu.write(0x6B5, 3, mem)
        stage, stage_frame = 8, frame
    elseif stage == 8 and frame - stage_frame == 15 then
        capture("final")
        print("DONE")
        emu.stop()
        return
    end
    if frame >= 3000 then
        print("TIMEOUT", stage, read(0xDC), read(0x64CE), read(0xC3))
        emu.stop()
    end
end, emu.eventType.endFrame)
