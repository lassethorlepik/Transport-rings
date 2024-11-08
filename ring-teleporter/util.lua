
local function get_relative_position(entity_a, entity_b)
    -- Validate that both entities are provided
    if not entity_a or not entity_b then
        return nil
    end
    if not entity_a.valid or not entity_b.valid then
        return nil
    end
    local pos_a = entity_a.position
    local pos_b = entity_b.position
    -- Calculate relative coordinates
    local relative_x = pos_a.x - pos_b.x
    local relative_y = pos_a.y - pos_b.y
    -- Return the relative position as a table
    return {x = relative_x, y = relative_y}
end

local function can_vanilla_teleport(entity)
    if entity.type == "character" then
        return true
    elseif entity.type == "car" then
        return true
    elseif entity.type == "spider-vehicle" then
        return true
    end
    return false
end

local function play_random_sound(entity, sounds)
    local random_index = math.random(#sounds)
    local selected_sound = sounds[random_index]
    if entity and entity.valid then
        entity.surface.play_sound{
            path = selected_sound,
            position = entity.position
        }
    end
end

local function schedule_after(delay_ticks, func)
    if delay_ticks <= 0 then
        game.print("Invalid function scheduling request with " .. tostring(delay_ticks) .. " ticks for function " .. tostring(func))
        return
    end
    -- Calculate the target tick when the function should be executed
    local target_tick = game.tick + delay_ticks
    -- Insert the scheduled function into the table
    table.insert(storage.ring_teleporter_scheduled_functions, {tick = target_tick, func = func})
end

local function add_positions(pos1, pos2)
    return {
        x = pos1.x + pos2.x,
        y = pos1.y + pos2.y
    }
end