local util = require("util")
local teleporting = require("Teleporting")

-- Sprites are shifted to avoid getting culled by the rendering engine
local entity_shift = {x=0, y=1.5}

-- Avoid any issues with references becoming invalid
local function remap_teleporters()
    log("Starting migration.")
    storage.ring_teleporter_GUIs = storage.ring_teleporter_GUIs or {}
    storage.ring_teleporter_teleporters = {}
    storage.ring_teleporter_scheduled_functions = {}
    storage.ring_teleporter_barriers = {}
    storage.ring_teleporter_nicknames = storage.ring_teleporter_nicknames or {}
    for _, surface in pairs(game.surfaces) do
        local sprites = surface.find_entities_filtered{name="ring-teleporter-sprite"}
        for _, sprite in ipairs(sprites) do
            sprite.destroy()
        end
        local back_animations = surface.find_entities_filtered{name="ring-teleporter-back"}
        for _, animation in ipairs(back_animations) do
            animation.destroy()
        end
        local front_animations = surface.find_entities_filtered{name="ring-teleporter-front"}
        for _, animation in ipairs(front_animations) do
            animation.destroy()
        end
        local barriers = surface.find_entities_filtered{name="ring-teleporter-barrier"}
        for _, barrier in ipairs(barriers) do
            barrier.destroy()
        end
        -- Add new sprites and data to storage
        local teleporters = surface.find_entities_filtered{name="ring-teleporter"}
        for _, teleporter in ipairs(teleporters) do
            local renderer = surface.create_entity{
                name = "ring-teleporter-sprite",
                position = util.add_positions({x = teleporter.position.x - 4.5, y = teleporter.position.y - 4.5}, entity_shift),
                force = teleporter.force,
                raise_built = false,
                create_build_effect_smoke = true,
            }
            renderer.destructible = false
            storage.ring_teleporter_teleporters[teleporter.unit_number] = {entity = teleporter, renderer = renderer, occupied = false}
            local poskey = util.poskey(teleporter)
            storage.ring_teleporter_nicknames[poskey] = storage.ring_teleporter_nicknames[poskey] or util.backername()
        end
    end
    log("Migration complete.")
end

script.on_init(function()
    storage.ring_teleporter_teleporters = {}
    storage.ring_teleporter_scheduled_functions = {}
    storage.ring_teleporter_barriers = {}
    storage.ring_teleporter_GUIs = {}
    storage.ring_teleporter_nicknames = {}
    storage.power_cost_multiplier = settings.startup["trt-power-multiplier"].value
end)

script.on_configuration_changed(function()
    remap_teleporters()
    storage.power_cost_multiplier = settings.startup["trt-power-multiplier"].value
end)

local event_filter = {
    {filter="name", name="ring-teleporter"},
    {filter="name", name="ring-teleporter-placer"},
}

Teleporter_ignored_entities = {
    ["ring-teleporter"] = true,
    ["ring-teleporter-sprite"] = true,
    ["ring-teleporter-back"] = true,
    ["ring-teleporter-front"] = true,
    ["ring-teleporter-barrier"] = true,
}

Teleporter_do_not_damage_entities = {
    ["ring-teleporter"] = true,
    ["ring-teleporter-sprite"] = true,
    ["ring-teleporter-back"] = true,
    ["ring-teleporter-front"] = true,
    ["ring-teleporter-barrier"] = true,

}

local rail_types = {
    ['curved-rail-a'] = true,
    ['elevated-curved-rail-a'] = true,
    ['curved-rail-b'] = true,
    ['elevated-curved-rail-b'] = true,
    ['half-diagonal-rail'] = true,
    ['elevated-half-diagonal-rail'] = true,
    ['legacy-curved-rail'] = true,
    ['legacy-straight-rail'] = true,
    ['rail-ramp'] = true,
    ['straight-rail'] = true,
    ['elevated-straight-rail'] = true,
}

local function is_rail(entity)
    return rail_types[entity.prototype.type]
end

local function ring_collision_incident(surface, pos, teleporter)
    local hits = surface.find_entities_filtered{position = pos, radius = 0.75}
    for _, hit in ipairs(hits) do
        if hit.valid and hit.is_entity_with_health and not Teleporter_do_not_damage_entities[hit.name] and not is_rail(hit) then
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
    local left = p.x - 6.5
    local right = p.x - 2.5
    local top = p.y - 4.5
    local bottom = p.y - 1.5
    local unit_number = entity.unit_number
    local function try_place(x, y)
        local pos = {x = x, y = y}
        if not surface.can_place_entity{name = barrier_name, position = pos} then
            ring_collision_incident(surface, pos, entity)
        end
        local placed_entity
        if entity and entity.valid then
            placed_entity = surface.create_entity{name = barrier_name, position = pos, force = entity.force}
        end
        if placed_entity then
            table.insert(barrier, placed_entity)
            placed_entity.destructible = false
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
    util.schedule_after(238, "destroy_barrier", {unit_number, surface})
    return barrier
end

local function destroy_barrier(unit_number, surface)
    local list = storage.ring_teleporter_barriers[unit_number]
    if list then
        for _, entity in ipairs(list) do
            if entity and entity.valid then
                entity.destroy()
            end
        end
    else -- This should not normally happen, unless during animation teleporter is destroyed or mod migration is applied etc
        if surface then
            local barriers = surface.find_entities_filtered{name="ring-teleporter-barrier"}
            for _, barrier in ipairs(barriers) do
                barrier.destroy()
            end
        end
    end
    storage.ring_teleporter_barriers[unit_number] = nil
end

local function barrier_start(entity)
    storage.ring_teleporter_barriers[entity.unit_number] = create_barrier(entity)
end

local function destroy_animations(animation1, animation2)
    if animation1 and animation1.valid then
        animation1.destroy()
    end
    if animation2 and animation2.valid then
        animation2.destroy()
    end
end

-- Function to play the one-time animation
local function animate_teleporter(entity)
    if not entity.valid then return end

    local surface = entity.surface
    local position = util.add_positions(entity.position, {x=-4.5,y=-4.5})

    local animation1 = surface.create_entity{
        name = "ring-teleporter-back",
        position = util.add_positions(position, entity_shift),
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
    }

    local animation2 = surface.create_entity{
        name = "ring-teleporter-front",
        position = util.add_positions(position, entity_shift),
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
    }

    animation1.destructible = false
    animation2.destructible = false

    storage.ring_teleporter_teleporters[entity.unit_number].animation1 = animation1
    storage.ring_teleporter_teleporters[entity.unit_number].animation2 = animation2
    util.play_random_sound(entity, {"ring-1", "ring-2", "ring-3", "ring-4", "ring-5"})
    
    util.schedule_after(20, "barrier_start", {entity})
    util.schedule_after(300, "destroy_animations", {animation1, animation2})
end

local function has_protection_signal(entity)
    local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
    local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
    if network_red then
        local signal = network_red.get_signal({type="virtual", name="shield-rings"})
        if signal and signal ~= 0 then
            return true
        end
    end
    if network_green then
        local signal = network_green.get_signal({type="virtual", name="shield-rings"})
        if signal and signal ~= 0 then
            return true
        end
    end
    return false
end

local function get_teleporter_id(src_teleporter_data, entity)
    if entity and entity.valid then
        local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
        local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
        local found_id = nil
        if network_red then
            local signal = network_red.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                found_id = signal
            end
        end
        if not found_id and network_green then
            local signal = network_green.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                found_id = signal
            end
        end
        if entity.energy < 999999999 * storage.power_cost_multiplier then -- Destination rings out of power
            return nil
        end
        if found_id then
            if has_protection_signal(entity) then
                if src_teleporter_data.entity then
                    local requester_force = src_teleporter_data.entity.force
                    local is_friendly_connection = requester_force.is_friend(entity.force)
                    if is_friendly_connection then
                        return found_id
                    end
                end
            else
                return found_id
            end
        end
    end
end

local function get_id_no_conditions(entity)
    if entity and entity.valid then
        local network_red = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
        local network_green = entity.get_circuit_network(defines.wire_connector_id.circuit_green)
        if network_red then
            local signal = network_red.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                return signal
            end
        end
        if network_green then
            local signal = network_green.get_signal({type="virtual", name="ring-id"})
            if signal and signal ~= 0 then
                return signal
            end
        end
    end
    return nil
end

local function timed_teleport(src_teleporter_data, dest_teleporter_data)
    local src_teleporter = src_teleporter_data.entity
    local dest_teleporter = dest_teleporter_data.entity
    if src_teleporter and src_teleporter.valid and dest_teleporter and dest_teleporter.valid then
        local p = src_teleporter.position
        local area = {
            left_top = {x = p.x - 7, y = p.y - 5},
            right_bottom = {x = p.x - 2, y = p.y - 0.5}
        }
        local targets = src_teleporter.surface.find_entities_filtered{area = area}

        p = dest_teleporter.position
        area = {
            left_top = {x = p.x - 7, y = p.y - 5},
            right_bottom = {x = p.x - 2, y = p.y - 0.5}
        }
        local targets2 = dest_teleporter.surface.find_entities_filtered{area = area}

        for _, target in ipairs(targets) do
            if target.valid and src_teleporter.valid and dest_teleporter.valid then
                local relative = util.get_relative_position(target, src_teleporter)
                teleporting.ring_teleport(target, dest_teleporter.surface, util.add_positions(dest_teleporter.position, relative))
            end
        end

        for _, target in ipairs(targets2) do
            if target.valid and src_teleporter.valid and dest_teleporter.valid then
                local relative = util.get_relative_position(target, dest_teleporter)
                teleporting.ring_teleport(target, src_teleporter.surface, util.add_positions(src_teleporter.position, relative))
            end
        end

    end
    src_teleporter_data.occupied = false
    dest_teleporter_data.occupied = false
end

local function timed_teleport_animation(src_teleporter_data, dest_teleporter_data)
    local src_teleporter = src_teleporter_data.entity
    local dest_teleporter = dest_teleporter_data.entity
    if src_teleporter and src_teleporter.valid and dest_teleporter and dest_teleporter.valid then
        src_teleporter.energy = src_teleporter.energy - 1000000000 * storage.power_cost_multiplier
        dest_teleporter.energy = dest_teleporter.energy - 1000000000 * storage.power_cost_multiplier
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
            if signal == get_teleporter_id(src_teleporter_data, dest_teleporter) then
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

function After_player_teleport_sound(player, target_position)
    player.play_sound{path="ring-end", position=target_position}
end

local function get_teleporters(src_entity)
    local teleporters = {}
    for unit_nr, data in pairs(storage.ring_teleporter_teleporters) do
        if data.entity ~= src_entity then
            local entity = data.entity
            if entity and entity.valid then
                local visible = true
                if has_protection_signal(entity) then
                    local requester_force = src_entity.force
                    local is_friendly_connection = requester_force.is_friend(entity.force)
                    if not is_friendly_connection then
                        visible = false
                    end
                end
                if visible then
                    local teleporter_data = {
                        occupied = data.occupied,
                        entity = entity
                    }
                    table.insert(teleporters, teleporter_data)
                end
            end
        end
    end
    return teleporters
end

local function create_teleporter_gui(player, entity)
    -- Retrieve the list of teleporters
    local teleporters = get_teleporters(entity)

    -- Destroy existing GUI if it exists
    local gui = player.gui.screen.teleporter_gui
    if gui then
        gui.destroy()
    end
    
    if entity == nil then return end -- Failure

    -- Create the main frame
    local frame = player.gui.screen.add{
        type = "frame",
        name = "teleporter_gui",
        direction = "vertical",
        tags = {unit_number = entity.unit_number}
    }
    frame.force_auto_center()

    -- Add a custom title bar
    local titlebar = frame.add{
        type = "flow",
        name = "titlebar_flow",
        direction = "horizontal"
    }
    titlebar.drag_target = frame  -- Make the title bar draggable

    -- Add a title label to the title bar
    titlebar.add{
        type = "label",
        style = "frame_title",
        caption = {"custom.manual-dialing"},
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

    -- Add the close button
    titlebar.add{
        type = "sprite-button",
        name = "teleporter_close_button",
        sprite = "utility/close",
        style = "close_button",
    }

    -- Add a scroll pane to handle many teleporters
    local scroll_pane = frame.add{
        type = "scroll-pane",
        name = "teleporter_scroll_pane",
        direction = "vertical",
        style = "scroll_pane"
    }
    scroll_pane.style.maximal_height = 400
    scroll_pane.style.width = 700

    -- Create a table to display the teleporters with columns
    local teleporter_table = scroll_pane.add{
        type = "table",
        name = "teleporter_table",
        column_count = 6,
        draw_horizontal_lines = true,
        draw_vertical_lines = false,
        draw_horizontal_line_after_headers = true,
        style = "bordered_table"
    }

    -- Add table headers
    teleporter_table.add{type = "label", caption = {"custom.position"}}
    teleporter_table.add{type = "label", caption = {"custom.nickname"}}
    teleporter_table.add{type = "label", caption = {"custom.force"}}
    teleporter_table.add{type = "label", caption = {"custom.charge-level"}}
    teleporter_table.add{type = "label", caption = {"custom.led"}}
    teleporter_table.add{type = "label", caption = {"custom.action"}}

    if not storage.ring_teleporter_GUIs then
        storage.ring_teleporter_GUIs = {}
    end

    storage.ring_teleporter_GUIs[player.index] = {
        gui = player.gui.screen.teleporter_gui,
        pos = entity.position,
        entity = entity
    }

    local this_charged = entity.energy >= 999999999 * storage.power_cost_multiplier

    util.sort_teleporters(teleporters, player.force.name)
    table.insert(teleporters, 1, storage.ring_teleporter_teleporters[entity.unit_number]) -- Src teleporter

    -- Loop through teleporters and add rows to the table
    for index, teleporter_data in pairs(teleporters) do
        local teleporter_entity = teleporter_data.entity
        local position = teleporter_entity.position
        local force_name = teleporter_entity.force.name
        local charge_level = math.min(teleporter_entity.energy / (999999999 * storage.power_cost_multiplier), 1)

        -- Create the GPS tag
        local gps_tag = string.format("[gps=%d,%d,%s]", math.floor(position.x + 0.5), math.floor(position.y + 0.5), teleporter_entity.surface.name)
        
        local icon = gps_tag
        local planet = teleporter_entity.surface.planet
        local sname = teleporter_entity.surface.name
        if planet then
            icon = string.format("[planet=%s]", planet.name)
        elseif teleporter_entity.surface.platform then
            icon = "[img=item.space-platform-hub]"
            sname = teleporter_entity.surface.platform.name
        end

        local id = get_id_no_conditions(teleporter_entity)
        if id then
            sname =  "ID " .. id .. " " .. sname:gsub("^%l", string.upper)
        else
            sname = sname:gsub("^%l", string.upper)
        end

        if #sname > 14 then
            sname = string.sub(sname, 1, 14) .. "..."
        end

        -- Add position button with GPS tag
        local btn = teleporter_table.add{
            type = "button",
            name = "teleporter_gps_button_" .. teleporter_entity.unit_number,
            caption = icon .. " " .. sname,
            tags = {gps_tag = gps_tag}
        }
        btn.style.horizontally_stretchable = true
        btn.style.minimal_width = 50
        btn.style.horizontal_align = "left"

        -- Nickname textbox
        local poskey = util.poskey(teleporter_entity)
        local nickname = storage.ring_teleporter_nicknames[poskey]
        local textfield_nickname
        local sameforce = player.force.name == force_name
        textfield_nickname = teleporter_table.add{type = "textfield", text = nickname, icon_selector = true, ignored_by_interaction = not sameforce, tags = {txtfield_type = "telep-nickname", poskey = poskey}}
        textfield_nickname.enabled = sameforce
        textfield_nickname.style.width = 150

        -- Add force name
        teleporter_table.add{type = "label", caption = force_name}

        -- Add charge level progress bar
        local progress_bar = teleporter_table.add{
            type = "progressbar",
            value = charge_level
        }
        progress_bar.style.width = 100

        local sprite = teleporter_data.occupied and "diode-yellow" or charge_level >= 1 and "diode-green" or "diode-red"
        local led = teleporter_table.add{
            type = "sprite",
            sprite = sprite,
        }
        led.style.right_padding = 2.5

        -- Add teleport button and set its enabled state
        if index == 1 then
            teleporter_table.add{
                type = "button",
                name = "teleporter_teleport_button_" .. teleporter_entity.unit_number,
                caption = {"custom.open-teleporter"},
                tags = {unit_number = teleporter_entity.unit_number, src_unit_number = entity.unit_number},
                enabled = false
            }
        else
            teleporter_table.add{
                type = "button",
                name = "teleporter_teleport_button_" .. teleporter_entity.unit_number,
                caption = {"custom.teleport"},
                tags = {unit_number = teleporter_entity.unit_number, src_unit_number = entity.unit_number},
                enabled = (charge_level >= 1) and (not teleporter_data.occupied) and this_charged
            }
        end
    end
    player.opened = frame
end

local function update_teleporter_gui(player, entity)
    local gui = player.gui.screen.teleporter_gui
    if not gui or not gui.valid then return end
    if not entity or not entity.valid then return end
    local teleporters = get_teleporters(entity)
    if not teleporters then return end
    local teleporter_table = gui.teleporter_scroll_pane.teleporter_table
    if not teleporter_table or not teleporter_table.valid then return end

    if not storage.ring_teleporter_GUIs then
        storage.ring_teleporter_GUIs = {}
    end
    storage.ring_teleporter_GUIs[player.index] = {
        gui = gui,
        pos = entity.position,
        entity = entity
    }

    local this_charged = entity.energy >= 999999999 * storage.power_cost_multiplier

    local header_count = 6
    local existing_rows = math.floor((#teleporter_table.children - header_count) / 6)

    util.sort_teleporters(teleporters, player.force.name)
    table.insert(teleporters, 1, storage.ring_teleporter_teleporters[entity.unit_number]) -- Src teleporter

    for i, teleporter_data in ipairs(teleporters) do
        local teleporter_entity = teleporter_data.entity
        if not teleporter_entity or not teleporter_entity.valid then
            goto continue  -- Skip invalid entities
        end

        if i > existing_rows then
            -- No existing row for this teleporter, skip to avoid adding new elements
            goto continue
        end

        -- Calculate the starting index of the row
        local row_start = header_count + (i - 1) * 6 + 1

        -- Get each cell in the row
        local table_children = teleporter_table.children
        local pos_btn = table_children[row_start]               -- Column 1: Position Button
        local nickname_cell = table_children[row_start + 1]     -- Column 2: Nickname Textfield/Label
        local force_label = table_children[row_start + 2]       -- Column 3: Force Name Label
        local charge_bar = table_children[row_start + 3]        -- Column 4: Charge Level Progress Bar
        local led_sprite = table_children[row_start + 4]        -- Column 5: Status Sprite (LED)
        local teleport_btn = table_children[row_start + 5]      -- Column 6: Teleport Button

        -- Update Position Button
        local position = teleporter_entity.position
        local force_name = teleporter_entity.force.name
        local charge_level = math.min(teleporter_entity.energy / (999999999 * storage.power_cost_multiplier), 1)

        -- Create the GPS tag
        local gps_tag = string.format("[gps=%d,%d,%s]", math.floor(position.x + 0.5), math.floor(position.y + 0.5), teleporter_entity.surface.name)

        local icon = gps_tag
        local planet = teleporter_entity.surface.planet
        local sname = teleporter_entity.surface.name
        if planet then
            icon = string.format("[planet=%s]", planet.name)
        elseif teleporter_entity.surface.platform then
            icon = "[img=item.space-platform-hub]"
            sname = teleporter_entity.surface.platform.name
        end

        local id = get_id_no_conditions(teleporter_entity)
        if id then
            sname = "ID " .. id .. " " .. sname:gsub("^%l", string.upper)
        else
            sname = sname:gsub("^%l", string.upper)
        end

        if #sname > 14 then
            sname = string.sub(sname, 1, 14) .. "..."
        end

        pos_btn.caption = icon .. " " .. sname
        pos_btn.tags = {gps_tag = gps_tag}

        if player.force.name == force_name then
            nickname_cell.enabled = true
        else
            nickname_cell.enabled = false
        end

        -- Update Force Name Label
        force_label.caption = force_name

        -- Update Charge Level Progress Bar
        charge_bar.value = charge_level

        -- Update Status Sprite (LED)
        local sprite = teleporter_data.occupied and "diode-yellow" or (charge_level >= 1 and "diode-green" or "diode-red")
        led_sprite.sprite = sprite

        -- Update Teleport Button
        if i == 1 then
            teleport_btn.enabled = false
        else
            teleport_btn.enabled = (charge_level >= 1) and (not teleporter_data.occupied) and this_charged
        end

        ::continue::
    end
end

local function manual_dial(player, src_unit_number, unit_number)
    local src_teleporter_data = storage.ring_teleporter_teleporters[src_unit_number]
    local dest_teleporter_data = storage.ring_teleporter_teleporters[unit_number]
    local can_teleport = not src_teleporter_data.occupied and not dest_teleporter_data.occupied
    if can_teleport then
        src_teleporter_data.occupied = true
        dest_teleporter_data.occupied = true
        util.schedule_after(300 - game.tick % 300, "timed_teleport_animation", {src_teleporter_data, dest_teleporter_data})
        player.print({"custom.manual-dial-success"})
    else
        player.print({"custom.occupied"})
    end
end

script.on_event(defines.events.on_gui_closed, function(event)
    local gui = event.element
    if gui and gui.valid and gui.name == "teleporter_gui" then
        gui.destroy()
        storage.ring_teleporter_GUIs[event.player_index] = nil
    end
end)

-- Handle GUI interactions
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element.valid then return end
    local player = game.players[event.player_index]

    -- Handle close button
    if element.name == "teleporter_close_button" then
        if player.gui.screen.teleporter_gui then
            player.gui.screen.teleporter_gui.destroy()
            storage.ring_teleporter_GUIs[player.index] = nil
        end
        return
    end

    -- Handle position button clicks
    if element.tags and element.tags.gps_tag then
        player.print(element.tags.gps_tag)
        return
    end

    -- Handle teleport buttons
    if element.tags and element.tags.src_unit_number and element.tags.unit_number then
        local src_number = element.tags.src_unit_number
        local unit_number = element.tags.unit_number

        -- Only proceed if the button is enabled
        if element.enabled then
            manual_dial(player, src_number, unit_number)
            if player.gui.screen.teleporter_gui then
                player.gui.screen.teleporter_gui.destroy()
                storage.ring_teleporter_GUIs[player.index] = nil
            end
        end
        return
    end
end)

-- Handle GUI opening
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity
    if entity then
        if entity.name == "ring-teleporter" then
            player.opened = nil  -- Prevent default GUI from opening
            local gui = player.gui.screen.teleporter_gui
            if gui and gui.tags and entity.unit_number == gui.tags.unit_number then
                storage.ring_teleporter_GUIs[player.index] = nil
                if gui.valid then
                    gui.destroy()
                end
            else
                create_teleporter_gui(player, entity)
            end
        end
    end
end)

local function update_GUI_for_everyone()
    for _, player in pairs(game.players) do
        -- Has GUI open? Otherwise ignore
        if player.gui.screen.teleporter_gui then
            update_teleporter_gui(player, nil)
        end
    end
end

local function on_built(event)
    local entity = event.entity
    if entity.name == "ring-teleporter" then
        local surf = entity.surface
        local renderer = surf.create_entity{
            name = "ring-teleporter-sprite",
            position = util.add_positions({x = entity.position.x - 4.5, y = entity.position.y - 4.5}, entity_shift),
            force = entity.force,
            raise_built = false,
            create_build_effect_smoke = true,
        }
        renderer.destructible = false
        storage.ring_teleporter_teleporters[entity.unit_number] = {entity = entity, renderer = renderer, occupied = false}
        local poskey = util.poskey(entity)
        storage.ring_teleporter_nicknames[poskey] = util.backername()
        update_GUI_for_everyone()
    end
    if entity.name == "ring-teleporter-placer" then
        local surf = entity.surface
        local teleporter = surf.create_entity{
            name = "ring-teleporter",
            position = {x = entity.position.x + 4.5, y = entity.position.y + 4.5},
            raise_built = false,
            force = entity.force,
            create_build_effect_smoke = true,
        }
        local renderer = surf.create_entity{
            name = "ring-teleporter-sprite",
            position = util.add_positions(entity.position, entity_shift),
            force = entity.force,
            raise_built = false,
            create_build_effect_smoke = true,
        }
        renderer.destructible = false
        storage.ring_teleporter_teleporters[teleporter.unit_number] = {entity = teleporter, renderer = renderer, occupied = false}
        local poskey = util.poskey(teleporter)
        storage.ring_teleporter_nicknames[poskey] = util.backername()
        entity.destroy()
        update_GUI_for_everyone()
    end
end

local function on_entity_removed(event)
    local entity = event.entity
    if entity.name == "ring-teleporter" then
        local data = storage.ring_teleporter_teleporters[entity.unit_number]
        if data then
            if data.animation1 and data.animation1.valid then
                data.animation1.destroy()
            end
            if data.animation2 and data.animation2.valid then
                data.animation2.destroy()
            end
            if data.renderer and data.renderer.valid then
                data.renderer.destroy()
            end
        end
        storage.ring_teleporter_teleporters[entity.unit_number] = nil
        update_GUI_for_everyone()
    end
end

script.on_event(defines.events.on_built_entity, function(event)
    on_built(event)
end, event_filter)

script.on_event(defines.events.on_robot_built_entity, function(event)
    on_built(event)
end, event_filter)

script.on_event(defines.events.on_space_platform_built_entity, function(event)
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

script.on_event(defines.events.on_space_platform_pre_mined, function(event)
    on_entity_removed(event)
end)

local function GUI_update()
    -- Loop through all players who have the GUI open
    for player_index, gui_data in pairs(storage.ring_teleporter_GUIs or {}) do        
        local player = game.players[player_index]
        if player and player.valid and player.gui.screen.teleporter_gui then
            update_teleporter_gui(player, gui_data.entity)
        else
            -- Player is invalid or GUI is closed; remove from the table
            storage.ring_teleporter_GUIs[player_index] = nil
        end
        -- Distance check
        --[[
        local character = game.get_player(player_index).character
        if character then
            if util.distance(character.position, gui_data.pos) > 10 then
                local gui = gui_data.gui
                if gui and gui.valid then
                    gui_data.gui.destroy()
                    storage.ring_teleporter_GUIs[player_index] = nil
                end
            end
        end
        ]]
    end
end

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
                    if signal and signal ~= 0 and entity.energy >= 999999999 * storage.power_cost_multiplier then -- 1 GJ
                        signal_teleport(data, signal)
                        triggered = true
                    end
                end
                if not triggered and network_green then
                    local signal = network_green.get_signal({type="virtual", name="goto-ring-id"})
                    if signal and signal ~= 0 and entity.energy >= 999999999 * storage.power_cost_multiplier then -- 1 GJ
                        signal_teleport(data, signal)
                    end
                end
            end
        end
    end
    GUI_update()
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

script.on_event(defines.events.on_gui_text_changed, function(event)
    local elem = event.element
    if elem and elem.tags and elem.tags.txtfield_type == "telep-nickname" then
        if elem.tags.poskey then
            storage.ring_teleporter_nicknames[elem.tags.poskey] = elem.text
        end
    end
end)

-- Finally define functions, that can be scheduled.
Function_map = {
    barrier_start = barrier_start,
    destroy_barrier = destroy_barrier,
    destroy_animations = destroy_animations,
    timed_teleport = timed_teleport,
    timed_teleport_animation = timed_teleport_animation,
    After_player_teleport_sound = After_player_teleport_sound
}

commands.add_command(
    "ring-remap",
    "Run this if you encounter bugs releated to transport rings, it may fix some.",

    function(command)
        -- Get the player who executed the command
        local player = game.players[command.player_index]
        -- Check if the player is an admin
        if player and player.admin then
            log("Player triggered remap!")
            remap_teleporters()
            player.print("Remap complete.")
        else
            player.print("You do not have admin permissions in this game.")
        end
    end
)
