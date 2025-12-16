local Util = require( "scripts/Util" )
local Teleporter = require( "scripts/Teleporter" )
local GUI = require( "scripts/GUI" )




-- Avoid any issues with references becoming invalid
local function remap_teleporters()
    log( "Starting migration." )
    
    -- Force all guis to close
    GUI.close_all_windows()
    
    -- Rebuild the teleporter data
    Teleporter.rebuild_data()
    
    log( "Migration complete." )
end




script.on_init( function()
    Teleporter.init()
    GUI.init()
end )


script.on_load( function()
    Teleporter.load()
    GUI.load()
end )




script.on_configuration_changed( function()
    remap_teleporters()
    storage.power_per_teleport = Util.power_per_teleport()
end )






-- Shortcuts for less derefs
local Teleporter_update_teleporter = Teleporter.update_teleporter
local GUI_update_window = GUI.update_window
local Teleporter_update_custom_status = Teleporter.update_custom_status
local Util_process_scheduled_functions = Util.process_scheduled_functions
local Util_interleave_function = Util.interleave_function

local ENTITY_GHOST = "entity-ghost"




-- Player mouse-over entity - set custom status update entity
local Selected_Teleporter_Data = nil

script.on_event( defines.events.on_selected_entity_changed, function( event )
    local player = game.players[ event.player_index ]
    local entity = player.selected
    
    Selected_Teleporter_Data = nil  -- Stop updating
    
    if entity and not entity.name == ENTITY_GHOST then
        local data = Teleporter.find_by_entity( entity )
        if data then
            Selected_Teleporter_Data = data -- Begin updating
        end
    end
    
end )




-- Function interleave ticks
local INTERVAL_LOGIC = 30
local INTERVAL_CUSTOM_STATUS = 5
local INTERVAL_GUI = 30




-- Interleave our logic instead of batching every 30 ticks
-- This gets rid of the 30 tick jitters with no measurable UPS loss for overhead
script.on_event( defines.events.on_tick, function( event )
    local tick = event.tick
    
    
    -- Scheduled functions
    Util_process_scheduled_functions( tick )
    
    
    -- Teleporter logic
    for _, data in pairs( storage.ring_teleporter_teleporters ) do
        Util_interleave_function( INTERVAL_LOGIC, tick, data.unit_number, Teleporter_update_teleporter, data )
    end
    
    
    -- Teleporter custom status
    if ( tick % INTERVAL_CUSTOM_STATUS ) == 0 and Selected_Teleporter_Data then
        Util_interleave_function( Selected_Teleporter_Data )
    end
    
    
    -- GUI updates
    for _, data in pairs( storage.ring_teleporter_GUIs ) do
        Util_interleave_function( INTERVAL_GUI, tick, data.player_index, GUI_update_window, data )
    end
    
end )




-- Same speed as above, but this method will cause 30 tick jitters when the number of teleporters grows larger in megabases.
--[[
-- Scheduled functions
script.on_event(defines.events.on_tick, function( event )
    Util.process_scheduled_functions( event.tick )
end)

script.on_nth_tick( 30, function( event )
    -- Teleporter logic
    for _, data in pairs( storage.ring_teleporter_teleporters ) do
        Teleporter_update_teleporter( data )
    end
    
    -- Teleporter custom status
    if Selected_Teleporter_Data then
        Teleporter_update_custom_status( Selected_Teleporter_Data )
    end
    
    -- GUI updates
    for _, data in pairs( storage.ring_teleporter_GUIs ) do
        GUI_update_window( data )
    end
end )
]]




-- Let the sub-systems hook their events
Teleporter.bootstrap()
GUI.bootstrap()




-- Connect the emergency fix command
commands.add_command(
    "ring-remap",
    "Run this if you encounter bugs releated to transport rings, it may fix some.",

    function(command)
        -- Get the player who executed the command
        local player = game.players[ command.player_index ]
        -- Check if the player is an admin
        if player and player.admin then
            log( "Player triggered remap!" )
            remap_teleporters()
            player.print( "Remap complete." )
        else
            player.print( "You do not have admin permissions in this game." )
        end
    end
)



