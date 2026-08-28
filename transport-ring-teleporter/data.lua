local Util = require( "scripts/Util" )

local recipe_groups = Util.recipe_groups
local recipe_group = Util.recipe_group()

-- TODO:  Core has an invisible texture, update to use that

local invisible_icon = "__transport-ring-teleporter__/graphics/invisible.png"
local invisible_icon_size = 32

local invisible_sprite = {
    count = 1,
    filename = "__transport-ring-teleporter__/graphics/invisible.png",
    width = 1,
    height = 1,
    direction_count = 1
}




-- Common to all potential entities

local placement_collision_mask = {
    layers = {
        item = true,
        meltable = true,
        object = true,
        player = true,
        water_tile = true,
        is_object = true,
        is_lower_object = true,
        trt_teleporters = true,
    },
    not_colliding_with_itself = true,     -- Stops placement object from breaking blueprint wires, but comes with the drawback of teleporter overlap when it shouldn't be allowed - We'll hand that issue in code when an item is built.
}


data:extend( {

    {   -- Transport ring collision layer
        type = "collision-layer",
        name = "trt_teleporters",
        hidden = true,
        hidden_in_factoriopedia = true,
    },

} )


-- Mk1 Transporter

local mk1_wire = {
    wire = {
        red     = { -0.48 ,  0.05  },
        green   = {  0.7  ,  0.0   }
    },
    shadow = {
        red     = { -0.48 ,  0.15  },
        green   = {  0.7  ,  0.1   }
    },
}
local mk1_output_port_wire = {
    wire = {
        red     = { -0.125,  0.0   },
        green   = {  0.125,  0.0   }
    },
    shadow = {
        red     = { -0.125,  0.0   },
        green   = {  0.125,  0.0   }
    }
}


local mk1_proxy_anim = {
    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter.png",
    priority = "low",
    width = 512,
    height = 512,
    apply_projection = false,
    direction_count = 1,
    line_length = 1,
    shift = { -4.5, -4.5 },
    scale = 0.8
}


local mk1_sprite = {
    layers = {
        {
            filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-shadow-still.png",
            size = 256,
            scale = 4,
            draw_as_shadow = true,
            shift = { 0.0 - 4.5, -1.5 + 6.7 - 4.5 + 1.5 }
        },
        {
            filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter.png",
            size = 512,
            scale = 0.8,
            shift = { 0.0 - 4.5, -1.5 - 4.5 + 1.5 }
        }
    }
}

local mk1_teleporter_ingredients = ( recipe_group == recipe_groups.krastorio ) and
    {
        { type = "item", name = "se-wide-beacon-2"          , amount =   1 },
        { type = "item", name = "se-space-platform-plating" , amount = 200 },
        { type = "item", name = "se-nanomaterial"           , amount = 200 },
        { type = "item", name = "se-linked-container"       , amount =   1 },
        { type = "item", name = "kr-energy-storage"         , amount =   1 },
        { type = "item", name = "kr-matter-stabilizer"      , amount =  10 },
        { type = "item", name = "se-self-sealing-gel"       , amount =  10 },
        { type = "item", name = "se-naquium-processor"      , amount =  10 },
        { type = "item", name = "kr-planetary-teleporter"   , amount =   1 },
        { type = "item", name = "trt-ring-mk1"              , amount =   5 },
    } or ( recipe_group == recipe_groups.space_age ) and
    {
        { type = "item", name = "beacon"                    , amount =   1 },
        { type = "item", name = "space-platform-foundation" , amount =  80 },
        { type = "item", name = "processing-unit"           , amount = 200 },
        { type = "item", name = "accumulator"               , amount = 200 },
        { type = "item", name = "trt-ring-mk1"              , amount =   5 },
        { type = "item", name = "display-panel"             , amount =   1 },
    } or -- ( recipe_group == recipe_groups.original ) and
    {
        { type = "item", name = "beacon"                    , amount =   1 },
        { type = "item", name = "concrete"                  , amount = 200 },
        { type = "item", name = "low-density-structure"     , amount = 200 },
        { type = "item", name = "accumulator"               , amount = 200 },
        { type = "item", name = "trt-ring-mk1"              , amount =   5 },
        { type = "item", name = "display-panel"             , amount =   1 },
    }


local mk1_ring_ingredients = ( recipe_group == recipe_groups.krastorio ) and
    {
        { type = "item", name = "se-nanomaterial"           , amount =  50 },
        { type = "item", name = "kr-matter-stabilizer"      , amount =   5 },
        { type = "item", name = "se-self-sealing-gel"       , amount =   5 },
        { type = "item", name = "se-naquium-processor"      , amount =   1 },
        
    } or ( recipe_group == recipe_groups.space_age ) and
    {
        { type = "item", name = "copper-cable"              , amount =  50 },
        { type = "item", name = "steel-plate"               , amount =  50 },
        { type = "item", name = "low-density-structure"     , amount =  50 },
    } or -- ( recipe_group == recipe_groups.original ) and
    {
        { type = "item", name = "processing-unit"           , amount =  50 },
        { type = "item", name = "low-density-structure"     , amount = 100 },
        { type = "item", name = "accumulator"               , amount =  50 },
    }


data:extend( {

    {   -- Mk1 placer entity
        type = "simple-entity-with-force",
        name = "trt-placer-mk1",
        flags = { "placeable-neutral", "player-creation", "not-rotatable" },
        collision_mask = placement_collision_mask,
        collision_box = { { -0.5 ,  0.0  }, {  0.9 ,  1.49 } },
        selection_box = { { -1.0 , -0.5  }, {  1.25,  1.75 } },
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = { mining_time = 3, result = "trt-platform-mk1" },
        remove_decoratives = "true",
        max_health = 5000,
        animations = { layers = { mk1_proxy_anim } },
        order = "z[ring-teleporter]",
        subgroup = "transport",
        build_grid_size = Util.grid_alignment(),
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = Util.format_power_string( Util.power_buffer(), "J", "" ),
            input_flow_limit = Util.format_power_string( Util.power_buffer() / 10, "W", "" ),
            output_flow_limit = "0W"
        },
        localised_description = { "entity-description.ring-teleporter", Util.format_power_string( Util.power_per_teleport(), "J", " " ) },
        factoriopedia_simulation = {
            init = "game.simulation.camera_position = {0, 0}\ngame.surfaces[1].create_entity{name = \"trt-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"trt-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.8"
        },
        --hidden = true,
        --hidden_in_factoriopedia = true,
    },
    {   -- Mk1 Placer item
        type = "item",
        name = "trt-platform-mk1",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "[trt]-a2",
        place_result = "trt-placer-mk1",
        stack_size = 1,
        subgroup = "transport",
        --hidden = true,
        --hidden_in_factoriopedia = true,
    },

    {   -- Mk1 Controller entity
        type = "accumulator",
        name = "trt-platform-mk1",
        flags = { "placeable-neutral", "player-creation", "not-rotatable" },   -- Must still blueprint for wire connections
        collision_mask = placement_collision_mask,
        collision_box = { { -0.5 ,  0.0  }, {  0.9 ,  1.49 } },
        selection_box = { { -1.0 , -0.5  }, {  1.25,  1.75 } },
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = { mining_time = 3, result = "trt-platform-mk1" },
        placeable_by = { { item = "trt-platform-bp-mk1", count = 1 } },         -- Fixes blueprinting issues in 2.1 somehow?
        build_grid_size = Util.grid_alignment(),
        remove_decoratives = "true",
        max_health = 5000,
        corpse = "medium-remnants",
        dying_explosion = "medium-explosion",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = Util.format_power_string( Util.power_buffer(), "J", "" ),
            input_flow_limit = Util.format_power_string( Util.power_buffer() / 10, "W", "" ),
            output_flow_limit = "0W"
        },
        circuit_connector = { points = mk1_wire },
        circuit_wire_max_distance = 20,
        alert_icon_shift = { 0.125, 0.5  },
        --factoriopedia_simulation = {
        --    init = "game.simulation.camera_position = {0, 0}\ngame.surfaces[1].create_entity{name = \"trt-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"trt-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.8"
        --},
        localised_description = { "entity-description.ring-teleporter", Util.format_power_string( Util.power_per_teleport(), "J", " " ) },
        hidden_in_factoriopedia = true,
        hidden = true,
    },
    {   -- Mk1 Controller blueprint item
        type = "item",
        name = "trt-platform-bp-mk1",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "[trt]-bp1",
        place_result = "trt-platform-mk1",
        stack_size = 1,
        hidden = true,
        hidden_in_factoriopedia = true,
        subgroup = "transport"
    },

    {   -- Mk1 Controller recipe
        type = "recipe",
        name = "trt-platform-mk1",
        enabled = false,
        energy_required = 30,
        ingredients = mk1_teleporter_ingredients,
        results = {
            {
                type = "item",
                name = "trt-platform-mk1",
                amount = 1
            }
        },
        subgroup = "transport",
        order = "[trt]-a2"
    },
    {   -- Mk1 ring item
        type = "item",
        name = "trt-ring-mk1",
        icon = "__transport-ring-teleporter__/graphics/icons/ring.png",
        icon_size = 256,
        order = "[trt]-a1",
        stack_size = 5,
        subgroup = "transport"
    },
    {   -- Mk1 ring recipe
        type = "recipe",
        name = "trt-ring-mk1",
        enabled = false,
        energy_required = 10,
        ingredients = mk1_ring_ingredients,
        results = {
            {
                type = "item",
                name = "trt-ring-mk1",
                amount = 1
            }
        },
        subgroup = "transport",
        order = "[trt]-a1"
    },

    --[[  REMOVED DUE TO LACK OF ENTITY GRAPHICS

    {   -- Mk2 Controller item
        type = "item",
        name = "trt-platform-mk2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-2.png",
        icon_size = 256,
        order = "z3[ring-teleporter]",
        stack_size = 5,
        subgroup = "transport"
    },
    {   -- Mk2 Controller recipe
        type = "recipe",
        name = "trt-platform-mk2",
        enabled = false,
        energy_required = 20,
        ingredients =
        {
            { type = "item", name = "quantum-processor"         , amount =  32 },
            { type = "item", name = "low-density-structure"     , amount = 100 },
            { type = "item", name = "superconductor"            , amount =  50 },
            { type = "item", name = "supercapacitor"            , amount = 100 },
            { type = "item", name = "fusion-reactor-equipment"  , amount =   1 },
        },
        results = { { type = "item", name = "trt-platform-mk2"  , amount =   1 } },
        subgroup = "transport",
        order = "z3[ring-teleporter]"
    },
    {   -- Mk2 ring item
        type = "item",
        name = "trt-ring-mk2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter-2.png",
        icon_size = 256,
        order = "z4[ring-teleporter]",
        
        stack_size = 1,
        subgroup = "transport"
    },
    {   -- Mk2 ring recipe
        type = "recipe",
        name = "trt-ring-mk2",
        enabled = false,
        energy_required = 60,
        ingredients =
        {
            { type = "item", name = "beacon"                    , amount =   1 },
            { type = "item", name = "radar"                     , amount =   1 },
            { type = "item", name = "refined-concrete"          , amount = 100 },
            { type = "item", name = "low-density-structure"     , amount = 100 },
            { type = "item", name = "trt-platform-mk2"          , amount =   5 },
            { type = "item", name = "display-panel"             , amount =   1 },
            { type = "item", name = "superconductor"            , amount = 200 },
            { type = "item", name = "supercapacitor"            , amount = 500 },
            { type = "item", name = "quantum-processor"         , amount = 128 },
        },
        results = { { type = "item", name = "trt-ring-mk2"      , amount =   1 } },
        subgroup = "transport",
        order = "z4[ring-teleporter]"
    },
    {   -- Mk2 platform item
        type = "item",
        name = "trt-2-platform",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-platform.png",
        icon_size = 256,
        order = "z5[ring-teleporter]",

        stack_size = 1,
        subgroup = "transport"
    },
    {   -- Mk2 platform recipe
        type = "recipe",
        name = "trt-2-platform",
        enabled = false,
        energy_required = 1,
        ingredients =
        {
            { type = "item", name = "beacon"                    , amount =   1 },
            { type = "item", name = "low-density-structure"     , amount =  10 },
            { type = "item", name = "display-panel"             , amount =   1 },
        },
        results = { { type = "item", name = "trt-2-platform"    , amount =   1 } },
        subgroup = "transport",
        order = "z5[ring-teleporter]"
    },

    ]]

    --[[ Mk1 sprite entity - Obsolete

    {
        type = "simple-entity-with-force",
        name = "trt-sprite",
        render_layer = "lower-object-overlay",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        hidden_in_factoriopedia = true,
        animations = mk1_sprite,
    },

    ]]

    {   -- Mk1 Sprite and Train stop entity - to show name on map and be captured by blueprints
        type = "train-stop",
        name = "trt-map-interface-mk1",
        flags = { "placeable-off-grid", "placeable-neutral", "player-creation", "hide-alt-info", "not-deconstructable", "not-rotatable", "not-flammable", "no-copy-paste" },
        collision_mask = { layers = {} },
        selectable_in_game = false,
        --icon = invisible_icon,
        --icon_size = invisible_icon_size,
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = { mining_time = 3, result = "trt-map-interface-mk1" },
        --placeable_by = { { item = "trt-platform-mk1", count = 1 } }, -- No collision or selection box so the only way to isolate and remove this from a blueprint is it's own item
        max_health = 10,
        build_grid_size = Util.grid_alignment(),
        animation_ticks_per_frame=20,
        integration_patch_render_layer = "lower-object-overlay",
        integration_patch = {
            north = mk1_sprite,
            east = mk1_sprite,
            south = mk1_sprite,
            west = mk1_sprite,
        },
        --circuit_wire_connection_points = { mk1_wire, mk1_wire, mk1_wire, mk1_wire },
        --circuit_wire_max_distance = 20,
        hidden = true,
        hidden_in_factoriopedia = true,
        friendly_map_color = { 0.25, 0.5, 1.0 },
        enemy_map_color = { 1.0, 0.5, 0.25 },
        alert_icon_scale = 0,       -- 0 scale alerts should hide the warning about not being connected to a rail
    },
    {   -- Mk1 Sprite and Train stop entity - blueprint item
        type = "item",
        name = "trt-map-interface-mk1",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "[trt]-bp2",
        place_result = "trt-map-interface-mk1",
        stack_size = 1,
        hidden_in_factoriopedia = true,
        hidden = true,
        flags = {},
    },


    {   -- Output port entity
        type = "constant-combinator",
        name = "trt-output-mk1",
        collision_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
        collision_mask = { layers = {} },
        selection_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
        selection_priority = 70,
        --placeable_by = { { item = "trt-platform-mk1", count = 1 } }, -- Nice for pipetting but causes confusion with blueprints
        minable = nil,
        maximum_wire_distance = 9,
        max_health = 10,
        --icon_size = 16,
        --icon = "__base__/graphics/icons/shapes/shape-circle.png",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        flags = { "placeable-off-grid", "placeable-neutral", "player-creation", "hide-alt-info", "not-on-map", "not-deconstructable", "not-rotatable", "not-flammable", "no-copy-paste" },
        circuit_wire_max_distance = 9,
        sprites = invisible_sprite, -- TODO:  Replace with proper sprite that will sit on the controller
        activity_led_sprites = invisible_sprite,
        activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
        circuit_wire_connection_points = { mk1_output_port_wire, mk1_output_port_wire, mk1_output_port_wire, mk1_output_port_wire },
        item_slot_count = 1,
        hidden = true,
        hidden_in_factoriopedia = true,
    },
    {   -- Output port item - blueprint item
        type = "item",
        name = "trt-output-mk1",
        hidden = true,
        hidden_in_factoriopedia = true,
        --icon_size = invisible_icon_size,
        --icon = invisible_icon,
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        subgroup = "circuit-network",
        order = "[trt]-bp3",
        place_result = "trt-output-mk1",
        stack_size = 50,
        flags = { "hide-from-bonus-gui" }
    },


    {   -- New animation which isn't frame-tick locked, allowing more granual teleportations
        type = "animation",
        name = "trt-mk1-anim-back",
        layers = {
            {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-shadows.png",
                size = 256,
                frame_count = 200,
                line_length = 16,
                scale = 4,
                animation_speed = 0.6666667,
                --draw_as_shadow = true,
                repeat_count = 1,
                shift = { 0.0 - 4.5, -1.5 + 6.7 - 4.5 + 1.5 },
            },
            {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-back.png",
                size = 512,
                frame_count = 200,
                line_length = 16,
                scale = 0.8,
                animation_speed = 0.6666667,
                repeat_count = 1,
                shift = { 0.0 - 4.5, -1.5 - 4.5 + 1.5 },
            }
        }
    },
    {   -- New animation which isn't frame-tick locked, allowing more granual teleportations
        type = "animation",
        name = "trt-mk1-anim-front",
        layers = {
            {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-front.png",
                size = 512,
                frame_count = 200,
                line_length = 16,
                scale = 0.8,
                animation_speed = 0.6666667,
                repeat_count = 1,
                shift = { 0 - 4.5, -1.5 - 4.5 + 1.5 }
            },
            {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/light-medium.png",
                size = 300,
                frame_count = 200,
                scale = 8,
                draw_as_light = true,
                shift = { 0 - 4.5, -1.5 - 4.5 + 1.5 },
                frame_sequence = {
                    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
                    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                }
            }
        }
    },

    {   -- Teleportation physical barrier
        type = "simple-entity",
        name = "trt-barrier",
        destructible = false,
        resistances = { { type = "impact", percent = 100 } },
        flags = { "placeable-off-grid" },
        collision_box = { { -0.5, -0.5 }, {  0.5,  0.5 } },
        collision_mask = {
            layers = { object = true, player = true },
            not_colliding_with_itself = true
        },
        hidden = true,
        hidden_in_factoriopedia = true,
    },


    {   -- Transport sound
        type = "sound",
        name = "trt-teleport-1",
        filename = "__transport-ring-teleporter__/sound/ring-1.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "trt-teleport-2",
        filename = "__transport-ring-teleporter__/sound/ring-2.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "trt-teleport-3",
        filename = "__transport-ring-teleporter__/sound/ring-3.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "trt-teleport-4",
        filename = "__transport-ring-teleporter__/sound/ring-4.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "trt-teleport-5",
        filename = "__transport-ring-teleporter__/sound/ring-5.ogg",
        volume = 1
    },

    {   -- Transport player sound
        type = "sound",
        name = "trt-teleport-player",
        filename = "__transport-ring-teleporter__/sound/ring-end.ogg",
        volume = 1
    },

    -- Input signals on controller
    {   -- Signal: ring-id
        type = "virtual-signal",
        name = "trt-ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-a1"
    },
    {   -- Signal: goto-ring-id
        type = "virtual-signal",
        name = "trt-goto-id",
        icon = "__transport-ring-teleporter__/graphics/icons/goto-ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-a2"
    },
    {   -- Signal: protected
        type = "virtual-signal",
        name = "trt-protected",
        icon = "__transport-ring-teleporter__/graphics/icons/shield-rings.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-a3"
    },
    {   -- Signal: ring-timer
        type = "virtual-signal",
        name = "trt-timer",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-timer.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-a4"
    },

    -- Input signals on controller that control signals on the output port
    {   -- Signal: entity on platform
        type = "virtual-signal",
        name = "trt-entity-on-platform",
        icon = "__transport-ring-teleporter__/graphics/icons/entity-on-platform.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-b1"
    },
    {   -- Signal: inventory on entity
        type = "virtual-signal",
        name = "trt-inventory-on-entity",
        icon = "__transport-ring-teleporter__/graphics/icons/inventory-on-entity.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-b2"
    },
    {   -- Signal: read moving entities
        type = "virtual-signal",
        name = "trt-read-moving-entities",
        icon = "__transport-ring-teleporter__/graphics/icons/read-moving-entities.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-b3"
    },

    -- Output signals on output port
    {   -- Signal: ring-status
        type = "virtual-signal",
        name = "trt-status",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-c1"
    },
    {   -- Signal: ring-status-low-power
        type = "virtual-signal",
        name = "trt-status-low-power",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-low-power.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-c2"
    },
    {   -- Signal: ring-status-occupied
        type = "virtual-signal",
        name = "trt-status-occupied",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-occupied.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-c3"
    },
    {   -- Signal: ring-status-waiting
        type = "virtual-signal",
        name = "trt-status-waiting",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-waiting.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "[trt]-s-c4"
    },


    {   -- GUI sprite: diode-red
        type = "sprite",
        name = "trt-diode-red",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        size = {
            32,
            32
        },
        x = 32
    },
    {   -- GUI sprite: diode-yellow
        type = "sprite",
        name = "trt-diode-yellow",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        size = {
            32,
            32
        },
        x = 64
    },
    {   -- GUI sprite: diode-green
        type = "sprite",
        name = "trt-diode-green",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        size = {
            32,
            32
        }
    },

})


local tips =
{
    {
        type = "tips-and-tricks-item-category",
        name = "trt-guide",
        order = "[trt]-g1"
    },
    {
        type = "tips-and-tricks-item",
        name = "trt-teleporter",
        localised_name = { "custom.tips-title" },
        localised_description = { "custom.tips-description" },
        order = "[trt]-g1-1",
        trigger =
        {
            type = "research",
            technology = "trt-mk1"
        },
        starting_status = "unlocked",
        is_title = true,
        indent = 0,
        icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
        icon_size = 656,
        category = "trt-guide",
    }
}


data:extend( tips )
