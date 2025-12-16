-- -------------------------------------------------------------------------------- --
local Util = require( "scripts/Util" )
local Teleporting = require( "scripts/Teleporting" )



-- -------------------------------------------------------------------------------- --
-- The Teleporter table

-- NOTE:  All "Teleporter_" (internal functions) are the callers responsibility to sanity check parameters before calling
-- NOTE:  All "Teleporter." (public functions) sanity check all parameters

local Teleporter = {}




-- -------------------------------------------------------------------------------- --
-- Shortcuts for less derefs

local Util_backername                   = Util.backername
local Util_poskey                       = Util.poskey
local Util_get_relative_position        = Util.get_relative_position
local Util_schedule_after               = Util.schedule_after
local Util_play_random_sound            = Util.play_random_sound

local math_random                       = math.random
local table_remove                      = table.remove
local table_insert                      = table.insert




-- -------------------------------------------------------------------------------- --
-- Names of Teleporter related prototypes

local TELEPORTER_PLACER_MK1             = "ring-teleporter-placer"
local TELEPORTER_PLACER_ITEM_MK1        = "ring-teleporter"

local TELEPORTER_CONTROLLER_MK1         = "ring-teleporter"
local TELEPORTER_SPRITE_NAME_MK1        = "ring-teleporter-map-nickname"
local TELEPORTER_OUTPUT_PORT_MK1        = "ring-teleporter-output"

local TELEPORTER_BACK_MK1               = "ring-teleporter-back-anim"
local TELEPORTER_BACK_MK1_LAYER         = "object-under"

local TELEPORTER_FRONT_MK1              = "ring-teleporter-front-anim"
local TELEPORTER_FRONT_MK1_LAYER        = "cargo-hatch"

local TELEPORTER_BARRIER                = "ring-teleporter-barrier"

local TELEPORTER_SPRITE_MK1_OBSOLETE    = "ring-teleporter-sprite"
local TELEPORTER_BACK_MK1_OBSOLETE      = "ring-teleporter-back"
local TELEPORTER_FRONT_MK1_OBSOLETE     = "ring-teleporter-front"

local TELEPORTATION_SOUNDS              = { "ring-1", "ring-2", "ring-3", "ring-4", "ring-5" }

local ENTITY_GHOST                      = "entity-ghost"




-- -------------------------------------------------------------------------------- --
-- Obsolete or potentially orphaned entities to be cleaned up on migration

local Teleporter_obsolete_entities      = {
    TELEPORTER_SPRITE_MK1_OBSOLETE,
    TELEPORTER_BACK_MK1_OBSOLETE,
    TELEPORTER_FRONT_MK1_OBSOLETE,
    TELEPORTER_BARRIER,
}




-- -------------------------------------------------------------------------------- --
-- Teleporter component entities to create and clean up (see Teleporter.new and Teleporter.remove)

local SCAN_AREA                         = 0.125     -- Maximum offset from expected position to search from a component

local TELEPORTER_CONTROLLER             = "controller"
local TELEPORTER_OUTPUT_PORT            = "output_port"
local TELEPORTER_SPRITE_NAME            = "sprite_name"

local Teleporter_component_entity_names = {
    [ TELEPORTER_CONTROLLER ]           = { make = true, name = TELEPORTER_CONTROLLER_MK1 , offset = { x =  0.0  , y =  0.0         }, protected = false, can_be_orphaned = false, has_quality = true  },
    [ TELEPORTER_SPRITE_NAME ]          = { make = true, name = TELEPORTER_SPRITE_NAME_MK1, offset = { x =  0.0  , y =  0.0         }, protected = true , can_be_orphaned = true , has_quality = false },
    [ TELEPORTER_OUTPUT_PORT ]          = { make = true, name = TELEPORTER_OUTPUT_PORT_MK1, offset = { x = -0.125, y = -0.125 + 1.5 }, protected = true , can_be_orphaned = true , has_quality = false },
}




-- -------------------------------------------------------------------------------- --
-- IDs of scheduled functions

local INITIATE_TELEPORT                 = "teleporter_initiate_teleport"
local CREATE_BARRIER                    = "teleporter_create_barrier"
local DESTROY_BARRIER                   = "teleporter_destroy_barrier"
local DESTROY_ANIMATION                 = "teleporter_destroy_animation"
local TELEPORT_OBJECTS                  = "teleporter_teleport_objects"
local TELEPORT_COMPLETE                 = "teleporter_teleport_complete"

-- Near future ticks
local NEAR_FUTURE_TICKS                 = 1




-- -------------------------------------------------------------------------------- --
-- New Animation method data that isn't frame-synced

local ANIMATION_FRAME_COUNT             = 200
local ANIMATION_SPEED                   = 0.6666667
--local ANIMATION_TICKS                   = ANIMATION_FRAME_COUNT / ANIMATION_SPEED
local ANIMATION_TICKS                   = 300 -- Use precomputed value so we don't end up with 299.9999850000007

-- Physical barrier timing
local BARRIER_START_TICKS               = 20
local BARRIER_END_TICKS                 = 238

-- Teleportation timing
local TELEPORTATION_TICK                = 150

-- Teleportation complete
local TELEPORTATION_COMPETE_TICK        = ANIMATION_TICKS + 1




-- -------------------------------------------------------------------------------- --
-- Map of defines.entity_status_diode used in the teleporter custom_status to sprites used in the teleporter GUI

local DIODE_RED                         = defines.entity_status_diode.red
local DIODE_YELLOW                      = defines.entity_status_diode.yellow
local DIODE_GREEN                       = defines.entity_status_diode.green

local DIODE_SPRITE   = {
    [ DIODE_GREEN ]                     = "diode-green",
    [ DIODE_YELLOW ]                    = "diode-yellow",
    [ DIODE_RED ]                       = "diode-red",
}




-- -------------------------------------------------------------------------------- --
-- Teleporter occupied status

local OCCUPIED_UNOCCUPIED               =  0
local OCCUPIED_OUTGOING                 =  1
local OCCUPIED_INCOMING                 = -1




-- -------------------------------------------------------------------------------- --
-- Barrier collision entites and types

local Teleporter_protected_entity_names = {
    [ TELEPORTER_CONTROLLER_MK1 ]       = true,
    [ TELEPORTER_SPRITE_NAME_MK1 ]      = true,
    [ TELEPORTER_OUTPUT_PORT_MK1 ]      = true,
    [ TELEPORTER_BARRIER ]              = true,
}

local Teleporter_protected_entity_types = {
    [ "curved-rail-a" ]                 = true,
    [ "elevated-curved-rail-a" ]        = true,
    [ "curved-rail-b" ]                 = true,
    [ "elevated-curved-rail-b" ]        = true,
    [ "half-diagonal-rail" ]            = true,
    [ "elevated-half-diagonal-rail" ]   = true,
    [ "legacy-curved-rail" ]            = true,
    [ "legacy-straight-rail" ]          = true,
    [ "rail-ramp" ]                     = true,
    [ "straight-rail" ]                 = true,
    [ "elevated-straight-rail" ]        = true,
}




-- -------------------------------------------------------------------------------- --
-- Circuit Signals used by Teleporters

local SIGNAL_RING_ID                    = "ring-id"
local SIGNAL_GOTO_ID                    = "goto-ring-id"
local SIGNAL_TIMER                      = "ring-timer"
local SIGNAL_PROTECTED                  = "shield-rings"

local SIGNAL_STATUS                     = "ring-status"
local SIGNAL_STATUS_LOW_POWER           = "ring-status-low-power"
local SIGNAL_STATUS_OCCUPIED            = "ring-status-occupied"
local SIGNAL_STATUS_WAITING             = "ring-status-waiting"

local Teleporter_custom_status_signals  = {
    [ SIGNAL_RING_ID ]                  = true,
    [ SIGNAL_GOTO_ID ]                  = true,
    [ SIGNAL_TIMER ]                    = true,
    [ SIGNAL_PROTECTED ]                = true,
}




-- -------------------------------------------------------------------------------- --
-- Let other code modules know the strings we use internally

Teleporter.CONTROLLER                   = TELEPORTER_CONTROLLER
Teleporter.OUTPUT_PORT                  = TELEPORTER_OUTPUT_PORT
Teleporter.SPRITE_NAME                  = TELEPORTER_SPRITE_NAME

Teleporter.OCCUPIED_UNOCCUPIED          = OCCUPIED_UNOCCUPIED
Teleporter.OCCUPIED_OUTGOING            = OCCUPIED_OUTGOING
Teleporter.OCCUPIED_INCOMING            = OCCUPIED_INCOMING




-- -------------------------------------------------------------------------------- --
-- Barrier collision handling

local function is_do_not_damage_entity( entity )
    if not ( entity or entity.valid ) then return true end      -- Ignore nil and invalid entities
    if not entity.is_entity_with_health then return true end    -- Entity has no health to damage?
    
    -- Return if the entity is in the excluded lists by name or type
    return Teleporter_protected_entity_names[ entity.name ] or Teleporter_protected_entity_types[ entity.prototype.type ]
end

local function ring_collision_incident( surface, pos, teleporter )
    local hits = surface.find_entities_filtered{ position = pos, radius = 0.75 }
    for _, hit in ipairs( hits ) do
        if not is_do_not_damage_entity( hit ) then
            local dmg = math.random( 250, 500 )
            hit.damage( dmg, "neutral" )
            teleporter.damage( dmg, "neutral" )
        end
    end
end




-- -------------------------------------------------------------------------------- --
-- Circuit signals
-- Signals with a total zero (0) value will return nil


-- This is the only function that will return zero (0) and not nil on a zero/not present signal
local function get_signal_from_wire( wire, name )
    return wire and wire.get_signal( { type = "virtual", name = name } ) or 0
end


-- Return all teleporter related signals, callers responsibility to sanity check
local function Teleporter_get_signals( entity, signals )
    local results = {}
    
    local network_red = entity.get_circuit_network( defines.wire_connector_id.circuit_red )
    local network_green = entity.get_circuit_network( defines.wire_connector_id.circuit_green )
    
    for name, _ in pairs( signals ) do
        local value = get_signal_from_wire( network_red, name )
                    + get_signal_from_wire( network_green, name )
        if value ~= 0 then
            results[ name ] = value
        end
    end
    
    return results
end


-- Return a named signal from a teleporter
local function Teleporter_get_signal( entity, name )
    local network_red = entity.get_circuit_network( defines.wire_connector_id.circuit_red )
    local network_green = entity.get_circuit_network( defines.wire_connector_id.circuit_green )
    
    local value = get_signal_from_wire( network_red, name )
                + get_signal_from_wire( network_green, name )
    
    if value == 0 then
        return nil
    end
    return value
end


-- Get individual circuit signals

function Teleporter.get_signal_ring_id( entity )
    if not( entity and entity.valid ) then return nil end
    return Teleporter_get_signal( entity, SIGNAL_RING_ID )
end
function Teleporter.get_signal_goto_id( entity )
    if not( entity and entity.valid ) then return nil end
    return Teleporter_get_signal( entity, SIGNAL_GOTO_ID )
end
function Teleporter.get_signal_timer( entity )
    if not( entity and entity.valid ) then return nil end
    return Teleporter_get_signal( entity, SIGNAL_TIMER )
end
function Teleporter.get_signal_shield( entity )
    if not( entity and entity.valid ) then return nil end
    return Teleporter_get_signal( entity, SIGNAL_PROTECTED )
end
function Teleporter.has_protection_signal( entity )
    if not( entity and entity.valid ) then return nil end
    return Teleporter_get_signal( entity, SIGNAL_PROTECTED ) ~= nil
end

local function Teleporter_get_signal_ring_id( entity )
    return Teleporter_get_signal( entity, SIGNAL_RING_ID )
end
local function Teleporter_get_signal_goto_id( entity )
    return Teleporter_get_signal( entity, SIGNAL_GOTO_ID )
end
local function Teleporter_get_signal_timer( entity )
    return Teleporter_get_signal( entity, SIGNAL_TIMER )
end
local function Teleporter_get_signal_shield( entity )
    return Teleporter_get_signal( entity, SIGNAL_PROTECTED )
end
local function Teleporter_has_protection_signal( entity )
    return Teleporter_get_signal( entity, SIGNAL_PROTECTED ) ~= nil
end


-- Get the remaining lock-out time for the teleporter, 0 = none
local function Teleporter_get_time_remaining( data )
    local entity = data[ TELEPORTER_CONTROLLER ]
    local timer = Teleporter_get_signal( entity, SIGNAL_TIMER )
    if timer then
        local ticks = timer * 60
        return math.max( 0, ( data.last_teleport + ticks ) - game.tick ) / 60
    end
    return 0
end
function Teleporter.get_time_remaining( entity )
    if not( entity and entity.valid ) then return 0 end
    local data = storage.ring_teleporter_teleporters[ entity.unit_number ]
    if not data then return 0 end
    return Teleporter_get_time_remaining( data )
end


-- Is this teleporter waiting for a timer cooldown?
local function Teleporter_is_waiting( data )
    return Teleporter_get_time_remaining( data ) > 0
end
function Teleporter.is_waiting( entity )
    if not( entity and entity.valid ) then return 0 end
    local data = storage.ring_teleporter_teleporters[ entity.unit_number ]
    if not data then return false end
    return Teleporter_get_time_remaining( data ) > 0
end




-- -------------------------------------------------------------------------------- --
-- Is the teleporter a "friend" of the target entity?

function Teleporter_is_friend( teleporter, target )
    return teleporter.force.is_friend( target.force )
end

function Teleporter.is_friend( teleporter, target )
    if not( teleporter and teleporter.valid ) then return false end
    if not( target and target.valid ) then return false end
    return teleporter.force.is_friend( target.force )
end




-- -------------------------------------------------------------------------------- --
-- Teleporter nickname handling

-- Get the teleporter nickname
local function Teleporter_get_nickname( poskey )
    return storage.ring_teleporter_nicknames[ poskey ] or Util_backername()
end

-- Get the teleporter nickname
function Teleporter.get_nickname( entity )
    if not( entity and entity.valid )then
        return nil
    end
    local poskey = Util_poskey( entity )
    return storage.ring_teleporter_nicknames[ poskey ] or Util_backername()
end


-- Set the teleporter nickname
function Teleporter_set_nickname( data, nickname )
    --log( "Teleporter_set_nickname() - setting nickname at " .. data.poskey .. " to '" .. nickname .. "'" )
    storage.ring_teleporter_nicknames[ data.poskey ] = nickname
    data[ TELEPORTER_SPRITE_NAME ].backer_name = "[item=ring-teleporter] " .. nickname
end

-- Set the teleporter nickname
function Teleporter.set_nickname( entity, nickname )
    if not( entity and entity.valid )then return end
    local data = storage.ring_teleporter_teleporters[ entity.unit_number ]
    if data then
        Teleporter_set_nickname( data, nickname )
    else
        local poskey = Util_poskey( entity )
        --log( "Teleporter.set_nickname() - setting nickname at " .. poskey .. " to '" .. nickname .. "'" )
        storage.ring_teleporter_nicknames[ poskey ] = nickname
    end
end




-- -------------------------------------------------------------------------------- --
-- This returns the charge level (of total accumulator), a diode color to indicate the "status" (yellow = busy, green = ready (not occupied and energy level >= teleport energy cost), red = low charge), the matching diode sprite and, the remaining wait time if the teleporter has a timer input signal
-- To check for whether a teleporter is "ready" just compare diode == DIODE_GREEN (or defines.entity_status_diode.green)

local function Teleporter_get_status( data )
    local entity = data[ TELEPORTER_CONTROLLER ]
    local energy = entity.energy
    local limit = entity.electric_buffer_size -- Use actual teleporter energy buffer limit
    local charge_level = energy / limit
    local remaining = Teleporter_get_time_remaining( data )
    local occupied = data.occupied
    occupied = ( occupied ~= OCCUPIED_UNOCCUPIED ) or ( remaining > 0 )   -- Effectively occupied if a timer is still in effect
    local diode = energy < storage.power_per_teleport and DIODE_RED or ( occupied and DIODE_YELLOW or DIODE_GREEN )
    return charge_level, diode, DIODE_SPRITE[ diode ], remaining
end

function Teleporter.get_status( entity )
    if not( entity and entity.valid )then return end
    local data = storage.ring_teleporter_teleporters[ entity.unit_number ]
    if not data then return end
    return Teleporter_get_status( data )
end




-- -------------------------------------------------------------------------------- --
-- Update the signals on the output port

local function Teleporter_update_output_port( data )
    
    local entity = data[ TELEPORTER_CONTROLLER ]
    local output = data.output_port
    
    -- Get the control behaviour of the output port
    local behavior = output.get_control_behavior()
    if not behavior then return end
    
    -- Remove any existing sections from it
    while( behavior.sections_count > 0 )do
        behavior.remove_section( 1 )
    end
    
    -- Add one new section for our signals
    local section = behavior.add_section()
    if not section then return end
    
    local occupied = data.occupied
    
    -- Get the status of the controller
    local charge_level, diode, sprite, remaining = Teleporter_get_status( data )
    
    -- Convert complex results into simple virtual signals
    local signal_tests = {
        [ SIGNAL_STATUS ] = function() return diode == DIODE_GREEN and 1 or ( diode == DIODE_YELLOW and 2 or 3 ) end,
        [ SIGNAL_STATUS_LOW_POWER ] = function() return ( entity.energy < storage.power_per_teleport ) and 1 or 0 end,
        [ SIGNAL_STATUS_OCCUPIED ] = function() return occupied end,
        [ SIGNAL_STATUS_WAITING ] = function() return remaining > 0 and math.floor( remaining + 1.0 ) or 0 end,
    }
    
    -- Only add non-zero value signals to be consistent with vanilla (for anything inspecting the output signals via Lua)
    local slot = 1
    for name, test in pairs( signal_tests ) do
        local value = test()
        if value ~= 0 then
            section.set_slot( slot, { value = { type = "virtual", name = name, quality = "normal" }, min = value } )
            slot = slot + 1
        end
    end
end




-- -------------------------------------------------------------------------------- --
-- Update the custom status area in the vanilla GUI sidebar when mouse-hovering over the control object

function Teleporter.update_custom_status( data )
    if not data then return end
    local entity = data[ TELEPORTER_CONTROLLER ]
    if not( entity and entity.valid )then return end
    
    local charge_level, diode, sprite, remaining = Teleporter_get_status( data )
    
    local signals = Teleporter_get_signals( entity, Teleporter_custom_status_signals )
    
    -- Shown after LED right before nickname
    local protected = signals[ SIGNAL_PROTECTED ] and "[virtual-signal=shield-rings] " or "[virtual-signal=shape-circle] "
    local nickname = Teleporter_get_nickname( data.poskey )
    local pro_name = { "", protected, nickname }
    local label = { "", protected, nickname }
    signals[ SIGNAL_PROTECTED ] = nil
    
    for name, value in pairs( signals ) do
        if value ~= 0 then
            local s = string.format( "\n[virtual-signal=%s] = %d", name, value )
            if name == SIGNAL_TIMER then
                -- If the teleporter has a timer, get the remaining time before another teleport can occur
                local ticks = value * 60
                local remaining = math.max( 0, ( data.last_teleport + ticks ) - game.tick ) / 60
                if remaining > 0 then
                    -- If there is time left, add it to the display
                    s = { "custom.cs_waiting", s, math.floor( remaining + 1.0 ) }
                end
            end
            table_insert( label, s )
        end
    end
    
    entity.custom_status = {
        label = label,          -- Full suite of info on the controller
        diode = diode           -- And it's diode
    }
    
    data.output_port.custom_status = {
        label = pro_name,       -- Name and protected status only on output port
        diode = diode,          -- Also show diode
    }
end




-- -------------------------------------------------------------------------------- --
-- Return all the teleporters excluding the source entity, with optional additional filtering

local function Teleporter_get_teleporters( src_entity, ring_id, exclude_unpowered, exclude_occupied, exclude_protected )
    local teleporters = {}
    
    -- Shortcuts for fewer deferences in the loop
    local power_per_teleport = storage.power_per_teleport
    
    for unit_nr, data in pairs( storage.ring_teleporter_teleporters ) do
        local entity = data[ TELEPORTER_CONTROLLER ]
        if entity ~= src_entity then
            if entity and entity.valid then
                
                if exclude_protected then
                    if not Teleporter_is_friend( src_entity, entity ) and Teleporter_has_protection_signal( entity ) then
                        goto continue
                    end
                end
                
                if ring_id and ring_id ~= Teleporter_get_signal_ring_id( entity ) then
                    goto continue
                end
                
                if exclude_unpowered and entity.energy < power_per_teleport then
                    goto continue
                end
                
                if exclude_occupied and data.occupied ~= OCCUPIED_UNOCCUPIED then
                    goto continue
                end
                
                table_insert( teleporters, data )
            end
            
        end
        
        ::continue::
    end
    
    return teleporters
end

function Teleporter.get_teleporters( entity, ring_id, exclude_unpowered, exclude_occupied, exclude_protected )
    if not( entity and entity.valid )then return end
    return Teleporter_get_teleporters( entity, ring_id, exclude_unpowered, exclude_occupied, exclude_protected )
end




-- -------------------------------------------------------------------------------- --
-- Return a teleporter by a component entity

-- Find a teleporter by it a component id
local function Teleporter_find_by_entity( entity, id )
    for _, data in pairs( storage.ring_teleporter_teleporters )do
        if data[ id ] == entity then
            return data
        end
    end
    return nil
end


-- Find a teleporter by some entity in it's entire makeup
function Teleporter.find_by_entity( entity )
    if not( entity and entity.valid )then return nil end
    
    local e_name = entity.name
    
    -- Teleporters are stored by controller unit number, just look it up
    if e_name == TELEPORTER_CONTROLLER_MK1 then
        return storage.ring_teleporter_teleporters[ entity.unit_number ]
    end
    
    -- Scrape the entire table then...
    for id, component in pairs( Teleporter_component_entity_names ) do
        if e_name == component.name then
            local result = Teleporter_find_by_entity( entity, id )
            if result then
                return result
            end
        end
    end
    
    -- Nothing
    return nil
end




-- -------------------------------------------------------------------------------- --
-- Sort teleporters by force then surface

function Teleporter.sort_teleporters( list, player_force_name )
    if not( list and #list > 0 ) then return end
    if not( player_force_name and player_force_name ~= "" )then end
    
    -- Shortcuts for fewer deferences in the loop
    local u_poskey = Util_poskey
    local t_nicknames = storage.ring_teleporter_nicknames
    
    table.sort( list, function( data_a, data_b )
        
        -- Shortcuts for fewer deferences in the loop
        local a = data_a[ TELEPORTER_CONTROLLER ]
        local b = data_b[ TELEPORTER_CONTROLLER ]
        local a_force = a.force
        local b_force = b.force
        local a_surface = a.surface
        local b_surface = b.surface
        
        -- Check that all required fields exist
        if not ( a and b and a_force and b_force and a_surface and b_surface ) then
            return false
        end
        
        -- Shortcuts for fewer deferences in the loop
        local a_force_name = a_force.name
        local b_force_name = b_force.name
        
        -- Prioritize the player's force
        if a_force_name == player_force_name and b_force_name ~= player_force_name then
            return true
        elseif b_force_name == player_force_name and a_force_name ~= player_force_name then
            return false
        end
        
        -- Sort alphabetically by force name
        if a_force_name ~= b_force_name then
            return a_force_name < b_force_name
        end
        
        -- Shortcuts for fewer deferences in the loop
        local a_surface_planet = a_surface.planet
        local b_surface_planet = b_surface.planet
        
        -- If force names are the same, sort by surface.planet (nil is lower priority)
        if a_surface_planet ~= b_surface_planet then
            if a_surface_planet == nil then
                return false -- a has lower priority
            elseif b_surface_planet == nil then
                return true -- b has lower priority
            else
                return a_surface_planet.prototype.order < b_surface_planet.prototype.order
            end
        end
        
        -- Shortcuts for fewer deferences in the loop
        local a_surface_name = a_surface.name
        local b_surface_name = b_surface.name
        
        -- If planets are the same, sort by surface.name
        if a_surface_name ~= b_surface_name then
            return a_surface_name < b_surface_name
        end
        
        -- If surface names are the same, sort by nickname
        return ( t_nicknames[ u_poskey( a ) ] or 0 ) < ( t_nicknames[ u_poskey( b ) ] or 0 )
    end)
end




-- -------------------------------------------------------------------------------- --
-- Handle the barriers used in the teleportation process


local function Teleporter_create_barrier( data )
    if not data then return end
    if data.aborted then return end
    
    --log( "Teleporter_create_barrier() : " .. Teleporter_get_nickname( data.poskey ) )
    
    local entity = data[ TELEPORTER_CONTROLLER ]
    if not ( entity and entity.valid ) then
        Teleporter.abort_teleport( data )
        return
    end
    
    local p = entity.position
    local surface = entity.surface
    local barriers = {}
    local left = p.x - 6.5
    local right = p.x - 2.5
    local top = p.y - 4.5
    local bottom = p.y - 1.5
    local unit_number = entity.unit_number
    local still_intact = entity.health > 0
    
    local function try_place( x, y )
        if not still_intact then return false end
        
        local pos = { x = x, y = y }
        
        -- Check for collisions and damage objects
        if not surface.can_place_entity{ name = TELEPORTER_BARRIER, position = pos } then
            ring_collision_incident( surface, pos, entity )
            still_intact = entity.health > 0
        end
        
        -- Teleporter destroyed?
        if not still_intact then return false end
        
        -- Try create the barrier for this tile
        local barrier = surface.create_entity{ name = TELEPORTER_BARRIER, position = pos, force = entity.force }
        if barrier and barrier.valid then
            -- Just ignore if the barrier didn't spawn, the teleporter is still intact
            table_insert( barriers, barrier )
            barrier.destructible = false
        end
        
        return true
    end
    
    -- Place top and bottom borders without extending to corners
    for x = left, right do
        if not try_place( x, top - 1 ) then break end       -- Top border
        if not try_place( x, bottom + 1 ) then break end    -- Bottom border
    end
    
    -- Place left and right borders without overlapping the corners
    for y = top, bottom do
        if not try_place( left - 1, y ) then break end      -- Left border
        if not try_place( right + 1, y ) then break end     -- Right border
    end
    
    -- Store the barriers
    data.barriers = barriers
    
    if still_intact then
        -- Hopefully it didn't get destroyed
        
        Util_schedule_after( BARRIER_END_TICKS, DESTROY_BARRIER, { data } )
        
    else
        
        -- Clean up the placed barries
        Teleporter.abort_teleport( data )
        
    end
    
end


local function Teleporter_destroy_barrier( data )
    if not data then return end
    
    --log( "Teleporter_destroy_barrier() : " .. Teleporter_get_nickname( data.poskey ) )
    
    if data.barriers then
        for _, barrier in pairs( data.barriers ) do
            if barrier and barrier.valid then
                barrier.destroy()
            end
        end
        data.barriers = nil
    end
    
end




-- -------------------------------------------------------------------------------- --
-- Handle the animation used in the teleportation process

local function Teleporter_create_animation( data )
    if not data then return end
    if data.aborted then return end
    
    --log( "Teleporter_create_animation() : " .. Teleporter_get_nickname( data.poskey ) )
    
    local renderer = data[ TELEPORTER_SPRITE_NAME ]
    if not ( renderer and renderer.valid ) then
        Teleporter.abort_teleport( data )
        return
    end
    
    local surface = data.surface
    local tick = game.tick
    
    -- Calculate frame offset to get the intended "start on frame 0 on any tick"
    local r = ( ( tick * ANIMATION_SPEED ) % ANIMATION_FRAME_COUNT )
    local animation_offset = r == 0 and 0 or ( ANIMATION_FRAME_COUNT - r )
    
    local function draw_animation( name, layer )
        return rendering.draw_animation{
            animation = name,
            target = {
                entity = renderer,
            },
            surface = surface,
            render_layer = layer,
            animation_offset = animation_offset,
        }
    end
    
    -- Draw the animation sequences
    data.animation1 = draw_animation( TELEPORTER_BACK_MK1 , TELEPORTER_BACK_MK1_LAYER  )
    data.animation2 = draw_animation( TELEPORTER_FRONT_MK1, TELEPORTER_FRONT_MK1_LAYER )
    
    -- Schedule their removal
    Util_schedule_after( ANIMATION_TICKS, DESTROY_ANIMATION, { data } )
end


-- Destroy the animation used in the teleportation process
local function Teleporter_destroy_animation( data )
    if not data then return false end
    
    --log( "Teleporter_destroy_animation() : " .. Teleporter_get_nickname( data.poskey ) )
    
    local function destroy( animation )
        if animation and animation.valid then
            animation.destroy()
        end
    end
    
    destroy( data.animation1 )
    destroy( data.animation2 )
    
    data.animation1 = nil
    data.animation2 = nil
end




-- -------------------------------------------------------------------------------- --
-- Play the animation, schedule the barrier creation and, play a random sound

local function Teleporter_begin_animation_sequence( data )
    if not data then return end
    if data.aborted then return end
    
    local renderer = data[ TELEPORTER_SPRITE_NAME ]
    --log( "Teleporter_begin_animation_sequence() : " .. Teleporter_get_nickname( data.poskey ) .. " " .. ( renderer and tostring( renderer ) or "no renderer???" ) )
    
    if not ( renderer and renderer.valid ) then
        Teleporter.abort_teleport( data )
        return
    end
    
    Teleporter_create_animation( data )
    Util_play_random_sound( renderer, TELEPORTATION_SOUNDS )
    
    Util_schedule_after( BARRIER_START_TICKS, CREATE_BARRIER, { data } )
end




-- -------------------------------------------------------------------------------- --
-- Do the actual entity swap between the teleporters

local function Teleporter_teleport_objects( src, dst )
    if not src then return end
    if src.aborted then return end
    if not dst then return end
    if dst.aborted then return end
    
    local src_entity = src[ TELEPORTER_CONTROLLER ]
    if not ( src_entity and src_entity.valid ) then return end
    
    local dst_entity = dst[ TELEPORTER_CONTROLLER ]
    if not ( dst_entity and dst_entity.valid ) then return end
    
    --log( "Teleporter_teleport_objects()\n\tsrc = " .. Teleporter_get_nickname( src.poskey ) .. "\n\tdst = " .. Teleporter_get_nickname( dst.poskey ) )
    
    local function get_objects( surface, p )
        local area = {
            left_top = { x = p.x - 7, y = p.y - 5 },
            right_bottom = { x = p.x - 2, y = p.y - 0.5 }
        }
        return surface.find_entities_filtered{ area = area }
    end
    
    local src_surface = src.surface
    local src_position = src.position
    
    local dst_surface = dst.surface
    local dst_position = dst.position
    
    local src_objects = get_objects( src_surface, src_position )
    local dst_objects = get_objects( dst_surface, dst_position )
    
    local function swap_a_b( objects, surface, from, to )
        for _, target in ipairs( objects ) do
            if target.valid then
                local relative = Util_get_relative_position( target.position, from )
                Teleporting.ring_teleport( target, surface, Util.add_positions( to, relative ) )
            end
        end
    end
    
    swap_a_b( src_objects, dst_surface, src_position, dst_position )
    swap_a_b( dst_objects, src_surface, dst_position, src_position )
    
end




-- -------------------------------------------------------------------------------- --
-- Finalize and cleanup everything to do with the teleportation, making the teleporters ready for another teleportation

local function Teleporter_teleport_complete( src, dst )
    local tick = game.tick
    
    --log( string.format( "Teleporter_teleport_complete() : %d\n\tsrc = %s\n\tdst = %s", tick, Teleporter_get_nickname( src.poskey ), Teleporter_get_nickname( dst.poskey ) ) )
    
    -- Data may not be valid on entry as though it will have been removed from the core table, it will still exist in the scheduled function parameters
    local function finalize( data )
        local entity = data[ TELEPORTER_CONTROLLER ]
        data.reservedby     = 0
        data.occupied       = OCCUPIED_UNOCCUPIED
        data.last_teleport  = tick
    end
    
    finalize( src )
    finalize( dst )
end




-- -------------------------------------------------------------------------------- --
-- Initiate a teleportation sequence between two teleporters

-- They are not the same and both are unoccupied or they are talking to each other
local function valid_teleport_request( src, dst )
    if src == dst then return false end
    if src.occupied == OCCUPIED_UNOCCUPIED and dst.occupied == OCCUPIED_UNOCCUPIED then return true end
    return ( src.reservedby == dst.unit_number )and( dst.reservedby == src.unit_number )
end


-- Start the actual teleportation sequence between the teleporters
function Teleporter.initiate_teleport( src, dst )
    if not src then return false end
    if not dst then return false end
    
    local function cancel_teleport()
        local function ct( data )
            data.occupied = OCCUPIED_UNOCCUPIED
            data.reservedby = 0
        end
        ct( src )
        ct( dst )
    end
    
    if not valid_teleport_request( src, dst ) then
        cancel_teleport()
        return false
    end
    
    local power_per_teleport = storage.power_per_teleport
    
    local src_entity = src[ TELEPORTER_CONTROLLER ]
    if not ( src_entity and src_entity.valid and src_entity.energy >= power_per_teleport ) then
        cancel_teleport()
        return false
    end

    
    local dst_entity = dst[ TELEPORTER_CONTROLLER ]
    if not ( dst_entity and dst_entity.valid and dst_entity.energy >= power_per_teleport ) then
        cancel_teleport()
        return false
    end

    
    --log( "Teleporter.initiate_teleport()\n\tsrc = " .. Teleporter_get_nickname( src.poskey ) .. "\n\tdst = " .. Teleporter_get_nickname( dst.poskey ) )
    
    src.occupied = OCCUPIED_OUTGOING
    dst.occupied = OCCUPIED_INCOMING
    
    src_entity.energy = src_entity.energy - power_per_teleport
    dst_entity.energy = dst_entity.energy - power_per_teleport
    
    Teleporter_begin_animation_sequence( src )
    Teleporter_begin_animation_sequence( dst )
    
    Util_schedule_after( TELEPORTATION_TICK, TELEPORT_OBJECTS, { src, dst } )
    Util_schedule_after( TELEPORTATION_COMPETE_TICK, TELEPORT_COMPLETE, { src, dst } )
    
    return true
end


-- Reserve each other so other teleporters can't try to teleport to already busy teleporters
local function Teleporter_initiate_teleport( src, dst )
    
    --log( "Teleporter_initiate_teleport()\n\tsrc = " .. Teleporter_get_nickname( src.poskey ) .. "\n\tdst = " .. Teleporter_get_nickname( dst.poskey ) )
    
    local function reserve( data, target, direction )
        data.reservedby = target.unit_number
        data.occupied = direction
    end
    
    reserve( src, dst, OCCUPIED_OUTGOING )
    reserve( dst, src, OCCUPIED_INCOMING )
    
    -- Schedule for the future, after we're done processing the logic on this tick
    Util_schedule_after( NEAR_FUTURE_TICKS, INITIATE_TELEPORT, { src, dst } )
end




-- -------------------------------------------------------------------------------- --
-- Abort a teleport in progress

function Teleporter.abort_teleport( data )
    --log( "Teleporter.abort_teleport() : " .. Teleporter_get_nickname( data.poskey ) .. "\n" .. debug.traceback() )
    data.aborted = true
    Teleporter_destroy_barrier( data )
    Teleporter_destroy_animation( data )
end




-- -------------------------------------------------------------------------------- --
-- Process the logic for teleporter

function Teleporter.update_teleporter( data )
    if not data then return end
    local entity = data[ TELEPORTER_CONTROLLER ]
    if not( entity and entity.valid ) then return end
    
    --log( "Teleporter.update_teleporter() : " .. Teleporter_get_nickname( data.poskey ) )
    
    -- Try to schedule a teleport from circuit signals
    if ( data.occupied == OCCUPIED_UNOCCUPIED )
    and data[ TELEPORTER_CONTROLLER ].energy >= storage.power_per_teleport
    and not Teleporter_is_waiting( data )
    then
        
        -- Get the target ID
        local goto_id = Teleporter_get_signal_goto_id( entity )
        if goto_id and goto_id ~= 0 then
            
            -- Get valid targets this teleporter can access
            local targets = Teleporter_get_teleporters( entity, goto_id, true, true, true )
            
            -- Try all targets at random until we get a successful attempt or run out of targets
            while( #targets > 0 )do
                local index = math_random( #targets )
                local target = targets[ index ]
                
                if not Teleporter_is_waiting( target ) then
                    Teleporter_initiate_teleport( data, target )
                    break   -- Success, break out of targeting loop
                end
                
                -- Remove this target from the candidates
                table_remove( targets, index )
            end
        end
        
    end
    
    -- Update the teleporters output port circuit signals
    Teleporter_update_output_port( data )
end




-- -------------------------------------------------------------------------------- --
-- Create a new Teleporter data block from either TELEPORTER_CONTROLLER_MK1 or TELEPORTER_PLACER_MK1

function Teleporter.new( entity )
    --log( "Teleporter.new() : " .. tostring( entity.valid ) .. " " .. entity.name .. " " .. Teleporter.get_nickname( entity ) )
    --log( "Teleporter.new() : " .. entity.name .. " " .. ( ( entity.name == ENTITY_GHOST ) and entity.ghost_name or "" ) )
    
    if not ( entity and entity.valid ) then return nil end
    local e_name = entity.name
    if not ( ( e_name == TELEPORTER_CONTROLLER_MK1 )
    or ( e_name == TELEPORTER_PLACER_MK1 ) ) then return nil end
    
    
    local surface = entity.surface
    local create_entity = surface.create_entity
    local pos = entity.position
    local force = entity.force
    local poskey = Util_poskey( entity )
    local quality = entity.quality or "normal"
    
    
    -- Destroy the placer entity
    if e_name == TELEPORTER_PLACER_MK1 then
        entity.destroy()
    end
    
    
    -- Encapsulate all data into one table entry
    local data = {
        --entity = nil,         -- For reference
        --renderer = nil,       -- For reference
        --output = nil,         -- For reference
        --station = nil,        -- For reference
        
        --unit_number = 0,      -- For reference
        poskey = poskey,
        
        surface = surface,
        --position = pos,       -- For reference
        
        reservedby = 0,         -- Set by automatic teleports as they don't start until the next tick (so all logic for the tick can complete first)
        occupied = OCCUPIED_UNOCCUPIED,
        last_teleport = 0,
        aborted = false,
        
        --animation1 = nil,     -- For reference
        --animation2 = nil,     -- For reference
        --barriers = nil,       -- For reference
    }
    
    
    -- Find or create a specific entity
    local function find_or_create( position, name, offset, has_quality )
        local x, y = position.x + offset.x, position.y + offset.y
        local area = { { x - SCAN_AREA, y - SCAN_AREA }, { x + SCAN_AREA, y + SCAN_AREA } }
        
        local function find_entity_near()
            
            -- First try to find a spawned entity
            local entities = surface.find_entities_filtered{
                name = name,
                area = area
            }
            if #entities > 0 then
                --log( "\tfound entity: " .. name .. " " .. entities[ 1 ].name )
                return entities[ 1 ]
            end
            
            -- Next try to find a ghost entity
            entities = surface.find_entities_filtered{
                name = ENTITY_GHOST,
                ghost_name = name,
                area = area
            }
            if #entities > 0 then
                --log( "\tfound ghost: " .. name .. " " .. entities[ 1 ].name )
                return entities[ 1 ]
            end
            
            return nil
        end
        
        local result = find_entity_near()
        if result and result.name == ENTITY_GHOST then -- Found a ghost
            --log( "\treviving ghost: " .. name .. " " .. result.name )
            result.silent_revive{ raise_revive = false }
            result = find_entity_near()
        end
        
        if not result then
            result = create_entity{
                name = name,
                position = { x = x, y = y },
                force = force,
                raise_built = false,
                create_build_effect_smoke = false,
                quality = has_quality and quality or "normal",
            }
            --log( "\tcreated entity: " .. name .. " " .. result.name )
        end
        
        return result
    end
    
    
    -- Find or create all entities
    for id, component in pairs( Teleporter_component_entity_names )do
        if component.make then
            --log( "find_or_create() " .. id .. " " .. component.name )
            local cd = find_or_create( pos, component.name, component.offset, component.has_quality )
            if component.protected then
                cd.destructible = false
                cd.minable = false
            end
            data[ id ] = cd
        end
    end
    
    
    -- Set the final data in the set
    local unit_number = data[ TELEPORTER_CONTROLLER ].unit_number
    data.unit_number = unit_number
    data.position = data[ TELEPORTER_CONTROLLER ].position
    
    
    -- Pull nickname from global table stored by position (for destroyed/blueprinted entities) or a random backer bame from the game
    -- Blueprints should have set the global for this poskey during the blueprint placement
    local nickname = storage.ring_teleporter_nicknames[ poskey ]
    nickname = ( nickname and nickname ~= "" ) and nickname or Util_backername()
    
    
    -- Update the station name regardless of source
    data[ TELEPORTER_SPRITE_NAME ].backer_name = "[item=ring-teleporter] " .. nickname
    --data[ TELEPORTER_SPRITE_NAME ].backer_name = nickname
    
    
    -- Store data in global tables
    storage.ring_teleporter_nicknames[ poskey ] = nickname
    storage.ring_teleporter_teleporters[ unit_number ] = data
    
    
    --[[
    local s = "\nsetup teleporter: " .. Teleporter_get_nickname( data.poskey )
    for k, v in pairs( data ) do
        s = s .. "\n\t" .. tostring( k ) .. " = (" .. type( v ) .. ") " .. tostring( v )
    end
    log( s )
    --]]
    
    
    -- Return data
    return data, nickname
end




-- -------------------------------------------------------------------------------- --
-- Remove a Teleporter data block from the internal data table, optionally also scrub the name from the name table (default: true)

function Teleporter.remove( entity, scrub_name )
    if not ( entity and entity.valid ) then return end
    --log( "Teleporter.remove() : " .. entity.name .. " " .. ( ( entity.name == ENTITY_GHOST ) and entity.ghost_name or "" ) )
    
    if not( entity.name == TELEPORTER_CONTROLLER_MK1 ) then return end
    
    local unit_number = entity.unit_number
    local poskey = Util_poskey( entity )
    
    
    -- Do a full scrub of the area to be sure nothing is left behind
    -- Also, covers cases of no data for a teleporter entity (ie, ghost is removed)
    do
        
        local find_entities_filtered = entity.surface.find_entities_filtered
        local pos = entity.position
        
        -- Find and destroy orphaned or ghost remnants
        local function find_and_destroy( position, name, offset )
            local x, y = position.x + offset.x, position.y + offset.y
            local area = { { x - SCAN_AREA, y - SCAN_AREA }, { x + SCAN_AREA, y + SCAN_AREA } }
            
            -- Destroy spawned entities
            for _, e in pairs( find_entities_filtered{
                name = name,
                area = area
            } or {} )do
                if e.valid then
                    e.destroy()
                end
            end
            
            -- Destroy ghost entities
            for _, e in pairs( find_entities_filtered{
                name = ENTITY_GHOST,
                ghost_name = name,
                area = area
            } or {} ) do
                if e.valid then
                    e.destroy()
                end
            end
            
        end
        
        -- Clean up all orphans
        for id, component in pairs( Teleporter_component_entity_names )do
            find_and_destroy( pos, component.name, component.offset )
        end
        
    end
    
    
    -- Purge the teleporter data from the table
    local data = storage.ring_teleporter_teleporters[ unit_number ]
    if data then
        
        local function tryDestroy( o ) -- o can be an entity or an animation
            if o and o.valid then
                o.destroy()
            end
        end
        
        tryDestroy( data.animation1 )
        tryDestroy( data.animation2 )
        
        if data.barriers then
            for _, barrier in pairs( data.barriers ) do
                tryDestroy( barrier )
            end
        end
        
        -- Clear all entities
        for id, _ in pairs( Teleporter_component_entity_names ) do
            tryDestroy( data[ id ] )
            data[ id ] = nil
        end
        
        -- Force-clear object references, let Lua gc handle simple types;
        -- Also, data may be held as a scheduled function parameter and the immediate data needs to be preserved until they are complete
        
        data.surface = nil
        data.position = nil
        
        data.animation1 = nil
        data.animation2 = nil
        data.barriers = nil
        
        storage.ring_teleporter_teleporters[ unit_number ] = nil
        
    end
    
    
    -- Remove the nickname from the database if requested
    if scrub_name == nil then scrub_name = true end
    if scrub_name then
        storage.ring_teleporter_nicknames[ poskey ] = nil
    end
    
end




-- -------------------------------------------------------------------------------- --
-- Migration/emergency repair tool - clean out all possible orphaned entities and rebuild every teleporter

function Teleporter.rebuild_data()
    
    storage.ring_teleporter_scheduled_functions = {}                                -- Nothing you were going to do was important
    
    storage.ring_teleporter_teleporters = {}                                        -- Will rebuild the table of teleporters in a moment
    storage.ring_teleporter_nicknames = storage.ring_teleporter_nicknames or {}     -- Maintain existing nicknames stored by poskey
    
    storage.ring_teleporter_barriers = nil                                          -- Obsolete
    storage.power_cost_multiplier = nil                                             -- Obsolete
    
    -- Scour all surfaces
    for _, surface in pairs( game.surfaces ) do
        
        local find_entities_filtered = surface.find_entities_filtered
        
        -- Clean up all obsolete entities
        for _, name in pairs( Teleporter_obsolete_entities ) do
            local entities = find_entities_filtered{ name = name }
            for _, entity in pairs( entities ) do
                entity.destroy()
            end
        end
        
        -- Look for component entities of teleporters that somehow didn't get cleaned up
        for id, component in pairs( Teleporter_component_entity_names ) do
            if component.can_be_orphaned then
                --log( string.format( "orphans of : %s", id ) )
                local offset = component.offset
                
                -- Try to find the base object or the placement object near this component entity
                local function found_near( entity )
                    local pos = entity.position
                    local x, y = pos.x - offset.x, pos.y - offset.y
                    local area = { { x - SCAN_AREA, y - SCAN_AREA }, { x + SCAN_AREA, y + SCAN_AREA } }
                    
                    local function found_it( name, ghost_name )
                        local entities = find_entities_filtered{
                            name = name,
                            ghost_name = ghost_name,
                            area = area
                        }
                        return entities and #entities > 0
                    end
                    
                    return found_it( TELEPORTER_CONTROLLER_MK1 )
                        or found_it( TELEPORTER_PLACER_MK1 )
                        or found_it( ENTITY_GHOST, TELEPORTER_CONTROLLER_MK1 )
                        or found_it( ENTITY_GHOST, TELEPORTER_PLACER_MK1 )
                    
                end
                
                -- Process them
                local function process_entities( entities )
                    for _, entity in pairs( entities ) do
                        local orphaned = not found_near( entity )
                        --log( string.format( "\torphaned? %s : %s : %s", tostring( orphaned ), Util.poskey( entity ), ( ( entity.name == ENTITY_GHOST ) and ( entity.name .. " -> " .. entity.ghost_name ) or entity.name ) ) )
                        
                        -- If it's not found near a base object or placement object or a ghost of either, destroy it
                        if orphaned then
                            entity.destroy()
                        end
                    end
                end
                
                -- Process all the component entities on the surface
                process_entities( find_entities_filtered{ name = component.name } )
                process_entities( find_entities_filtered{ name = ENTITY_GHOST, ghost_name = component.name } )
                
            end
        end
        
        -- Rebuild teleporter table
        local entities = surface.find_entities_filtered{ name = TELEPORTER_CONTROLLER_MK1 }
        for _, entity in pairs( entities ) do
            --log( "Teleporter.rebuild_data() : " .. Teleporter.get_nickname( entity ) )
            Teleporter.new( entity )
        end
        
    end
    
end




-- -------------------------------------------------------------------------------- --
-- Event handling


-- Don't listen for everything
local build_event_filter = {
    { filter = "name", name = TELEPORTER_PLACER_MK1 },
    { filter = "ghost_name", name = TELEPORTER_PLACER_MK1 },
    { filter = "ghost_name", name = TELEPORTER_CONTROLLER_MK1 },
    { filter = "ghost_name", name = TELEPORTER_SPRITE_NAME_MK1 },
}
local remove_event_filter = {
    { filter = "name", name = TELEPORTER_CONTROLLER_MK1 },
}


-- Strip the teleporter icon prefix from the train stop name in the blueprint
-- Clear signals on teleporter output port
local function on_player_setup_blueprint( event )
    local player = game.players[ event.player_index ]
    local blueprint = event.stack
    if not blueprint or not blueprint.is_blueprint or not blueprint.valid_for_read then
        return
    end
    
    local bp_ents = blueprint.get_blueprint_entities()
    local src_ents = event.mapping.get()
    
    local modified = false
    
    if bp_ents and src_ents then
        for i, bp_ent in ipairs( bp_ents ) do
            
            local src_ent = src_ents[ i ]
            
            -- Fix name parameter
            if bp_ent.name == TELEPORTER_SPRITE_NAME_MK1 then
                
                local data = Teleporter_find_by_entity( src_ent, TELEPORTER_SPRITE_NAME )
                
                if data then
                    local nickname = Teleporter_get_nickname( data.poskey )
                    --log( "on_player_setup_blueprint() - recording nickname as '" .. nickname .. "'" )
                    bp_ent.station = nickname
                    modified = true
                end
                
            end
            
            -- Clear output port circuit signals (invalid in a blueprint)
            if bp_ent.name == TELEPORTER_OUTPUT_PORT_MK1 then
                
                if bp_ent.control_behavior then
                    bp_ent.control_behavior.sections = nil
                    modified = true
                end
                
            end
            
        end
    end
    
    if modified then
        blueprint.set_blueprint_entities( bp_ents )
    end
end


-- Something placed a teleporter controller or the placer entity
local function on_built( event )
    local entity = event.entity
    local e_name = entity.name
    local player_index = event.player_index
    local player = player_index and game.players[ player_index ]
    --log( "on_built() : " .. entity.name .. " " .. ( ( entity.name == ENTITY_GHOST ) and entity.ghost_name or "" ) )
    
    
    -- Look for another teleporter that would overlap
    local function check_overlap( entity )
        local unit_number = entity.unit_number
        local x, y = entity.position.x, entity.position.y
        local area = { { x - 9.0, y - 6.0 }, { x + 9.0, y + 7.0 } }     -- Our entire area plus any area of another teleporter to the right and/or below this one
        
        local function found_it( name, ghost_name )
            local entities = entity.surface.find_entities_filtered{
                name = name,
                ghost_name = ghost_name,
                area = area
            }
            if not ( entities and #entities > 0 ) then
                return false
            end
            for _, e in pairs( entities ) do
                if e.unit_number ~= unit_number then    -- Don't detect as colliding with itself
                    --log( "unit: " .. tostring( unit_number ) .." collided with: " ..tostring( e.unit_number ) .. " " .. name .. " " .. ( ghost_name and ghost_name or "" ) )
                    return true
                end
            end
            return false
        end
        
        return found_it( TELEPORTER_CONTROLLER_MK1 )                    -- Overlap with a placed controller
            or found_it( TELEPORTER_PLACER_MK1 )                        -- And a placed placer (should never happen)
            or found_it( ENTITY_GHOST, TELEPORTER_PLACER_MK1 )          -- Or a ghost placer
            --or found_it( ENTITY_GHOST, TELEPORTER_CONTROLLER_MK1 )    -- But not a ghost controller
    end
    
    
    -- Look for component ghosts where this [ghost] entity was placed and remove them
    local function clean_mess_near( entity )
        local find_entities_filtered = entity.surface.find_entities_filtered
        local pos = entity.position
        
        -- Remove component ghosts
        for id, component in pairs( Teleporter_component_entity_names ) do
            local offset = component.offset
            
            local x, y = pos.x + offset.x, pos.y + offset.y
            local area = { { x - SCAN_AREA, y - SCAN_AREA }, { x + SCAN_AREA, y + SCAN_AREA } }
            
            local entities = find_entities_filtered{
                name = ENTITY_GHOST,
                ghost_name = component.name,
                area = area
            } or {}
            
            for _, e in pairs( entities ) do
                e.destroy()
            end
            
        end
        
        -- And destroy the bad entity itself
        entity.destroy()
    end
    
    
    if entity.name == ENTITY_GHOST then
        
        
        if entity.ghost_name == TELEPORTER_PLACER_MK1 then
            
            -- Check if this placer would collide with another teleporter
            if check_overlap( entity ) then
                entity.destroy()   -- Just destroy this one, the other one was here first
            end
            
            return
        end
        
        
        if entity.ghost_name == TELEPORTER_CONTROLLER_MK1 then
            -- This case will only happen via blueprints
            
            -- Check if this controller would collide with another teleporter
            if check_overlap( entity ) then
                clean_mess_near( entity )   -- Can only be placed by blueprint, meaning the rest of the components are misplaced too
                return
            end
            
            -- Spawn a placer ghost so robots can deliver the teleporter
            local placer = entity.surface.create_entity{
                name = ENTITY_GHOST,
                ghost_name = TELEPORTER_PLACER_MK1,
                position = entity.position,
                raise_built = false,
                force = entity.force,
                ghost = true,
                create_build_effect_smoke = true,
                quality = entity.quality,
            }
            
            return
        end
        
        
        -- Read the nickname from a blueprinted teleporter
        if entity.ghost_name == TELEPORTER_SPRITE_NAME_MK1 then
            
            local nickname = entity.backer_name
            local poskey = Util_poskey( entity )
            --log( "on_built() - setting nickname at " .. poskey .. " to '" .. nickname .. "'" )
            storage.ring_teleporter_nicknames[ poskey ] = nickname
            
            return
        end
        
        
    elseif e_name == TELEPORTER_PLACER_MK1 then
        
        if check_overlap( entity ) then
            
            -- Return item stack
            local stack = {
                name = TELEPORTER_PLACER_ITEM_MK1,
                count = 1,
                quality = entity.quality,
            }
            
            local spill = true  -- Default for robots, player will be given back directly (unless inventory is full)
            
            if player then -- Give it right back to the player that built it
                local remainder = stack.count - player.insert( stack )
                spill = remainder > 0 -- No room?  Fast logistics!  Spill it on the floor then.
                stack.count = remainder
            end
            
            if spill then -- Spawn the [remaining] item[s] on the ground
                local item = entity.surface.spill_item_stack{
                    position = entity.position,
                    stack = stack,
                    enable_looted = true,
                }
                item.to_be_looted = true
            end
            
            clean_mess_near( entity )   -- Would overlap with an existing teleporter/ghost
            
            return
        end
        
        
        -- Try create the teleporter
        Teleporter.new( event.entity )
        
    end
end


-- Remove the Teleporter and scrub it's name from the database
local function on_entity_removed_clean( event )
    Teleporter.remove( event.entity, true )
end


-- Remove the Teleporter and DO NOT scrub it's name from the database
local function on_entity_removed_dirty( event )
    Teleporter.remove( event.entity, false )
end


-- Player is trying to copy-paste the nickname between Teleporters
local function on_entity_settings_pasted( event )
    
    local src = Teleporter.find_by_entity( event.source )
    if not src then return end
    
    local dst = Teleporter.find_by_entity( event.destination )
    if not dst then return end
    
    -- Can only copy-paste nicknames between ring teleporters, all other settings are set via circuits
    Teleporter_set_nickname( dst, Teleporter_get_nickname( src.poskey ) )
    
end


-- Picker Dollies support (blacklist)
local function init_PickerDollies()
    if remote.interfaces[ "PickerDollies" ] and remote.interfaces[ "PickerDollies" ][ "add_blacklist_name" ] then
        
        local function blacklist( name )
            remote.call( "PickerDollies", "add_blacklist_name", name )
        end
        
        -- No way to signal to Picker Dollies "not right now" and it provides no public API to
        -- make use of it's functions to do the work of moving all the component entities,
        -- So instead we'll just blacklist everything from being moved.
        blacklist( TELEPORTER_PLACER_MK1 )
        blacklist( TELEPORTER_CONTROLLER_MK1 )
        blacklist( TELEPORTER_SPRITE_NAME_MK1 )
        blacklist( TELEPORTER_OUTPUT_PORT_MK1 )
        blacklist( TELEPORTER_BARRIER )
        
    end
    
end




-- -------------------------------------------------------------------------------- --
-- Setup the event handling and other low-level requirements prior to init() and load()

function Teleporter.bootstrap()
    
    -- Blueprinting
    script.on_event( defines.events.on_player_setup_blueprint, on_player_setup_blueprint )
    script.on_event( defines.events.on_pre_build, on_pre_build )
    
    -- Entity Built
    script.on_event( defines.events.on_built_entity, on_built, build_event_filter )
    script.on_event( defines.events.on_robot_built_entity, on_built, build_event_filter )
    script.on_event( defines.events.on_space_platform_built_entity, on_built, build_event_filter )
    
    -- Entity Removed
    script.on_event( defines.events.on_player_mined_entity, on_entity_removed_clean, remove_event_filter )
    script.on_event( defines.events.on_robot_mined_entity, on_entity_removed_clean, remove_event_filter )
    script.on_event( defines.events.on_space_platform_pre_mined, on_entity_removed_clean, remove_event_filter )
    script.on_event( defines.events.on_entity_died, on_entity_removed_dirty, remove_event_filter )
    
    -- Entity settings copy-paste
    script.on_event( defines.events.on_entity_settings_pasted, on_entity_settings_pasted )
    
end




-- -------------------------------------------------------------------------------- --
-- Setup the game data

function Teleporter.init()
    storage.ring_teleporter_scheduled_functions = {}
    storage.ring_teleporter_teleporters         = {}
    storage.ring_teleporter_nicknames           = {}    -- Still used for rebuilt ghosts and blueprints
    
    --storage.ring_teleporter_barriers          = {}    -- Obsolete
    
    storage.power_per_teleport                  = Util.power_per_teleport()
    
    init_PickerDollies()
end




-- -------------------------------------------------------------------------------- --
-- Load event

function Teleporter.load()
    init_PickerDollies()
end




-- -------------------------------------------------------------------------------- --
-- Map functions that can be scheduled.

Util.map_functions{
    [ INITIATE_TELEPORT ]       = Teleporter.initiate_teleport,     -- Note:  This is NOT the internal function, the internal function schedules a public API call
    [ CREATE_BARRIER ]          = Teleporter_create_barrier,
    [ DESTROY_BARRIER ]         = Teleporter_destroy_barrier,
    [ DESTROY_ANIMATION ]       = Teleporter_destroy_animation,
    [ TELEPORT_OBJECTS ]        = Teleporter_teleport_objects,
    [ TELEPORT_COMPLETE ]       = Teleporter_teleport_complete,
}




-- -------------------------------------------------------------------------------- --
return Teleporter