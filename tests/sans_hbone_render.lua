local frame, stage, active, stage_two_frame = 0, 0, false, 0
local captured_dialogue = false
local mem = emu.memType.nesMemory
local function read(address) return emu.read(address, mem) end

emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    frame = frame + 1
    if frame == 340 then
        emu.write(0xE0, 3, mem)
        emu.write(0x69E, 2, mem)
        stage = 1
    end
    if stage == 0 then return end
    emu.write(0xC5, 20, mem)
    emu.write(0xBA, 132, mem)
    emu.write(0xBC, 156, mem)
    if stage == 2 and not active and frame == stage_two_frame + 60 then
        emu.write(0x69E, 2, mem)
    end
    if stage == 2 and not captured_dialogue and frame == stage_two_frame + 45 then
        captured_dialogue = true
        local png, bytes = emu.takeScreenshot(), {}
        for i = 1, #png do bytes[i] = string.format("%02x", png:byte(i)) end
        print("DIALOGUE", table.concat(bytes))
    end
    local phase, state, time = read(0x64CE), read(0xDC), read(0xDD)
    if state == 2 and ((stage == 1 and phase == 0) or (stage == 2 and phase == 1)) then
        active = true
        if (time >= 5 and time <= 35) or (time >= 125 and time <= 209) then
            local left, right = -1, -1
            for i = 0, 31 do
                if read(0x6400 + i) == 5 then
                    local x, y = read(0x6420 + i), read(0x6440 + i)
                    if x == 0x42 then left = y end
                    if x == 0x86 then right = y end
                end
            end
            local png, bytes = emu.takeScreenshot(), {}
            for i = 1, #png do bytes[i] = string.format("%02x", png:byte(i)) end
            print("SNAP", stage, time, left, right, table.concat(bytes))
        end
    elseif active then
        if stage == 2 then
            print("DONE")
            emu.stop()
            return
        end
        stage, active, stage_two_frame = 2, false, frame
        emu.write(0x64C8, 22, mem)
    end
    if frame >= 1600 then print("TIMEOUT"); emu.stop() end
end, emu.eventType.endFrame)
