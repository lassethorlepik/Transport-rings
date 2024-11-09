local util = require("util")
local Teleporting = {}

-- Main teleport function
local function teleport_entity(entity, target_surface, target_position, mapping)
    if not (entity and target_surface and target_position) then return end
    local new = entity.clone{position={x = target_position.x, y = target_position.y}, surface=target_surface, force=entity.force, create_build_effect_smoke=false}
    if new then
        entity.destroy()
    end
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
    local limit = settings.global["trt-train-limit"].value
    if limit == 0 then return end -- Trains are not allowed to be teleported.
    local base_pos = base_entity.position
    -- Calculate relative positions of all carriages to the base
    local relative_positions = {}
    for _, carriage in ipairs(carriages) do
        relative_positions[carriage.unit_number] = {x = carriage.position.x - base_pos.x, y = carriage.position.y - base_pos.y}
    end
    -- Collect data for all carriages
    local carriage_data = {}
    local counter = 0
    for _, carriage in ipairs(carriages) do
        if carriage.valid then
            table.insert(carriage_data, {
                name = carriage.name,
                entity = carriage,
                relative_position = relative_positions[carriage.unit_number],
            })
        end
        counter = counter + 1
        if counter >= limit then
            break
        end
    end
    local new_carriages = {}
    for _, data in ipairs(carriage_data) do
        local new_pos = {
            x = target_position.x + data.relative_position.x,
            y = target_position.y + data.relative_position.y
        }
        local entity = data.entity
        if entity.valid then
            local new_carriage = entity.clone{position=new_pos, surface=target_surface, force=force, create_build_effect_smoke=false}
            if new_carriage then
                data.entity.destroy()
            end
            table.insert(new_carriages, new_carriage)
        end
    end
    -- Reconstruct the train details
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
        if entity.type == "character" then
            local player = entity.player
            if player and player.valid then
                local force = player.force
                if not force.is_chunk_charted(target_surface, target_position) then
                    force.chart(target_surface, {target_position, target_position})
                end
                util.schedule_after(1, "After_player_teleport_sound", {player, target_position}) -- Need one tick for charting
            end
        end
        return
    end

    if entity.train then
        teleport_train(entity, target_surface, target_position)
    else
        teleport_entity(entity, target_surface, target_position)
    end
end

return Teleporting