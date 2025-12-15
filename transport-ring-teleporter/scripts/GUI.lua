local Util = require( "scripts/Util" )
local Teleporter = require( "scripts/Teleporter" )




-- Local deference shortcut
local DIODE_RED = defines.entity_status_diode.red
local DIODE_YELLOW = defines.entity_status_diode.yellow
local DIODE_GREEN = defines.entity_status_diode.green




-- Teleporter constants
local OCCUPIED_UNOCCUPIED = Teleporter.OCCUPIED_UNOCCUPIED
local OCCUPIED_OUTGOING = Teleporter.OCCUPIED_OUTGOING
local OCCUPIED_INCOMING = Teleporter.OCCUPIED_INCOMING

local TELEPORTER_CONTROLLER = Teleporter.CONTROLLER


-- IDs of scheduled functions

local GUI_OPEN_WINDOW = "gui_open_window"


-- Name of GUI elements
local GUI_BASE = "teleporter_gui"
local GUI_EXPAND_BUTTON = "teleporter_expand_button"
local GUI_CLOSE_BUTTON = "teleporter_close_button"
local GUI_HEADER_PANE = "header_pane"
local GUI_HEADER_TABLE = "header_table"
local GUI_TELEPORTER_PANE = "teleporter_pane"
local GUI_TELEPORTER_TABLE = "teleporter_table"


local teleporter_table_desc = {}


-- GUI Columns, tables and cell styles are automatically created and applied from this table
local COL_LOCATION = 1
local COL_ID = 2
local COL_TARGET = 3
local COL_TIMER = 4
local COL_SHIELD = 5
local COL_NICKNAME = 6
local COL_FORCE = 7
local COL_CHARGE = 8
local COL_LED = 9
local COL_USER_ACTION = 10

local COL_LAST = COL_USER_ACTION

local SRC_TELEPORTER_DATA_INDEX = -1




-- Instead of setting up a metatable, just setup a couple common stubs and specifically set them in the table definition
local function empty_element( parent, player ) return parent.add{ type = "flow", direction = "horizontal" } end
local function empty_update( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready ) end

local function make_action_button_caption( diode, occupied, entity, data_index )
    
    if occupied == OCCUPIED_OUTGOING then
        return { "custom.sending" }
    
    elseif occupied == OCCUPIED_INCOMING then
        return { "custom.receiving" }
    
    elseif diode == DIODE_RED then
        return { "custom.low-power" }
    
    elseif diode == DIODE_YELLOW then
        local timer = Teleporter.get_time_remaining( entity )
        if timer > 0 then
            return { "custom.waiting", math.floor( timer + 1.0 ) }
        end
    
    end
    
    if data_index == SRC_TELEPORTER_DATA_INDEX then
        return { "custom.open-teleporter" }
    end
    
    return { "custom.teleport" }
end


local teleporter_table_desc = {
    
    
    -- COL_LOCATION: Teleporter Location
    [ COL_LOCATION ] = { advanced = false, caption = { "custom.position" }, style = { width = 150, horizontal_align = "left" },
        make_filter = function( parent, player )
            local items = {}
            local count = 1
            local tags = {}
            items[ count ] = { "", "[virtual-signal=signal-anything] ", { "custom.any" } }
            tags[ count ] = ""
            
            -- Planets first
            for _, p in pairs( game.planets ) do
                count = count + 1
                items[ count ] = string.format( "[planet=%s] %s", p.name, p.name )
                tags[ count ] = p.name
            end
            
            -- Then space platforms
            for _, p in pairs( game.surfaces ) do
                if p.platform then
                    count = count + 1
                    items[ count ] = string.format( "[img=item.space-platform-hub] %s", p.platform.name )
                    tags[ count ] = p.platform.name
                end
            end
            
            -- Create filter dropdown element
            return parent.add{
                type = "drop-down",
                items = items,
                tags = { surfaces = tags },
                selected_index = 1,
            }
        end,
        update = empty_update,  -- Should? remain static unless destroyed.  If destroyed the entire row will be hidden anyway.
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local position = entity.position
            local surface = entity.surface
            
            local icon
            local sname = surface.name                              -- Surface name, unaltered for tags
            
            -- Create the GPS tag
            local gps_tag = string.format("[gps=%d,%d,%s]", math.floor(position.x + 0.5), math.floor(position.y + 0.5), sname)
            
            local planet = surface.planet
            local platform = surface.platform
            
            if planet then
                sname = planet.name                                 -- Use planet name
                icon = string.format("[planet=%s] ", sname)
            elseif platform then
                sname = platform.name                               -- Use platform name
                icon = "[img=item.space-platform-hub] "
            else
                icon = gps_tag .. " "
            end
            
            local dname = sname                                     -- Display name is surface name, may be altered
            
            if #dname > 14 then
                dname = string.sub(dname, 1, 14) .. "..."
            end
            
            -- Create the element
            local element = parent.add{
                type = "button",
                caption = icon .. dname,                            -- [Altered] Display name
                tags = {
                    gps_tag = gps_tag,
                    surface = sname,                                -- Unaltered Surface name
                },
            }
            
            return element
        end,
    },
    
    -- COL_ID: Teleporter ID
    [ COL_ID ] = { advanced = true, caption = { "", "[virtual-signal=ring-id]" }, style = { width = 100, horizontal_align = "right" },
        make_filter = function( parent, player )
            return parent.add{
                type = "textfield",
                text = "",
                numeric = true,
                allow_negative = true,
                tags = { txtfield_type = "telep-filter_id" }
            }
        end,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local id = Teleporter.get_signal_ring_id( entity )
            
            if id then
                element.caption = tostring( id )
                element.tags = { id = id }
            else
                element.caption = ""
                element.tags = { id = 0 }
            end
            
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "label"
            }
        end,
    },
    
    -- COL_TARGET: Teleporter Target
    [ COL_TARGET ] = { advanced = true, caption = { "", "[virtual-signal=goto-ring-id]" }, style = { width = 100, horizontal_align = "right" },
        make_filter = function( parent, player )
            return parent.add{
                type = "textfield",
                text = "",
                numeric = true,
                allow_negative = true,
                tags = { txtfield_type = "telep-filter_target" }
            }
        end,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local target = Teleporter.get_signal_goto_id( entity )
            
            if target then
                element.caption = tostring( target )
                element.tags = { target = target }
            else
                element.caption = ""
                element.tags = { target = 0 }
            end
            
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "label"
            }
        end,
    },
    
    -- COL_TIMER: Teleporter Timer
    [ COL_TIMER ] = { advanced = true, caption = { "", "[virtual-signal=ring-timer]" }, style = { width = 32, horizontal_align = "center", vertical_align = "center" },
        make_filter = empty_element,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local timer = Teleporter.get_signal_timer( entity )
            
            if timer then
                element.caption = tostring( timer )
                element.tags = { timer = timer }
            else
                element.caption = ""
                element.tags = { timer = 0 }
            end
            
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "label"
            }
        end,
    },
    
    -- COL_SHIELD: Teleporter Shield
    [ COL_SHIELD ] = { advanced = true, caption = { "", "[virtual-signal=shield-rings]" }, style = { width = 44, horizontal_align = "center", vertical_align = "center" },
        make_filter = function( parent, player )
            local items = {}
            items[ 1 ] = { "", "[virtual-signal=signal-anything] ", { "custom.any" } }
            items[ 2 ] = { "", "[virtual-signal=shape-circle] ", { "custom.open" } }
            items[ 3 ] = { "", "[virtual-signal=shield-rings] ", { "custom.protected" } }
            
            -- Create filter dropdown element
            return parent.add{
                type = "drop-down",
                items = items,
                selected_index = 1,
            }
        end,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local shielded = Teleporter.has_protection_signal( entity )
            
            if shielded then
                element.caption = { "", "[virtual-signal=shield-rings]" }
            else
                element.caption = { "", "[virtual-signal=shape-circle]" }
            end
            element.tags = { protected = shielded }
            
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "label"
            }
        end,
    },
    
    -- COL_NICKNAME: Teleporter Nickname
    [ COL_NICKNAME ] = { advanced = false, caption = { "custom.nickname" }, style = { width = 300 },
        make_filter = function( parent, player )
            return parent.add{
                type = "textfield",
                text = "",
                icon_selector = true,
                ignored_by_interaction = false,
                tags = { txtfield_type = "telep-filter_nickname" }
            }
        end,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local nickname = Teleporter.get_nickname( entity )
            
            -- Don't update it unless it's been updated in the background
            -- ie, another player has renamed it on their end
            -- This prevents the local player UI constantly boffing their input.
            if element.text ~= nickname then
                element.text = nickname
            end
            
            -- Not likely to happen, but we'll do it just the same
            element.ignored_by_interaction = not same_force
            
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            local nickname = Teleporter.get_nickname( entity )
            
            local element = parent.add{
                type = "textfield",
                icon_selector = true,
                text = nickname,
                ignored_by_interaction = not same_force,
                tags = {
                    txtfield_type = "telep-nickname",
                    unit_number = entity.unit_number
                },
                enabled = same_force,
            }
            
            return element
        end,
    },
    
    -- COL_FORCE: Teleporter Force (owning faction)
    [ COL_FORCE ] = { advanced = true, caption = { "custom.force" }, style = { width = 100 },
        make_filter = function( parent, player )
            local items = {}
            local count = 1
            local tags = {}
            
            -- Any filter at very top
            items[ count ] = { "", "[virtual-signal=signal-anything] ", { "custom.any" } }
            tags[ count ] = ""
            
            -- Player force right below that
            count = count + 1
            local player_force = game.forces[ "player" ]
            items[ count ] = player_force.name
            tags[ count ] = player_force.name
            
            -- Get all other non-player forces friendly to the player force
            for _, f in pairs( game.forces ) do
                if f.name ~= player_force.name and f.is_friend( player_force ) then
                    count = count + 1
                    items[ count ] = f.name
                    tags[ count ] = f.name
                end
            end
            
            return parent.add{
                type = "drop-down",
                items = items,
                tags = { forces = tags },
                selected_index = 1,
            }
        end,
        update = empty_update,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "label",
                caption = entity.force.name,
            }
        end,
    },
    
    -- COL_CHARGE: Teleporter Charge Level
    [ COL_CHARGE ] = { advanced = false, caption = { "custom.charge-level" }, style = { width = 100 },
        make_filter = empty_element,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            element.value = charge
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "progressbar"
            }
        end,
    },
    
    -- COL_LED: Teleporter Status LED
    [ COL_LED ] = { advanced = false, caption = { "custom.led" }, style = { width = 32, height = 32, horizontal_align = "center", vertical_align = "center" },
        make_filter = empty_element,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            element.sprite = sprite
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "sprite",
                sprite = sprite,
                resize_to_sprite = false
            }
        end,
    },
    
    -- COL_USER_ACTION: Teleporter Action Button
    [ COL_USER_ACTION ] = { advanced = false, caption = { "custom.action" }, style = { width = 120, horizontal_align = "center" },
        make_filter = empty_element,
        update = function( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            
            element.caption = make_action_button_caption( diode, data.occupied, entity, data_index )
            
            if data_index ~= SRC_TELEPORTER_DATA_INDEX and src_ready then
                element.enabled = src_ready and same_force and ( diode == DIODE_GREEN )
            end
        end,
        make = function( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            return parent.add{
                type = "button",
                tags = { dst_unit = entity.unit_number, src_unit = src_entity.unit_number },
                caption = make_action_button_caption( diode, data.occupied, entity, data_index ),
                enabled = data_index ~= SRC_TELEPORTER_DATA_INDEX and src_ready and same_force and ( diode == DIODE_GREEN )
            }
        end,
    },
    
    
}




-- Check the players UI preference and return the required table mapping data
local function GUI_get_UI_Mapping( player_index )
    storage.ring_teleporter_UI_Advanced_Mode = storage.ring_teleporter_UI_Advanced_Mode or {}
    local advanced = storage.ring_teleporter_UI_Advanced_Mode[ player_index ]
    if advanced == nil then
        advanced = false
    end
    
    local mapping = {}
    local row_length = 0
    
    -- Create a simple mapping table of actual column index -> table description index
    for i = 1, COL_LAST, 1 do
        local desc = teleporter_table_desc[ i ]
        if not desc.advanced or advanced then
            row_length = row_length + 1
            mapping[ row_length ] = i
        end
    end
    
    return advanced, row_length, mapping
end


-- Make the entire row of teleporter column headers in the header table
function teleporter_table_desc.make_headers( parent, advanced )
    for i = 1, COL_LAST, 1 do
        local desc = teleporter_table_desc[ i ]
        if not desc.advanced or advanced then
            local header = parent.add{ type = "label", caption = desc.caption }
            header.style.width = desc.style.width
        end
    end
end


-- Make the entire row of teleporter column filters in the header table
teleporter_table_desc.make_filters = function( parent, player ) -- Don't pass advanced to filter creation, in basic UI no filter line will be present at all
    if not parent then return end
    
    -- Resulting elements
    local elements = {}
    
    
    -- Make them
    for i = 1, COL_LAST, 1 do
        local element = teleporter_table_desc[ i ].make_filter( parent, player )
        teleporter_table_desc.apply_column_style( i, element )
        elements[ i ] = element
    end
    
    
    -- Return them
    return elements
end


-- Make the entire row of teleporter columns in the teleporter table for the given teleporter
teleporter_table_desc.make_row = function( player, parent, advanced, data, data_index, src_entity, src_ready )
    if not parent then return end
    if not data then return end
    local entity = data[ TELEPORTER_CONTROLLER ]
    if not entity or not entity.valid then return end
    
    -- Common data to all
    local same_force = entity.force.name == player.force.name
    local charge, diode, sprite = Teleporter.get_status( entity )
    
    -- Resulting elements
    local elements = {}
    
    
    -- Make them
    for i = 1, COL_LAST, 1 do
        local desc = teleporter_table_desc[ i ]
        if not desc.advanced or advanced then
            local element = desc.make( player, parent, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
            teleporter_table_desc.apply_column_style( i, element )
            desc.update( player, element, data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
        end
        elements[ i ] = element
    end
    
    
    -- Return them
    return elements
end


-- Update the entire row of teleporter columns for the given teleporter
teleporter_table_desc.update_row = function( player, elements, advanced, row_length, mapping, row_start, data, data_index, src_entity, src_ready )
    if not elements then return end
    if not data then return end
    local entity = data[ TELEPORTER_CONTROLLER ]
    if not entity or not entity.valid then return end
    
    -- Common data to all
    local same_force = entity.force.name == player.force.name
    local charge, diode, sprite = Teleporter.get_status( entity )
    
    -- Update them
    for i = 1, row_length, 1 do
        teleporter_table_desc[ mapping[ i ] ].update( player, elements[ row_start + i ], data, entity, data_index, same_force, charge, diode, sprite, src_entity, src_ready )
    end
    
end


-- Make this row visible
teleporter_table_desc.show_row = function( elements, row_length, row_start )
    if elements[ row_start + 1 ].visible then return end -- skip if already visible
    for j = 1, row_length, 1 do
        elements[ row_start + j ].visible = true
    end
end

-- Make this row invisible
teleporter_table_desc.hide_row = function( elements, row_length, row_start )
    if not elements[ row_start + 1 ].visible then return end -- skip if already hidden
    for j = 1, row_length, 1 do
        elements[ row_start + j ].visible = false
    end
end


-- Apply the column style to the element
teleporter_table_desc.apply_column_style = function( index, element )
    local cs = teleporter_table_desc[ index ].style   -- Shortcut
    local es = element.style                -- Shortcut
    for k, v in pairs( cs ) do
        es[ k ] = v                         -- Copy key-value pairs
    end
end








local GUI = {}

function GUI.close_window( player )
    local frame = player.gui.screen.teleporter_gui
    --log( "GUI.close_window : " .. ( player and tostring( player.index ) or "none" ) .. " " .. ( frame and frame.name or "none" ) .. "\n" .. debug.traceback() )
    if frame then
        frame.destroy()
        if storage.ring_teleporter_GUIs then
            storage.ring_teleporter_GUIs[ player.index ] = nil
        end
    end
end

function GUI.close_all_windows()
    for _, player in pairs( game.players ) do
        GUI.close_window( player )
    end
end




function GUI.open_window( player, entity )
    -- Destroy existing GUI if it exists
    GUI.close_window( player )
    
    if not( entity and entity.valid )then return end -- Failure
    
    -- Get the teleporter data for this entity
    local src_data = storage.ring_teleporter_teleporters[ entity.unit_number ]
    if src_data == nil then return end -- Failure
    
    
    local advanced, row_length, mapping = GUI_get_UI_Mapping( player.index )
    
    
    if advanced then
        -- Factorio does something weird with UI scale - at 44 and 100% the icon is only shown in the expanded drop-down as an icon and with the text in a tooltip.
        -- BUT - at 44 and 200%, the icon is clipped in the drop-down by 14 pixels and lowering it from 44 causes the right edges of the icons to be clipped when the drop-down is expanded.
        -- Solution - Make it even WIDER at higher scales so it shows the full text for people with high resolution displays.
        teleporter_table_desc[ COL_SHIELD ].style.width = player.display_scale > 1.0 and 128 or 44
    end
    
    
    -- Retrieve the list of other teleporters
    local teleporters = Teleporter.get_teleporters( entity )
    Teleporter.sort_teleporters( teleporters, player.force.name )
    --table.insert( teleporters, 1, src_data ) -- Don't put it in the list of other teleporters
    
    local src_charge, src_diode, src_sprite = Teleporter.get_status( entity )
    local src_ready = src_diode == DIODE_GREEN
    
    
    -- Create the main frame
    local frame
    do
        
        frame = player.gui.screen.add{
            type = "frame",
            name = GUI_BASE,
            direction = "vertical",
            tags = { src_data = src_data },
        }
        frame.force_auto_center()
        
        -- Add a custom title bar
        local titlebar = frame.add{
            type = "flow",
            direction = "horizontal"
        }
        titlebar.drag_target = frame  -- Make the title bar draggable
        
        -- Add a title label to the title bar
        titlebar.add{
            type = "label",
            style = "frame_title",
            caption = { "custom.manual-dialing" },
            ignored_by_interaction = true
        }
        
        -- Add a spacer to push the close button to the right
        local spacer = titlebar.add{
            type = "empty-widget",
            style = "draggable_space_header",
            ignored_by_interaction = true
        }
        spacer.style.horizontally_stretchable = true
        spacer.style.height = 24
        spacer.style.minimal_width = 24
        spacer.style.right_padding = 0
        
        -- Add an advanced mode toggle
        titlebar.add{
            type = "sprite-button",
            name = GUI_EXPAND_BUTTON,
            sprite = advanced and "utility/collapse" or "utility/expand",
            style = "shortcut_bar_expand_button",
        }
        
        -- Add the close button
        titlebar.add{
            type = "sprite-button",
            name = GUI_CLOSE_BUTTON,
            sprite = "utility/close",
            style = "close_button",
        }
        
    end
    
    
    -- Create a header table for the column headers, filters and, source teleporter
    do
        
        -- Add a pane for the header and filters
        local header_pane = frame.add{
            type = "scroll-pane",
            name = GUI_HEADER_PANE,
            direction = "vertical",
            style = "scroll_pane"
        }
        header_pane.style.minimal_height = advanced and 128 or 80
        
        
        -- Create a table to display the teleporters with columns
        local header_table = header_pane.add{
            type = "table",
            name = GUI_HEADER_TABLE,
            column_count = row_length,
            draw_horizontal_lines = true,
            draw_vertical_lines = false,
            draw_horizontal_line_after_headers = true,
            style = "bordered_table"
        }
        
        
        -- Add table headers
        teleporter_table_desc.make_headers( header_table, advanced )
        
        
        -- Add table filters
        if advanced then    -- But only in advanced mode
            teleporter_table_desc.make_filters( header_table, player )
        end
        
        
        -- Add the source teleporter to the header table
        teleporter_table_desc.make_row( player, header_table, advanced, src_data, SRC_TELEPORTER_DATA_INDEX, entity, src_ready )
        
        
    end
    
    
    -- Create a table of the other teleporters
    do
    
        -- Add a scroll pane
        local scroll_pane = frame.add{
            type = "scroll-pane",
            name = GUI_TELEPORTER_PANE,
            direction = "vertical",
            style = "scroll_pane"
        }
        scroll_pane.style.maximal_height = 600 -- Limit how large the UI can grow before scrolling kicks in
        
        -- Create the table
        local teleporter_table = scroll_pane.add{
            type = "table",
            name = GUI_TELEPORTER_TABLE,
            column_count = row_length,
            draw_horizontal_lines = true,
            draw_vertical_lines = false,
            draw_horizontal_line_after_headers = true,
            style = "bordered_table"
        }
        
        -- Loop through the other teleporters and add rows to the table
        for index, teleporter_data in pairs( teleporters ) do
            teleporter_table_desc.make_row( player, teleporter_table, advanced, teleporter_data, index, entity, src_ready )
        end
        
    end
    
    local player_index = player.index
    storage.ring_teleporter_GUIs[ player_index ] = {
        frame = frame,
        player_index = player_index,
        entity = entity,
        src_data = src_data
    }
    
    player.opened = frame
end



function GUI.update_window( frame_data )
    
    if not ( frame_data and frame_data.player_index ) then
        return
    end
    
    local player = game.players[ frame_data.player_index ]
    if not player then
        return
    end
    
    
    local frame = frame_data.frame or player.gui.screen.teleporter_gui
    if not frame or not frame.valid then
        GUI.close_window( player )
        return
    end
    
    local entity = frame_data.entity
    if not ( entity and entity.valid ) then
        GUI.close_window( player )
        return
    end
    
    local header_pane = frame[ GUI_HEADER_PANE ]
    local header_table = header_pane[ GUI_HEADER_TABLE ]
    
    local teleporter_pane = frame[ GUI_TELEPORTER_PANE ]
    local teleporter_table = teleporter_pane[ GUI_TELEPORTER_TABLE ]
    
    
    local advanced, row_length, mapping = GUI_get_UI_Mapping( player.index )
    
    
    local src_data = frame_data.src_data
    local src_charge_level, src_diode, src_sprite = Teleporter.get_status( entity )
    local src_ready = src_diode == DIODE_GREEN
    
    local table_children = teleporter_table.children
    local existing_rows = math.floor( #table_children / row_length )
    
    -- Retrieve the list of other teleporters
    local teleporters = Teleporter.get_teleporters( entity )
    Teleporter.sort_teleporters( teleporters, player.force.name )
    --table.insert( teleporters, 1, storage.ring_teleporter_teleporters[ entity.unit_number ] ) -- Src teleporter
    local nr_teleporters = #teleporters
    
    
    -- Get each filter element in the header
    local header_children = header_table.children
    local filter_pos_drop = advanced and header_children[ COL_LAST + COL_LOCATION ]          -- Column 1: Location dropdown
    local filter_id_cell = advanced and header_children[ COL_LAST + COL_ID ]                 -- Column 2: Ring ID Textfield/Label
    local filter_target_cell = advanced and header_children[ COL_LAST + COL_TARGET ]         -- Column 3: Target ID Textfield/Label
    --local filter_timer_cell = advanced and header_children[ COL_LAST + COL_TIMER ]         -- Column 4: Timer Textfield/Label
    local filter_shield_cell = advanced and header_children[ COL_LAST + COL_SHIELD ]         -- Column 5: Shield Textfield/Label
    local filter_nickname_cell = advanced and header_children[ COL_LAST + COL_NICKNAME ]     -- Column 6: Nickname Textfield/Label
    local filter_force_drop = advanced and header_children[ COL_LAST + COL_FORCE ]           -- Column 7: Force Name dropdown
    --local filter_charge_bar = advanced and header_children[ COL_LAST + COL_CHARGE ]        -- Column 8: Charge Level Progress Bar
    --local filter_led_sprite = advanced and header_children[ COL_LAST + COL_LED ]           -- Column 9: Status Sprite (LED)
    --local filter_action_cell = advanced and header_children[ COL_LAST + COL_USER_ACTION ]  -- Column 10: Action label
    
    -- Get each filter value
    local filter_surface = advanced and filter_pos_drop.tags.surfaces[ filter_pos_drop.selected_index ]
    local filter_id
    if advanced and filter_id_cell.text ~= "" then
        filter_id = tonumber( filter_id_cell.text )
    end
    
    local filter_target
    if advanced and filter_target_cell.text ~= "" then
        filter_target = tonumber( filter_target_cell.text )
    end
    
    local filter_shield
    if advanced then
        if filter_shield_cell.selected_index == 2 then      -- Open
            filter_shield = false
        elseif filter_shield_cell.selected_index == 3 then  -- Protected
            filter_shield = true
        end
    end
    
    local filter_nickname = advanced and filter_nickname_cell.text
    local filter_force = advanced and filter_force_drop.tags.forces[ filter_force_drop.selected_index ]
    
    -- Update the source teleporter in the header table
    do
        local row_start = advanced and ( COL_LAST * 2 ) or row_length
        teleporter_table_desc.update_row( player, header_children, advanced, row_length, mapping, row_start, src_data, SRC_TELEPORTER_DATA_INDEX, src_data[ TELEPORTER_CONTROLLER ], src_ready )
    end
    
    -- Update and filter the other teleporters
    for i, teleporter_data in ipairs( teleporters ) do
        
        if i > existing_rows then
            -- Add new row for this teleporter
            teleporter_table_desc.make_row( player, teleporter_table, advanced, teleporter_data, i, entity, src_ready )
            existing_rows = existing_rows + 1
            -- Old table was invalidated by adding new rows
            table_children = teleporter_table.children
        end
        
        -- Calculate the starting index of the row
        local row_start = ( i - 1 ) * row_length
        
        
        local teleporter_entity = teleporter_data[ TELEPORTER_CONTROLLER ]
        if not teleporter_entity or not teleporter_entity.valid then
            teleporter_table_desc.hide_row( table_children, row_length, row_start )
            goto continue  -- Skip invalid entities
        end
        
        
        if advanced then
            
            local function is_accepted_by_filter()
                -- Get each cell in the row
                if filter_surface ~= "" then
                    local pos_btn = table_children[ row_start + COL_LOCATION ]          -- Column 1: Position Button
                    if filter_surface ~= pos_btn.tags.surface then return false end
                end
                
                if filter_id then
                    local id_label = table_children[ row_start + COL_ID ]               -- Column 2: Ring ID Label
                    if filter_id ~= tonumber( id_label.tags.id ) then return false end
                end
                
                if filter_target then
                    local target_label = table_children[ row_start + COL_TARGET ]      -- Column 3: Target ID Textfield/Label
                    if filter_target ~= tonumber( target_label.tags.target ) then return false end
                end
                
                --local timer_label = table_children[ row_start + COL_TIMER ]          -- Column 4: Timer Textfield/Label
                
                if filter_shield ~= nil then
                    local shield_cell = table_children[ row_start + COL_SHIELD ]       -- Column 5: Shield Textfield/Label
                    if filter_shield ~= shield_cell.tags.protected then return false end
                end
                
                if filter_nickname ~= "" then
                    local nickname_cell = table_children[ row_start + COL_NICKNAME ]    -- Column 6: Nickname Textfield/Label
                    if string.find( nickname_cell.text, filter_nickname, 1, true ) == nil then return false end -- Plain string matching from the begining - plain matching must be specified so it doesn't try to regex icons
                end
                
                if filter_force ~= "" then
                    local force_label = table_children[ row_start + COL_FORCE ]         -- Column 7: Force Name Label
                    if filter_force ~= force_label.caption then return false end
                end
                
                --local charge_bar = table_children[ row_start + COL_CHARGE ]           -- Column 8: Charge Level Progress Bar
                --local led_sprite = table_children[ row_start + COL_LED ]              -- Column 9: Status Sprite (LED)
                --local teleport_btn = table_children[ row_start +  COL_USER_ACTION ]   -- Column 10: Teleport Button
                
                return true
            end
            
            if is_accepted_by_filter() then
                teleporter_table_desc.show_row( table_children, row_length, row_start )
            else
                teleporter_table_desc.hide_row( table_children, row_length, row_start )
                -- Skip further updates for it
                goto continue
            end
            
        end
        
        
        -- Update the elements
        teleporter_table_desc.update_row( player, table_children, advanced, row_length, mapping, row_start, teleporter_data, i, entity, src_ready )
        
        
        ::continue::
    end
    
    
    -- Disable rows on a shrinking list
    if nr_teleporters < existing_rows then
        for i = nr_teleporters + 1, existing_rows, 1 do
            local row_start = ( i - 1 ) * row_length
            teleporter_table_desc.hide_row( table_children, row_length, row_start )
        end
    end
    
end








local function manual_dial( player, src_unit, dst_unit )
    local src_data = storage.ring_teleporter_teleporters[ src_unit ]
    local dst_data = storage.ring_teleporter_teleporters[ dst_unit ]
    if Teleporter.initiate_teleport( src_data, dst_data ) then
        player.print( { "custom.manual-dial-success" } )
    else
        player.print( { "custom.occupied" } )
    end
end






local function on_gui_text_changed( event )
    local elem = event.element
    if elem and elem.tags and elem.tags.txtfield_type == "telep-nickname" then
        local unit_number = elem.tags.unit_number
        if unit_number then
            local nickname = elem.text
            local data = storage.ring_teleporter_teleporters[ unit_number ]
            Teleporter.set_nickname( data[ TELEPORTER_CONTROLLER ], nickname )
        end
    end
end




local function on_gui_click( event )
    local element = event.element
    if not element.valid then return end
    
    local player_index = event.player_index
    local player = game.players[ player_index ]
    
    -- Handle window expansion
    if element.name == GUI_EXPAND_BUTTON then
        
        -- Get the entity from the current window
        local gui = storage.ring_teleporter_GUIs[ player_index ]
        local entity = gui.entity
        
        -- Close the current window
        GUI.close_window( player )
        
        -- Toggle the window mode
        storage.ring_teleporter_UI_Advanced_Mode[ player_index ] = not storage.ring_teleporter_UI_Advanced_Mode[ player_index ]
        
        -- Schedule the window to reopen on the next tick
        Util.schedule_after( 1, GUI_OPEN_WINDOW, { player, entity } )
        
        return
    end
    
    -- Handle close button
    if element.name == GUI_CLOSE_BUTTON then
        GUI.close_window( player )
        return
    end
    
    local tags = element.tags
    if tags then
        
        -- Handle position button clicks
        if tags.gps_tag then
            player.print( tags.gps_tag )
            return
        end
        
        -- Handle teleport button clicks
        if tags.src_unit and tags.dst_unit then
            
            -- Only proceed if the button is enabled
            if element.enabled then
                manual_dial( player, tags.src_unit, tags.dst_unit )
                GUI.close_window( player )
            end
        end
        
    end
end




local function on_gui_opened( event )
    local player = game.players[ event.player_index ]
    local entity = event.entity
    --log( "on_gui_opened() : " .. tostring( entity ~= nil ) )
    
    -- Get the teleporter data from the entity
    local data = Teleporter.find_by_entity( entity )
    
    
    if data then
        --log( "\t->" .. tostring( entity.valid ) .. " " .. entity.name .. " " .. Teleporter.get_nickname( entity ) .. " " .. tostring( data ) )
        
        player.opened = nil                     -- Prevent default GUI from opening
        
        local gui = player.gui.screen.teleporter_gui
        
        entity = data[ TELEPORTER_CONTROLLER ]
        
        if gui and gui.tags and entity.unit_number == gui.tags.unit_number then
            GUI.close_window( player )          -- Close any existing teleporter window
        else
            GUI.open_window( player, entity )   -- Open the new teleporter window
        end
        
    end
end




local function on_gui_closed( event )
    local gui = event.element
    --log( "on_gui_closed() : " .. tostring( gui ~= nil ) .. " " .. ( ( gui and gui.valid ) and gui.name or "none" ) )
    if gui and gui.valid and gui.name == GUI_BASE then
        GUI.close_window( game.players[ event.player_index ] )
    end
end





function GUI.bootstrap()
    
    -- Handle GUI interactions
    script.on_event( defines.events.on_gui_text_changed, on_gui_text_changed )
    script.on_event( defines.events.on_gui_click, on_gui_click )
    
    -- Handle GUI open/close
    script.on_event( defines.events.on_gui_opened, on_gui_opened )
    script.on_event( defines.events.on_gui_closed, on_gui_closed )
    
end


function GUI.init()
    storage.ring_teleporter_GUIs = {}
    storage.ring_teleporter_UI_Advanced_Mode = {}
end


-- Map functions that can be scheduled.

Util.map_functions{
    [ GUI_OPEN_WINDOW ]       = GUI.open_window,
}

return GUI