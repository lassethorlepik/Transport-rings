local util = require("util")
local teleporting = require("Teleporting")

script.on_init(function()
    storage.ring_teleporter_teleporters = {}
    storage.ring_teleporter_scheduled_functions = {}
end)

script.on_configuration_changed(function()
    storage.ring_teleporter_teleporters = storage.ring_teleporter_teleporters or {}
    storage.ring_teleporter_scheduled_functions = storage.ring_teleporter_scheduled_functions or {}
end)

local event_filter = {
    {filter="name", name="ring-teleporter"},
}

Teleporter_ignored_entities = {
    ["ring-teleporter"] = true,
    ["ring-teleporter-sprite"] = true,
    ["ring-teleporter-back"] = true,
    ["ring-teleporter-front"] = true,
    ["ring-teleporter-barrier"] = true,
}

local function ring_collision_incident(surface, pos, teleporter)
    local hits = surface.find_entities_filtered{position = pos, radius = 0.75}
    for _, hit in ipairs(hits) do
        if hit.valid and hit.is_entity_with_health and not Teleporter_ignored_entities[hit.name] then
            local dmg = math.random(250, 500)
            hit.damage(dmg, "neutral")
            if teleporter and teleporter.valid then
                teleporter.damage(dmg, "neutral")
            end
        end
    end
end

local function create_barrier(entity)
    if not entity.valid then return {} end
    local p = entity.position
    local surface = entity.surface
    local barrier_name = "ring-teleporter-barrier"
    local barrier = {}
    local left = p.x - 2
    local right = p.x + 2
    local top = p.y + 0.5
    local bottom = p.y + 3.5
    local function try_place(x, y)
        local pos = {x = x, y = y}
        if surface.can_place_entity{name = barrier_name, position = pos} then
            local placed_entity = surface.create_entity{name = barrier_name, position = pos}
            if placed_entity then
                table.insert(barrier, placed_entity)
            end
        else
            ring_collision_incident(surface, pos, entity)
        end
    end
    -- Place top and bottom borders without extending to corners
    for x = left, right do
        try_place(x, top - 1)      -- Top border
        try_place(x, bottom + 1)   -- Bottom border
    end
    -- Place left and right borders without overlapping the corners
    for y = top, bottom do
        try_place(left - 1, y)     -- Left border
        try_place(right + 1, y)    -- Right border
    end
    -- Top block offset due to teleporter collider
    try_place(left + 2, top - 1.05)
    return barrier
end

local function barrier_start(entity)
    storage.ring_teleporter_teleporters[entity.unit_number].barrier_list = create_barrier(entity)
end

local function destroy_animations(entity, animation1, animation2)
    if entity.valid then
        local list = storage.ring_teleporter_teleporters[entity.unit_number].barrier_list
        if list then
            for _, entity in ipairs(list) do
                if entity and entity.valid then
                    entity.destroy()
                end
            end
            if animation1 and animation1.valid then
                animation1.destroy()
            end
            if animation2 and animation2.valid then
                animation2.destroy()
            end
        end
    end
end

-- Function to play the one-time animation
local function animate_teleporter(entity)
    if not entity.valid then return end

    local surface = entity.surface
    local position = entity.position

    local animation1 = surface.create_entity{
        name = "ring-teleporter-back",
        position = position,
        raise_built = false,
        create_build_effect_smoke = false,
    }

    local animation2 = surface.create_entity{
        name = "ring-teleporter-front",
        position = position,
        raise_built = false,
        create_build_effect_smoke = false,
    }

    storage.ring_teleporter_teleporters[entity.unit_number].animation1 = animation1
    storage.ring_teleporter_teleporters[entity.unit_number].animation2 = animation2
    util.play_random_sound(entity, {"ring-1", "ring-2", "ring-3", "ring-4", "ring-5"})
    
    util.schedule_after(20, "barrier_start", {entity})
    util.schedule_after(300, "destroy_animations", {entity, animation1, animation2})
end

local function get_teleporter_id(entity)
    if entity and entity.valid then
        local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
        local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
        local triggered = false
        if network_red then
            local signal = network_red.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                return signal
            end
        end
        if not triggered and network_green then
            local signal = network_green.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                return signal
            end
        end
    end
end

local function timed_teleport(src_teleporter_data, dest_teleporter_data)
    local src_teleporter = src_teleporter_data.entity
    local dest_teleporter = dest_teleporter_data.entity
    if src_teleporter and src_teleporter.valid then
        local p = src_teleporter.position
        local area = {
            left_top = {x = p.x - 3, y = p.y - 0.5},
            right_bottom = {x = p.x + 3, y = p.y + 4.2}
        }
        local targets = src_teleporter.surface.find_entities_filtered{area = area}
        for _, target in ipairs(targets) do
            if target.valid and src_teleporter.valid then
                local relative = util.get_relative_position(target, src_teleporter)
                teleporting.ring_teleport(target, dest_teleporter.surface, util.add_positions(dest_teleporter.position, relative))
            end
        end
    end
    src_teleporter_data.occupied = false
    dest_teleporter_data.occupied = false
end

local function timed_teleport_animation(src_teleporter_data, dest_teleporter_data)
    local src_teleporter = src_teleporter_data.entity
    local dest_teleporter = dest_teleporter_data.entity
    if src_teleporter and src_teleporter.valid then
        src_teleporter.energy = src_teleporter.energy - 1000000000
        animate_teleporter(src_teleporter)
        animate_teleporter(dest_teleporter)
        util.schedule_after(150, "timed_teleport", {src_teleporter_data, dest_teleporter_data})
    else
        src_teleporter_data.occupied = false
        dest_teleporter_data.occupied = false
    end
end

local function signal_teleport(src_teleporter_data, signal)
    for _, dest_teleporter_data in pairs(storage.ring_teleporter_teleporters) do
        local dest_teleporter = dest_teleporter_data.entity
        if dest_teleporter and dest_teleporter.valid then
            if signal == get_teleporter_id(dest_teleporter) then
                if not src_teleporter_data.occupied and not dest_teleporter_data.occupied then
                    src_teleporter_data.occupied = true
                    dest_teleporter_data.occupied = true
                    util.schedule_after(300 - game.tick % 300, "timed_teleport_animation", {src_teleporter_data, dest_teleporter_data})
                end
                break
            end
        end
    end
end

-- TODO: Entities too close 
local function on_built(event)
    local entity = event.entity
    if entity.name == "ring-teleporter" then
        local p = entity.position
        local surf = entity.surface
        surf.destroy_decoratives{area={left_top = {x = p.x - 4, y = p.y - 4}, right_bottom = {x = p.x + 4, y = p.y + 5}}}
        local renderer = surf.create_entity{
            name = "ring-teleporter-sprite",
            position = entity.position,
            raise_built = false,
            create_build_effect_smoke = false,
        }
        storage.ring_teleporter_teleporters[entity.unit_number] = {entity = entity, renderer = renderer, occupied = false}
    end
end

local function on_entity_removed(event)
    local entity = event.entity
    if entity.name == "ring-teleporter" then
        local data = storage.ring_teleporter_teleporters[entity.unit_number]
        if data.animation1 and data.animation1.valid then
            data.animation1.destroy()
        end
        if data.animation2 and data.animation2.valid then
            data.animation2.destroy()
        end
        if data.renderer and data.renderer.valid then
            data.renderer.destroy()
        end
        storage.ring_teleporter_teleporters[entity.unit_number] = nil
    end
end

script.on_event(defines.events.on_built_entity, function(event)
    on_built(event)
end, event_filter)

script.on_event(defines.events.on_robot_built_entity, function(event)
    on_built(event)
end, event_filter)

script.on_event(defines.events.on_player_mined_entity, function(event)
    on_entity_removed(event)
end, event_filter)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    on_entity_removed(event)
end, event_filter)

script.on_event(defines.events.on_entity_died, function(event)
    on_entity_removed(event)
end)

-- Handling signals
script.on_nth_tick(30, function(event)
    -- Process each ring-teleporter
    for _, data in pairs(storage.ring_teleporter_teleporters) do
        if not data.occupied then
            local entity = data.entity
            if entity and entity.valid then
                local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
                local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
                local triggered = false
                if network_red then
                    local signal = network_red.get_signal({type="virtual", name="goto-ring-id"})
                    if signal and signal ~= 0 and entity.energy >= 999999999 then -- 1 GJ
                        signal_teleport(data, signal)
                        triggered = true
                    end
                end
                if not triggered and network_green then
                    local signal = network_green.get_signal({type="virtual", name="goto-ring-id"})
                    if signal and signal ~= 0 and entity.energy >= 999999999 then -- 1 GJ
                        signal_teleport(data, signal)
                    end
                end
            end
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)
    local current_tick = event.tick
    -- Iterate through the scheduled_functions table in reverse
    for i = #storage.ring_teleporter_scheduled_functions, 1, -1 do
        local scheduled = storage.ring_teleporter_scheduled_functions[i]
        if current_tick >= scheduled.tick then
            -- Execute the function
            util.Execute(scheduled.func_id, scheduled.params)
            -- Remove the executed function from the table
            table.remove(storage.ring_teleporter_scheduled_functions, i)
        end
    end
end)

-- Finally define functions, that can be scheduled.
Function_map = {
    barrier_start = barrier_start,
    destroy_animations = destroy_animations,
    timed_teleport = timed_teleport,
    timed_teleport_animation = timed_teleport_animation,
}
