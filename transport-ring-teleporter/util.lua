local Util = {}

function Util.add_positions(pos1, pos2)
    return {
        x = pos1.x + pos2.x,
        y = pos1.y + pos2.y
    }
end

function Util.distance(pos1, pos2)
    return ((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2)^0.5
end

function Util.get_relative_position(entity_a, entity_b)
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

function Util.can_vanilla_teleport(entity)
    if entity.type == "character" then
        return true
    elseif entity.type == "car" then
        return true
    elseif entity.type == "spider-vehicle" then
        return true
    end
    return false
end

function Util.play_random_sound(entity, sounds)
    local random_index = math.random(#sounds)
    local selected_sound = sounds[random_index]
    if entity and entity.valid then
        entity.surface.play_sound{
            path = selected_sound,
            position = entity.position
        }
    end
end

-- Every scheduled function needs to be listed in function_map for serialization
function Util.schedule_after(delay_ticks, func_id, params)
    if delay_ticks <= 0 then
        Util.Execute(func_id, params)
        return
    end
    -- Calculate the target tick when the function should be executed
    local target_tick = game.tick + delay_ticks
    -- Insert the scheduled function into the table
    table.insert(storage.ring_teleporter_scheduled_functions, {tick = target_tick, func_id = func_id, params = params})
end

-- Execute a function based on id
function Util.Execute(func_id, params)
    log("Execute: " .. func_id .. ", params: " .. tostring(params))
    local func = Function_map[func_id]
    if params == nil then
        func(params)
    else
        func(table.unpack(params))
    end
end

-- Return power as a string
function Util.format_power_string(value, unit_type, space)
    local energy_units = {
        { unit = "PJ", threshold = 1e15, factor = 1e-15 }, -- Petajoule
        { unit = "TJ", threshold = 1e12, factor = 1e-12 }, -- Terajoule
        { unit = "GJ", threshold = 1e9,  factor = 1e-9  }, -- Gigajoule
        { unit = "MJ", threshold = 1e6,  factor = 1e-6  }, -- Megajoule
        { unit = "kJ", threshold = 1e3,  factor = 1e-3  }, -- Kilojoule
        { unit = "J",  threshold = 0,    factor = 1     }  -- Joule
    }
    local power_units = {
        { unit = "PW", threshold = 1e15, factor = 1e-15 }, -- Petawatt
        { unit = "TW", threshold = 1e12, factor = 1e-12 }, -- Terawatt
        { unit = "GW", threshold = 1e9,  factor = 1e-9  }, -- Gigawatt
        { unit = "MW", threshold = 1e6,  factor = 1e-6  }, -- Megawatt
        { unit = "kW", threshold = 1e3,  factor = 1e-3  }, -- Kilowatt
        { unit = "W",  threshold = 0,    factor = 1     }  -- Watt
    }
    local units = unit_type == "W" and power_units or energy_units
    local abs_value = math.abs(value)
    for _, unit_info in ipairs(units) do
        if abs_value >= unit_info.threshold then
            local scaled_value = value * unit_info.factor
            local formatted_value = string.format("%.2f", scaled_value)
            -- Remove trailing zeros and possible trailing decimal point
            formatted_value = formatted_value:gsub("(%d)%.?0*$", "%1")
            return formatted_value .. space .. unit_info.unit
        end
    end
end

-- Get unique identifier based on location and surface
function Util.poskey(entity)
    local pos = entity.position
    return pos.x .. ";" .. pos.y .. ";" .. entity.surface.name
end

function Util.backername()
    return game.backer_names[math.random(#game.backer_names)]
end

function Util.sort_teleporters(list, player_force_name)
    table.sort(list, function(data_a, data_b)
        local a = data_a.entity
        local b = data_b.entity

        -- Check that all required fields exist
        if not (a and b and a.force and b.force and a.surface and b.surface) then
            return false
        end

        -- Prioritize the player's force
        if a.force.name == player_force_name and b.force.name ~= player_force_name then
            return true
        elseif b.force.name == player_force_name and a.force.name ~= player_force_name then
            return false
        end

        -- Sort alphabetically by force name
        if a.force.name ~= b.force.name then
            return a.force.name < b.force.name
        end

        -- If force names are the same, sort by surface.planet (nil is lower priority)
        if a.surface.planet ~= b.surface.planet then
            if a.surface.planet == nil then
                return false -- a has lower priority
            elseif b.surface.planet == nil then
                return true -- b has lower priority
            else
                return a.surface.planet.prototype.order < b.surface.planet.prototype.order
            end
        end

        -- If planets are the same, sort by surface.name
        if a.surface.name ~= b.surface.name then
            return a.surface.name < b.surface.name
        end

        -- If surface names are the same, sort by nickname
        return (storage.ring_teleporter_nicknames[Util.poskey(a)] or 0) < (storage.ring_teleporter_nicknames[Util.poskey(b)] or 0)
    end)
end

return Util