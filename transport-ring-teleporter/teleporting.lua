local util = require("util")
local Teleporting = {}

-- Helper function to serialize control behavior
local function serialize_control_behavior(cb)
    if not cb then return nil end
    local cb_type = cb.entity.name
    if not cb_type then return nil end
    local serialized = {type = cb_type}
    -- Serialize based on control behavior type
    if cb_type == "arithmetic-combinator" or cb_type == "decider-combinator" or cb_type == "selector-combinator" then
        serialized.parameters = cb.condition
    elseif cb_type == "constant-combinator" then
        serialized.signals = cb.sections
    elseif cb_type == "programmable-speaker" then
        serialized.speaker_state = cb.state
        serialized.signal = cb.signal
    elseif cb_type == "power-switch" then
        serialized.switch_state = cb.switch_state
    end
    
    return serialized
end

-- Helper function to deserialize and apply control behavior
local function deserialize_control_behavior(cb, data)
    if not (cb and data and data.type == cb.entity.name) then return end
    if data.type == "arithmetic-combinator" or data.type == "decider-combinator" or data.type == "selector-combinator" then
        cb.condition = data.parameters
    elseif data.type == "constant-combinator" then
        cb.sections = data.sections
    elseif data.type == "programmable-speaker" then
        cb.state = data.speaker_state
        cb.signal = data.signal
    elseif data.type == "power-switch" then
        cb.switch_state = data.switch_state
    end
end

-- Main teleport function
local function teleport_entity(entity, target_surface, target_position, mapping)
    if not (entity and target_surface and target_position) then return end

    local type_defs = {
        ["container"] = {inv = {defines.inventory.chest}},
        ["logistic-container"] = {inv = {defines.inventory.chest}},
        ["storage-tank"] = {inv = {defines.inventory.chest}},
        ["assembling-machine"] = {inv = {defines.inventory.assembling_machine_input, defines.inventory.assembling_machine_output}},
        ["furnace"] = {inv = {defines.inventory.furnace_source, defines.inventory.furnace_destination, defines.inventory.fuel}},
        ["inserter"] = {special = {"filter"}},
        ["arithmetic-combinator"] = {control_behavior = true},
        ["decider-combinator"] = {control_behavior = true},
        ["selector-combinator"] = {control_behavior = true},
        ["constant-combinator"] = {control_behavior = true},
        ["programmable-speaker"] = {special = {"circuit_parameters"}, control_behavior = true},
        ["power-switch"] = {special = {"switch_state"}, control_behavior = true},
        -- Add other entities as needed
    }

    local defs = type_defs[entity.type]
    local data = {inv = {}, special = {}, control_behavior = nil}

    if defs then
        -- Backup inventories
        if defs.inv then
            for i, inv_id in ipairs(defs.inv) do
                data.inv[i] = entity.get_inventory(inv_id).get_contents()
            end
        end
        -- Backup special properties
        if defs.special then
            for _, prop in ipairs(defs.special) do
                if prop == "filter" then
                    data.special.filter = entity.get_filter(1)
                elseif prop == "circuit_parameters" then
                    data.special.circuit_parameters = entity.circuit_parameters
                elseif prop == "signal" then
                    data.special.signal = entity.get_signal()
                elseif prop == "switch_state" then
                    data.special.switch_state = entity.switch_state
                end
            end
        end
        -- Backup control behavior
        if defs.control_behavior then
            local cb = entity.get_control_behavior()
            data.control_behavior = serialize_control_behavior(cb)
        end
    end

    -- Create new entity
    local new = target_surface.create_entity{
        name = entity.name,
        position = target_position,
        force = entity.force,
        direction = entity.direction,
        raise_built = false,
        create_build_effect_smoke = false,
    }
    if not new then return end

    -- Restore health
    if entity.health and new.health then new.health = entity.health end

    -- Restore inventories and special properties
    if defs then
        if defs.inv then
            for i, inv_id in ipairs(defs.inv) do
                local tgt_inv = new.get_inventory(inv_id)
                if tgt_inv and data.inv[i] then
                    for item, count in pairs(data.inv[i]) do
                        tgt_inv.insert{name = item, count = count}
                    end
                end
            end
        end
        if defs.special then
            for _, prop in ipairs(defs.special) do
                if prop == "filter" and data.special.filter then
                    new.set_filter(1, data.special.filter)
                elseif prop == "circuit_parameters" and data.special.circuit_parameters then
                    new.circuit_parameters = data.special.circuit_parameters
                elseif prop == "signal" and data.special.signal then
                    new.set_signal(data.special.signal)
                elseif prop == "switch_state" and data.special.switch_state then
                    new.switch_state = data.special.switch_state
                end
            end
        end
        -- Restore control behavior
        if defs.control_behavior and data.control_behavior then
            local cb = new.get_control_behavior()
            deserialize_control_behavior(cb, data.control_behavior)
        end
    end

    -- Handle wire connections
    if mapping then
        for _, wire in ipairs({"red", "green", "electric"}) do
            local wire_type = defines.wire_type[wire] or defines.wire_type.electric
            local network = entity.get_circuit_network(wire, wire_type)
            if network then
                for _, connected in pairs(network.connected_entities) do
                    local new_conn = mapping[connected]
                    if new_conn then
                        new.connect_neighbour{wire = wire_type, target_entity = new_conn}
                    end
                end
            end
        end
    end

    -- Map original to new entity
    if mapping then mapping[entity] = new end

    entity.destroy()
    return new
end

local function teleport_train(entity, target_surface, target_position)
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
end

function Teleporting.ring_teleport(entity, target_surface, target_position)
    if not entity.valid then return end
    if Teleporter_ignored_entities[entity.name] or entity.type == "entity-ghost" then return end

    if util.can_vanilla_teleport(entity) then
        entity.teleport(target_position, target_surface)
        return
    end

    if entity.train then
        teleport_train(entity, target_surface, target_position)
    else
        teleport_entity(entity, target_surface, target_position)
    end
end

return Teleporting