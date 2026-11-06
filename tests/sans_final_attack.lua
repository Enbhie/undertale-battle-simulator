local frame = 0
local last_phase = -1
local beam_start = 0
local last_image = -1
local finished = false
local box_ready = 0
local sampled = {}
local mem = emu.memType.nesMemory

local function capture(name)
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
        emu.write(0x64C8, 22, mem)
        emu.write(0x69E, 2, mem)
    end
    if frame > 340 then
        emu.write(0xC5, 20, mem)
        if emu.read(0x64CE, mem) == 1 then emu.write(0xBA, 132, mem) end
    end
    local phase = emu.read(0x64CE, mem)
    local state = emu.read(0xDC, mem)
    if frame > 340 and phase ~= last_phase then
        print("PHASE", frame, phase, state, emu.read(0xAA, mem))
        last_phase = phase
        if phase == 4 then beam_start = frame end
        if phase == 5 then print("BEAM_DURATION", frame - beam_start) end
    end
    if phase >= 1 and phase <= 3 and state == 2 and
       emu.read(0xDD, mem) == 90 and not sampled[phase] then
        sampled[phase] = true
        local falling, left = 0, 0
        for i = 0, 31 do
            local kind = emu.read(0x6400 + i, mem)
            if kind == 5 then falling = falling + 1 end
            if kind == 6 then left = left + 1 end
        end
        print("BONES", phase, falling, left)
    end
    if phase == 4 then
        -- Keep the player outside the box while inspecting every collision rectangle.
        emu.write(0xC3, 4, mem)
        emu.write(0xBA, 0, mem)
        emu.write(0xBC, 0, mem)
        local elapsed = frame - beam_start
        if elapsed >= 7 and elapsed < 480 and elapsed % 9 == 7 and elapsed ~= last_image then
            last_image = elapsed
            capture(tostring(elapsed))
            local rects = {}
            for i = 0, 31 do
                if emu.read(0x6400 + i, mem) == 7 then
                    table.insert(rects, string.format("%d,%d,%d,%d",
                        emu.read(0x6420 + i, mem), emu.read(0x6440 + i, mem),
                        emu.read(0x6460 + i, mem), emu.read(0x6480 + i, mem)))
                end
            end
            print("HITBOXES", elapsed, table.concat(rects, ";"))
        end
    end
    if not finished and box_ready == 0 and phase == 5 and state == 0 and
       emu.read(0xBF, mem) == 8 and emu.read(0xC1, mem) == 246 and
       emu.read(0xB8, mem) == 0 and frame > beam_start + 500 then
        box_ready = frame + 15
    end
    if not finished and box_ready > 0 and frame >= box_ready then
        finished = true
        capture("dialogue")
        print("DIALOGUE_MUSIC", emu.read(0xAA, mem))
        print("DONE", frame)
        emu.write(0x69E, 2, mem)
    elseif finished and phase == 0 and state == 2 then
        print("NO_REPLAY", frame, emu.read(0xAA, mem))
        emu.stop()
    end
    if frame == 2500 then print("TIMEOUT"); emu.stop() end
end, emu.eventType.endFrame)
