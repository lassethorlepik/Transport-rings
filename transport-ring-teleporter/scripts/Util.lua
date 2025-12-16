local Util = {}

local Util_function_map = {}


-- Maps a function id to it's function for scheduled function calls
function Util.map_function( func_id, func )
    Util_function_map[ func_id ] = func
end

function Util.map_functions( function_map )
    for func_id, func in pairs( function_map )do
        Util_function_map[ func_id ] = func
    end
end

function Util.add_positions( pos1, pos2 )
    return {
        x = pos1.x + pos2.x,
        y = pos1.y + pos2.y
    }
end

function Util.distance( pos1, pos2 )
    -- Optimized from three exponents to one, ofc Lua is the real bottleneck but shh!
    local dx = ( pos1.x - pos2.x )
    local dy = ( pos1.y - pos2.y )
    return ( ( dx * dx ) + ( dy * dy ) ) ^ 0.5
end

function Util.get_relative_position( pos_a, pos_b )
    if not ( pos_a and pos_b ) then
        return nil
    end
    -- Return the calculated relative position as a table
    return {
        x = pos_a.x - pos_b.x,
        y = pos_a.y - pos_b.y
    }
end

function Util.can_vanilla_teleport( entity )
    if entity.type == "character" then
        return true
    elseif entity.type == "car" then
        return true
    elseif entity.type == "spider-vehicle" then
        return true
    end
    return false
end


function Util.play_random_sound( entity, sounds )
    if not( entity and entity.valid ) then return end
    local random_index = math.random( #sounds )
    local selected_sound = sounds[ random_index ]
    entity.surface.play_sound{
        path = selected_sound,
        position = entity.position
    }
end

-- Every scheduled function call first needs to be mapped for serialization
function Util.schedule_after( delay_ticks, func_id, params, onlyone )
    if delay_ticks <= 0 then
        Util.Execute( func_id, params )
        return
    end
    -- Calculate the target tick when the function should be executed
    local target_tick = game.tick + delay_ticks
    -- Should this function only be scheduled once for a given tick?
    if onlyone then
        for _, sched in pairs( storage.ring_teleporter_scheduled_functions )do
            if sched.tick == target_tick and sched.func_id == func_id then
                -- Already found matching scheduled function call on this tick, don't schedule it twice
                return
            end
        end
    end
    -- Insert the scheduled function into the table
    table.insert( storage.ring_teleporter_scheduled_functions, { tick = target_tick, func_id = func_id, params = params } )
end

-- Execute a function based on id
function Util.Execute( func_id, params )
    local func = Util_function_map[ func_id ]
    if not func then
        --log( "Attempted to execute an unmapped function: " .. func_id )
        return
    end
    --log( "Execute: " .. func_id .. ", params: " .. tostring( params ) )
    if params == nil then
        func()
    else
        func( table.unpack( params ) )
    end
end


-- Process scheduled functions
function Util.process_scheduled_functions( tick )
    -- Iterate through the scheduled_functions table in reverse
    for i = #storage.ring_teleporter_scheduled_functions, 1, -1 do
        local scheduled = storage.ring_teleporter_scheduled_functions[ i ]
        if tick >= scheduled.tick then
            -- Execute the function
            Util.Execute( scheduled.func_id, scheduled.params )
            -- Remove the executed function from the table
            table.remove( storage.ring_teleporter_scheduled_functions, i )
        end
    end
end


-- Interleaved function call
function Util.interleave_function( interval, tick, unique_id, func, param )
    local hash = ( unique_id + tick ) % interval
    if hash ~= 0 then return end
    func( param )
end



-- Set these tables up once on start instead of every function call
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

-- Return power as a string
function Util.format_power_string( value, unit_type, space )
    local units = unit_type == "W" and power_units or energy_units
    local abs_value = math.abs( value )
    for _, unit_info in ipairs( units ) do
        if abs_value >= unit_info.threshold then
            local scaled_value = value * unit_info.factor
            local formatted_value = string.format( "%.2f", scaled_value )
            -- Remove trailing zeros and possible trailing decimal point
            formatted_value = formatted_value:gsub( "(%d)%.?0*$", "%1" )
            return formatted_value .. space .. unit_info.unit
        end
    end
end

-- Get unique identifier based on location and surface
function Util.poskey( entity )
    local pos = entity.position
    return pos.x .. ";" .. pos.y .. ";" .. entity.surface.name
end

function Util.backername()
    local result = game.backer_names[ math.random( #game.backer_names ) ]
    return result
end

function Util.power_per_teleport()
    return settings.startup[ "trt-power-multiplier" ].value * 1000000000
end

function Util.power_buffer()
    return math.max( Util.power_per_teleport(), settings.startup[ "trt-buffer-multiplier" ].value * 2000000000 )
end

return Util