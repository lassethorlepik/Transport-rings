require("util")

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

local function create_barrier(entity)
    if not entity.valid then return {} end  -- Ensure the entity is valid
    local p = entity.position
    local surface = entity.surface
    local barrier_name = "ring-teleporter-barrier"
    local area = {
        left_top = {x = p.x - 2, y = p.y + 1},
        right_bottom = {x = p.x + 2, y = p.y + 4}
    }
    local barrier = {}
    -- Function to attempt placing a barrier at a specific position
    local function try_place(x, y)
        local pos = {x = x, y = y}
        if surface.can_place_entity{name = barrier_name, position = pos} then
            local placed_entity = surface.create_entity{name = barrier_name, position = pos}
            if placed_entity then
                table.insert(barrier, placed_entity)
            end
        end
    end
    -- Place top and bottom borders
    for x = area.left_top.x - 1, area.right_bottom.x + 1 do
        try_place(x, area.left_top.y - 1)      -- Top border
        try_place(x, area.right_bottom.y + 1)  -- Bottom border
    end
    -- Place left and right borders
    for y = area.left_top.y, area.right_bottom.y do
        try_place(area.left_top.x - 1, y)      -- Left border
        try_place(area.right_bottom.x + 1, y)  -- Right border
    end

    try_place(area.left_top.x + 2, area.left_top.y - 0.49)

    return barrier
end

local function barrier_start(entity)
    storage.ring_teleporter_teleporters[entity.unit_number].barrier_list = create_barrier(entity)
end

local function destroy_animations(entity, animation1, animation2)
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

-- Function to play the one-time animation
function animate_teleporter(entity)
    if not entity.valid then return end  -- Ensure the entity is still valid

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
    play_random_sound(entity, {"ring-1", "ring-2", "ring-3", "ring-4", "ring-5"})
    
    schedule_after(20, function() barrier_start(entity) end)
    schedule_after(300, function() destroy_animations(entity, animation1, animation2) end)
end

-- Function to teleport an entity or an entire train
local function ring_teleport(entity, target_surface, target_position)
    game.print("s")
    if not entity.valid then return end  -- Ensure the entity is still valid

    local entity_name = entity.name
    if entity_name == "ring-teleporter-barrier" or entity.type == "entity-ghost" then return end

    if can_vanilla_teleport(entity) then
        entity.teleport(target_position, target_surface)
        return
    end

    -- Function to teleport regular entities
    local function teleport_entity(e)
        local entity_type = e.type
        local force = e.force
        local direction = e.direction
        local health = e.health
        local inventories = {}

        -- Collect inventory contents if applicable
        if entity_type == "container" or entity_type == "logistic-container" or entity_type == "storage-tank" then
            inventories.main = e.get_inventory(defines.inventory.chest).get_contents()
        elseif entity_type == "assembling-machine" then
            inventories.main = e.get_inventory(defines.inventory.assembling_machine_input).get_contents()
            inventories.output = e.get_inventory(defines.inventory.assembling_machine_output).get_contents()
        end

        -- Create the new entity at the target location
        local new_entity = target_surface.create_entity{
            name = e.name,
            position = target_position,
            force = force,
            direction = direction,
            raise_built = false,
            create_build_effect_smoke = false,
        }

        if not new_entity then return end  -- Failed to create

        -- Restore health
        if health and new_entity.health then
            new_entity.health = health
        end

        -- Restore inventories
        if inventories.main then
            local inventory = nil
            if entity_type == "container" or entity_type == "logistic-container" or entity_type == "storage-tank" then
                inventory = new_entity.get_inventory(defines.inventory.chest)
            elseif entity_type == "assembling-machine" then
                inventory = new_entity.get_inventory(defines.inventory.assembling_machine_input)
                for item, count in pairs(inventories.main) do
                    inventory.insert{name = item, count = count}
                end
                inventory = new_entity.get_inventory(defines.inventory.assembling_machine_output)
                for item, count in pairs(inventories.output) do
                    inventory.insert{name = item, count = count}
                end
            end
            if inventory then
                for item, count in pairs(inventories.main) do
                    inventory.insert{name = item, count = count}
                end
            end
        end

        -- Handle inserter filters
        if entity_type == "inserter" then
            local filter = e.get_filter(1)
            if filter then
                new_entity.set_filter(1, filter)
            end
        end

        -- Destroy the old entity
        e.destroy()
    end

    -- Check if the entity is part of a train
    if entity.train then
        local train = entity.train
        local schedule = train.schedule
        local force = entity.force
        local is_manual = train.manual_mode
        local speed = train.speed
        local group = train.group
        -- Collect all carriages
        local carriages = train.carriages
        if #carriages == 0 then return end  -- No carriages to teleport

        -- Determine base position (first locomotive)
        local base_entity = carriages[1]
        if not base_entity.valid then return end
        local base_pos = base_entity.position

        -- Calculate relative positions of all carriages to the base
        local relative_positions = {}
        for _, carriage in ipairs(carriages) do
            relative_positions[carriage.unit_number] = {x = carriage.position.x - base_pos.x, y = carriage.position.y - base_pos.y}
        end

        -- Collect data for all carriages
        local carriage_data = {}
        for _, carriage in ipairs(carriages) do
            if carriage.valid then
                table.insert(carriage_data, {
                    name = carriage.name,
                    relative_position = relative_positions[carriage.unit_number],
                    direction = carriage.direction,
                    health = carriage.health,
                    inventories = {}
                })

                -- Collect inventories if applicable
                local c_type = carriage.type
                if c_type == "cargo-wagon" then
                    carriage_data[#carriage_data].inventories.cargo = carriage.get_inventory(defines.inventory.cargo_wagon).get_contents()
                elseif c_type == "artillery-wagon" then
                    carriage_data[#carriage_data].inventories.ammo = carriage.get_inventory(defines.inventory.artillery_wagon_ammo).get_contents()
                elseif c_type == "fluid-wagon" then
                    carriage_data[#carriage_data].inventories.fluid = carriage.get_fluid_contents() 
                elseif c_type == "locomotive" then
                    carriage_data[#carriage_data].inventories.fuel = carriage.get_inventory(defines.inventory.fuel).get_contents()
                else
                    -- Handle other types or log unsupported types
                end
            end
        end

        -- Destroy all carriages
        for _, carriage in ipairs(carriages) do
            carriage.destroy()
        end

        -- Recreate all carriages at the new position
        local new_carriages = {}
        for _, data in ipairs(carriage_data) do
            local new_pos = {
                x = target_position.x + data.relative_position.x,
                y = target_position.y + data.relative_position.y
            }
            local new_carriage = target_surface.create_entity{
                name = data.name,
                position = new_pos,
                force = force,
                direction = data.direction,
                raise_built = false,
                create_build_effect_smoke = false,
            }
            if new_carriage then
                -- Restore health
                if data.health and new_carriage.health then
                    new_carriage.health = data.health
                end

                -- Restore inventories
                if data.inventories.cargo then
                    local inventory = new_carriage.get_inventory(defines.inventory.cargo_wagon)
                    if inventory then
                        for _, stack in pairs(data.inventories.cargo) do
                            inventory.insert{name = stack.name, count = stack.count}
                        end
                    end
                end
                if data.inventories.ammo then
                    local inventory = new_carriage.get_inventory(defines.inventory.artillery_wagon_ammo)
                    if inventory then
                        for _, stack in pairs(data.inventories.ammo) do
                            inventory.insert{name = stack.name, count = stack.count}
                        end
                    end
                end
                if data.inventories.fuel then
                    local inventory = new_carriage.get_inventory(defines.inventory.fuel)
                    if inventory then
                        for _, stack in pairs(data.inventories.fuel) do
                            inventory.insert{name = stack.name, count = stack.count}
                        end
                    end
                end
                if data.inventories.fluid then
                    for name, amount in pairs(data.inventories.fluid) do
                        new_carriage.insert_fluid({name=name, amount=amount})
                    end
                end
            end
            table.insert(new_carriages, new_carriage)
        end

        -- Reconstruct the train schedule
        local carriage = new_carriages[1]
        if carriage then
            local new_train = carriage.train
            if new_train then
                new_train.schedule = schedule
                new_train.manual_mode = is_manual
                new_train.speed = speed
                new_train.group = group
            end
        end

    else
        -- Handle regular entity teleportation
        teleport_entity(entity)
    end
end

local function get_teleporter_id(entity)
    if entity and entity.valid then
        local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
        local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
        triggered = false
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

local function start_teleport(src_teleporter_data, dest_teleporter_data)
    game.print("s1")
    local src_teleporter = src_teleporter_data.entity
    local dest_teleporter = dest_teleporter_data.entity
    if src_teleporter and src_teleporter.valid then
        local p = src_teleporter.position
        local area = {
            left_top = {x = p.x - 2.5, y = p.y + 1.5},
            right_bottom = {x = p.x + 2.5, y = p.y + 4.5}
        }
        local targets = src_teleporter.surface.find_entities_filtered{area = area}
        for _, target in ipairs(targets) do
            local relative = get_relative_position(target, src_teleporter)
            ring_teleport(target, dest_teleporter.surface, add_positions(dest_teleporter.position, relative))
        end
    end
    src_teleporter_data.occupied = false
    dest_teleporter_data.occupied = false
end

local function trigger_teleport(src_teleporter_data, signal)
    game.print("a")
    local src_teleporter = src_teleporter_data.entity
    for _, dest_teleporter_data in pairs(storage.ring_teleporter_teleporters) do
        local dest_teleporter = dest_teleporter_data.entity
        if dest_teleporter and dest_teleporter.valid then
            if signal == get_teleporter_id(dest_teleporter) then
                game.print("1")
                if not src_teleporter_data.occupied and dest_teleporter_data.occupied then
                    src_teleporter.occupied = true
                    dest_teleporter_data.occupied = true
                    game.print("2")
                    schedule_after(300 - game.tick % 300, function()
                        game.print("3")
                        if src_teleporter and src_teleporter.valid then
                            src_teleporter.energy = src_teleporter.energy - 1000000000
                            animate_teleporter(src_teleporter)
                            animate_teleporter(dest_teleporter)
                            schedule_after(150, function() start_teleport(src_teleporter_data, dest_teleporter_data) end)
                        else
                            src_teleporter_data.occupied = false
                            dest_teleporter_data.occupied = false
                        end
                    end)
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
        storage.ring_teleporter_teleporters[entity.unit_number] = {entity = entity, renderer = renderer}
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
            entity = data.entity
            if entity and entity.valid then
                local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
                local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
                triggered = false
                if network_red then
                    local signal = network_red.get_signal({type="virtual", name="goto-ring-id"})
                    if signal and signal ~= 0 and entity.energy >= 1000000000 then -- 1 GJ
                        trigger_teleport(data, signal)
                        triggered = true
                    end
                end
                if not triggered and network_green then
                    local signal = network_green.get_signal({type="virtual", name="goto-ring-id"})
                    if signal and signal ~= 0 and entity.energy >= 1000000000 then -- 1 GJ
                        trigger_teleport(data, signal)
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
            local result = scheduled.func
            -- Remove the executed function from the table
            table.remove(storage.ring_teleporter_scheduled_functions, i)
        end
    end
end)