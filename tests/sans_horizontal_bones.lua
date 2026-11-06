local frame = 0
local stage = 0
local active = false
local previous = {}
local moves = {left = 0, right = 0}
local distance = {left = 0, right = 0}
local damage = {left = false, right = false}
local pending = nil
local errors = 0
local stage_two_frame = 0
local stopped = false
local background_bones = 0
local removed = {left = 0, right = 0}
local mem = emu.memType.nesMemory

local function read(address)
    return emu.read(address, mem)
end

emu.addEventCallback(function()
    local input = {}
    if frame >= 60 and frame <= 75 then input.select = true end
    emu.setInput(input, 0)
end, emu.eventType.inputPolled)

emu.addEventCallback(function()
    if stopped then return end
    frame = frame + 1
    if frame == 340 then
        emu.write(0xE0, 3, mem)
        emu.write(0x69E, 2, mem)
        stage = 1
    end
    if stage == 0 then return end

    if pending then
        if read(0xC5) ~= 19 then errors = errors + 1 end
        damage[pending] = true
        pending = nil
    end
    emu.write(0xC5, 20, mem)
    emu.write(0xBA, 132, mem)
    emu.write(0xBC, 156, mem)

    local phase, state = read(0x64CE), read(0xDC)
    if stage == 2 and not active and frame == stage_two_frame + 60 then
        emu.write(0x69E, 2, mem)
    end
    if state == 2 and ((stage == 1 and phase == 0) or (stage == 2 and phase == 1)) then
        active = true
        local current = {}
        for i = 0, 31 do
            if read(0x6400 + i) == 5 then
                local x, y = read(0x6420 + i), read(0x6440 + i)
                local side = x == 0x42 and "left" or x == 0x86 and "right" or nil
                if side then
                    local anim = read(0x64A0 + i)
                    if anim ~= 0 or read(0x6480 + i) ~= y + 6 then
                        errors = errors + 1
                    end
                    background_bones = background_bones + 1
                    if previous[i] and previous[i].side == side then
                        local delta = (y - previous[i].y) * (side == "left" and 1 or -1)
                        if delta ~= 0 and delta ~= 2 then errors = errors + 1 end
                        moves[side] = moves[side] + 1
                        distance[side] = distance[side] + delta
                    end
                    current[i] = {side = side, y = y}
                    if not pending and not damage[side] and moves[side] >= 3 then
                        emu.write(0xBA, x + 5, mem)
                        emu.write(0xBC, y + 3, mem)
                        pending = side
                    end
                end
            end
        end
        for i, old in pairs(previous) do
            if not current[i] and
               ((old.side == "left" and old.y >= 182) or
                (old.side == "right" and old.y <= 130)) then
                removed[old.side] = removed[old.side] + 1
            end
        end
        previous = current
    elseif active then
        print("HORIZONTAL", stage, moves.left, moves.right,
              damage.left and 1 or 0, damage.right and 1 or 0, errors,
              background_bones, removed.left, removed.right, distance.left, distance.right)
        if stage == 2 then
            stopped = true
            emu.stop()
            return
        end
        stage, active, previous = 2, false, {}
        stage_two_frame = frame
        moves, damage, errors = {left = 0, right = 0}, {left = false, right = false}, 0
        distance = {left = 0, right = 0}
        background_bones, removed = 0, {left = 0, right = 0}
        emu.write(0x64C8, 22, mem)
    end
    if frame >= 1600 then
        print("TIMEOUT", stage, phase, state, read(0x69E), read(0x64C8), read(0xDC + 4))
        stopped = true
        emu.stop()
    end
end, emu.eventType.endFrame)
