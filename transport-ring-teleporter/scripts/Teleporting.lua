local Util = require( "scripts/Util" )
local Teleporting = {}

-- Derefs
local robot_group = Util.robot_group

-- Local filter arrays
local ignored_entities = {}
local ignored_types = {}


-- Add a name (and a function to test) to an ignore table
-- "names" is a table of string/table {string, boolean function, [table]} where the string is the name to ignore (true) and optionally a function to test at runtime (for map settings) and finally, an optional table of parameters to unpack for the function
local function add_to_ignore( target, names )
    for _, n in pairs( names ) do
        if n ~= nil then
            if type( n ) == "string" and n ~= "" then
                target[ n ] = true
            end
            if type( n ) == "table" then
                local entity = n[ 1 ]
                local func   = n[ 2 ]
                local params = n[ 3 ]
                if type( entity ) == "string" and entity ~= "" and type( func ) == "function" then
                    target[ entity ] = { func = func, params = params }
                end
            end
        end
    end
end

-- Test an entity against an ignore list entry
local function is_ignored( list, index )
    if index == nil or type( index ) ~= "string" or index == "" then return false end
    if list == nil or type( list ) ~= "table" then return false end
    local li = list[ index ]
    if li == nil then return false end
    if type( li ) == "table" and li.func ~= nil then
        if li.params then
            return li.func( table.unpack( li.params ) )
        end
        return li.func()
    end
    return li
end

-- Test whether an entity is ignored by entity name
local function is_ignored_entity( name )
    return is_ignored( ignored_entities, name )
end

-- Test whether an entity is ignored by type name
local function is_ignored_type( name )
    return is_ignored( ignored_types, name )
end


-- The Util functions to return the game settings are the inverse of what we need here
local function invert_bool_func( func, ... )
    return not func( ... )
end


-- Ignore specific entities
add_to_ignore( ignored_entities, {
    "trt-placer-mk1",
    "trt-platform-mk1",
    "trt-map-interface-mk1",
    "trt-output-mk1",
    "trt-barrier",
} )


-- Ignore whole classes of entities
add_to_ignore( ignored_types, {
    -- Decals and meta-entities
    "arrow",
    "speech-bubble",
    "highlight-box",
    "item-request-proxy",
    "sticker",
    
    -- Weapons fire in-flight
    "artillery-flare",
    "artillery-projectile",
    "beam",
    "projectile",
    "stream",
    
    -- Landscape features, do teleport plants and trees though
    "cliff",
    "optimized-decorative",
    --"plant",
    --"tree",
    
    -- Spooky ghosts!
    "entity-ghost",
    "tile-ghost",
    
    -- Hidden entities that are part of real entities
    "burner-generator",
    "electric-energy-interface",
    "heat-interface",
    
    -- Space Age
    "asteroid-collector",
    "asteroid",
    "asteroid-chunk",
    "rocket-silo",
    "rocket-silo-rocket",
    "rocket-silo-rocket-shadow",
    "cargo-pod",
    "cargo-bay",
    "cargo-landing-pad",
    "space-platform-hub",
    "thruster",
    
    -- Robbits
    "capture-robot", -- Always ignore capture bots, they are only deployed when their associated rocket is fired at a specific target
    { "combat-robot"        , invert_bool_func, { Util.teleport_robots, robot_group.combat        } },  -- Bring the players followers with them
    { "construction-robot"  , invert_bool_func, { Util.teleport_robots, robot_group.construction  } },  -- Get ready for headaches!
    { "logistic-robot"      , invert_bool_func, { Util.teleport_robots, robot_group.logistics     } },  -- More headaches!
    
    -- Rails - Be sure to build matching rails on the other side!
    "curved-rail-a",
    "curved-rail-b",
    "half-diagonal-rail",
    "straight-rail",
    
    "elevated-curved-rail-a",
    "elevated-curved-rail-b",
    "elevated-half-diagonal-rail",
    "elevated-straight-rail",
    "rail-support",
    "rail-ramp",
    
    "legacy-curved-rail",
    "legacy-straight-rail",
    
    "rail-chain-signal",
    "rail-signal",
    "train-stop",
    
    -- Tiles
    "tile",
    "tile-effect",
    "deconstructible-tile-proxy",
    
    -- There's something in the air...
    "airborne-pollutant",
    "explosion",
    "fire",
    "lightning",
    "optimized-particle",
    "particle-source",
    "smoke-with-trigger",
    "trivial-smoke",
    
    -- Vulcanus demolishers are too big!
    "segmented-unit",
    "segment",
    
} )


function Teleporting.get_teleportable_objects( entity )
    
    local function get_objects( surface, p )
        local area = {
            left_top = { x = p.x - 7, y = p.y - 5 },
            right_bottom = { x = p.x - 2, y = p.y - 0.5 }
        }
        return surface.find_entities_filtered{ area = area }
    end
    
    local raw_objects = get_objects( entity.surface, entity.position )
    
    local result = {}
    for _, e in pairs( raw_objects ) do
        if not is_ignored_entity( e.name ) and not is_ignored_type( e.type ) then
            result[ #result + 1 ] = e
        end
    end
    
    return result
end




local PLAYER_TELEPORT_SOUND = "player_post_teleport_sfx"


local function player_post_teleport_sfx( player )
    player.play_sound{ path = "trt-teleport-player", position = player.position }
end



-- Main teleport function
local function teleport_entity( entity, target_surface, target_position )
    if not (entity and target_surface and target_position) then return end
    local new = entity.clone{position={x = target_position.x, y = target_position.y}, surface=target_surface, force=entity.force, create_build_effect_smoke=false}
    if new then
        entity.destroy()
    end
    return new
end

local function teleport_train( entity, target_surface, target_position )
    local limit = Util.train_length_limit()
    if limit == 0 then return end -- Trains are not allowed to be teleported.
    
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
    local base_entity = carriages[ 1 ]
    if not base_entity.valid then return end
    
    -- Target is the destination teleporter so base position for correct relative placement must be the source teleporter
    local base_pos = entity.position
    
    -- Collect data for all carriages
    local carriage_data = {}
    for index, carriage in ipairs( carriages ) do
        if carriage.valid then
            carriage_data[ index ] = {
                name = carriage.name,
                entity = carriage,
                relative_position = { x = carriage.position.x - base_pos.x, y = carriage.position.y - base_pos.y },
            }
        end
        if index >= limit then
            break
        end
    end
    
    -- Clone the train
    local new_carriages = {}
    for index, data in ipairs( carriage_data ) do
        local old_carriage = data.entity
        if old_carriage.valid then
            local new_carriage = old_carriage.clone{
                position = {
                    x = target_position.x + data.relative_position.x,
                    y = target_position.y + data.relative_position.y
                },
                surface = target_surface,
                force = force,
                create_build_effect_smoke = false,
            }
            if new_carriage then
                new_carriage.set_driver( old_carriage.get_driver() )
                old_carriage.destroy()
                new_carriages[ index ] = new_carriage
            end
        end
    end
    
    -- Reconstruct the train details
    if new_carriages[ 1 ] ~= nil then
        local new_train = new_carriages[ 1 ].train
        if new_train then
            new_train.schedule = schedule
            new_train.manual_mode = is_manual
            new_train.speed = speed
            new_train.group = group
        end
    end
end

function Teleporting.ring_teleport( entity, target_surface, target_position )
    if not entity.valid then return end
    if is_ignored_entity( entity.name ) or is_ignored_type( entity.type ) then return end

    if Util.can_vanilla_teleport( entity ) then
        entity.teleport( target_position, target_surface, true )
        if entity.type == "character" then
            local player = entity.player
            if player and player.valid then
                local force = player.force
                if not force.is_chunk_charted( target_surface, target_position ) then
                    force.chart( target_surface, { target_position, target_position } )
                end
                Util.schedule_after( 1, PLAYER_TELEPORT_SOUND, { player } ) -- Need one tick for charting
            end
        end
        return
    end

    if entity.train then
        teleport_train( entity, target_surface, target_position )
    else
        teleport_entity( entity, target_surface, target_position )
    end
end




-- Map functions that can be scheduled.
Util.map_functions{
    [ PLAYER_TELEPORT_SOUND ] = player_post_teleport_sfx,
}


return Teleporting