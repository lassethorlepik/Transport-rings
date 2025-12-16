local Util = require( "scripts/Util" )

local grid_alignment = settings.startup[ "trt-align-to-rail-grid" ].value and 2 or 1

local mk1_wire = {
    wire = {
        red = {-0.48, 0.05},
        green = {0.7, 0}
    },
    shadow = {
        red = {-0.48, 0.15},
        green = {0.7, 0.1}
    },
}
local output_port_wire = {
    wire = {
        red = { -0.125, 0 },
        green = { 0.125, 0 }
    },
    shadow = {
        red = { -0.125, 0 },
        green = { 0.125, 0 }
    }
}

local invisible_icon = "__transport-ring-teleporter__/graphics/invisible.png"
local invisible_icon_size = 32

local invisible_sprite = {
    count = 1,
    filename = "__transport-ring-teleporter__/graphics/invisible.png",
    width = 1,
    height = 1,
    direction_count = 1
}

local proxy_anim = {
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
            shift = {0 - 4.5, -1.5 + 6.7 - 4.5 + 1.5}
        },
        {
            filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter.png",
            size = 512,
            scale = 0.8,
            shift = {0 - 4.5, -1.5 - 4.5 + 1.5}
        }
    }
}

local placement_collision_mask = {
    layers = {
        item=true,
        meltable=true,
        object=true,
        player=true,
        water_tile=true,
        is_object=true,
        is_lower_object=true,
        teleporter_ring=true,
    },
    not_colliding_with_itself=true,     -- Stops placement object from breaking blueprint wires, but comes with the drawback of teleporter overlap when it shouldn't be allowed - We'll hand that issue in code when an item is built.
}


data:extend({

    {   -- Transport ring collision layer
        type="collision-layer",
        name="teleporter_ring",
        hidden=true,
        hidden_in_factoriopedia=true,
    },

    {   -- Mk1 placer entity
        type = "simple-entity-with-force",
        name = "ring-teleporter-placer",
        flags = { "placeable-neutral", "player-creation", "not-rotatable" },
        collision_mask = placement_collision_mask,
        collision_box = {{-0.5, 0}, {0.9, 1.49}},
        selection_box = {{-1, -0.5}, {1.25, 1.75}},
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = {mining_time = 3, result = "ring-teleporter"},
        remove_decoratives = "true",
        max_health = 5000,
        animations = { layers = { proxy_anim } },
        order = "z[ring-teleporter]",
        subgroup = "transport",
        build_grid_size = grid_alignment,
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = Util.format_power_string( Util.power_buffer(), "J", "" ),
            input_flow_limit = Util.format_power_string( Util.power_buffer() / 10, "W", "" ),
            output_flow_limit = "0W"
        },
        localised_description = {"entity-description.ring-teleporter", Util.format_power_string( Util.power_per_teleport(), "J", " ")},
        factoriopedia_simulation = {
            init = "game.simulation.camera_position = {0, 0}\ngame.surfaces[1].create_entity{name = \"ring-teleporter-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.8"
        },
        --hidden=true,
        --hidden_in_factoriopedia=true,
    },
    {   -- Mk1 Placer item
        type = "item",
        name = "ring-teleporter",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "z2[ring-teleporter]",
        place_result = "ring-teleporter-placer",
        stack_size = 1,
        subgroup = "transport",
        --hidden = true,
        --hidden_in_factoriopedia = true,
    },

    {   -- Mk1 Controller entity
        type = "accumulator",
        name = "ring-teleporter",
        flags = { "placeable-neutral", "player-creation", "not-rotatable" },   -- Must still blueprint for wire connections
        collision_mask = placement_collision_mask,
        collision_box = {{-0.5, 0}, {0.9, 1.49}},
        selection_box = {{-1, -0.5}, {1.25, 1.75}},
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = {mining_time = 3, result = "ring-teleporter"},
        placeable_by = { { item = "ring-teleporter", count = 1 } },
        build_grid_size = grid_alignment,
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
        alert_icon_shift = {0.125, 0.5},
        --factoriopedia_simulation = {
        --    init = "game.simulation.camera_position = {0, 0}\ngame.surfaces[1].create_entity{name = \"ring-teleporter-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.8"
        --},
        localised_description = {"entity-description.ring-teleporter", Util.format_power_string( Util.power_per_teleport(), "J", " ")},
        hidden_in_factoriopedia = true,
        hidden = true,
    },
    {   -- Mk1 Controller blueprint item
        type = "item",
        name = "ring-teleporter-bp",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "z2[ring-teleporter]",
        place_result = "ring-teleporter",
        stack_size = 1,
        hidden = true,
        hidden_in_factoriopedia = true,
        subgroup = "transport"
    },

    {   -- Mk1 Controller recipe
        type = "recipe",
        name = "ring-teleporter",
        enabled = false,
        energy_required = 30,
        ingredients =
        {
            {type="item", name="beacon", amount=1},
            {type="item", name="concrete", amount=200},
            {type="item", name="low-density-structure", amount=200},
            {type="item", name="accumulator", amount=200},
            {type="item", name="transport-ring", amount=5},
            {type="item", name="display-panel", amount=1},
        },
        results = {{type="item", name="ring-teleporter", amount=1}},
        subgroup = "transport",
        order = "z2[ring-teleporter]"
    },
    {   -- Mk1 ring item
        type = "item",
        name = "transport-ring",
        icon = "__transport-ring-teleporter__/graphics/icons/ring.png",
        icon_size = 256,
        order = "z1[ring-teleporter]",
        stack_size = 5,
        subgroup = "transport"
    },
    {   -- Mk1 ring recipe
        type = "recipe",
        name = "transport-ring",
        enabled = false,
        energy_required = 10,
        ingredients =
        {
            {type="item", name="processing-unit", amount=50},
            {type="item", name="low-density-structure", amount=100},
            {type="item", name="accumulator", amount=50},
        },
        results = {{type="item", name="transport-ring", amount=1}},
        subgroup = "transport",
        order = "z1[ring-teleporter]"
    },

    {   -- Mk2 Controller item
        type = "item",
        name = "transport-ring-2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-2.png",
        icon_size = 256,
        order = "z3[ring-teleporter]",
        stack_size = 5,
        subgroup = "transport"
    },
    {   -- Mk2 Controller recipe
        type = "recipe",
        name = "transport-ring-2",
        enabled = false,
        energy_required = 20,
        ingredients =
        {
            {type="item", name="quantum-processor", amount=32},
            {type="item", name="low-density-structure", amount=100},
            {type="item", name="superconductor", amount=50},
            {type="item", name="supercapacitor", amount=100},
            {type="item", name="fusion-reactor-equipment", amount=1},
        },
        results = {{type="item", name="transport-ring-2", amount=1}},
        subgroup = "transport",
        order = "z3[ring-teleporter]"
    },
    {   -- Mk2 ring item
        type = "item",
        name = "ring-teleporter-2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter-2.png",
        icon_size = 256,
        order = "z4[ring-teleporter]",
        
        stack_size = 1,
        subgroup = "transport"
    },
    {   -- Mk2 ring recipe
        type = "recipe",
        name = "ring-teleporter-2",
        enabled = false,
        energy_required = 60,
        ingredients =
        {
            {type="item", name="beacon", amount=1},
            {type="item", name="radar", amount=1},
            {type="item", name="refined-concrete", amount=100},
            {type="item", name="low-density-structure", amount=100},
            {type="item", name="transport-ring-2", amount=5},
            {type="item", name="display-panel", amount=1},
            {type="item", name="superconductor", amount=200},
            {type="item", name="supercapacitor", amount=500},
            {type="item", name="quantum-processor", amount=128},
        },
        results = {{type="item", name="ring-teleporter-2", amount=1}},
        subgroup = "transport",
        order = "z4[ring-teleporter]"
    },
    {   -- Mk2 platform item
        type = "item",
        name = "ring-teleporter-2-platform",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-platform.png",
        icon_size = 256,
        order = "z5[ring-teleporter]",

        stack_size = 1,
        subgroup = "transport"
    },
    {   -- Mk2 platform recipe
        type = "recipe",
        name = "ring-teleporter-2-platform",
        enabled = false,
        energy_required = 1,
        ingredients =
        {
            {type="item", name="beacon", amount=1},
            {type="item", name="low-density-structure", amount=10},
            {type="item", name="display-panel", amount=1},
        },
        results = {{type="item", name="ring-teleporter-2-platform", amount=1}},
        subgroup = "transport",
        order = "z5[ring-teleporter]"
    },

    {   -- Mk1 sprite entity - Obsolete
        type = "simple-entity-with-force",
        name = "ring-teleporter-sprite",
        render_layer = "lower-object-overlay",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        hidden_in_factoriopedia = true,
        animations = mk1_sprite,
    },

    {   -- Mk1 Sprite and Train stop entity - to show name on map and be captured by blueprints
        type = "train-stop",
        name = "ring-teleporter-map-nickname",
        flags = { "placeable-off-grid", "placeable-neutral", "player-creation", "hide-alt-info", "not-deconstructable", "not-rotatable", "not-flammable", "no-copy-paste" },
        collision_mask = { layers = {} },
        selectable_in_game = false,
        --icon = invisible_icon,
        --icon_size = invisible_icon_size,
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = {mining_time = 3, result = "ring-teleporter-map-nickname"},
        --placeable_by = { { item = "ring-teleporter", count = 1 } }, -- No collision or selection box so the only way to isolate and remove this from a blueprint is it's own item
        max_health = 10,
        build_grid_size = grid_alignment,
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
        name = "ring-teleporter-map-nickname",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        place_result = "ring-teleporter-map-nickname",
        stack_size = 1,
        hidden_in_factoriopedia = true,
        hidden = true,
        flags = {},
    },


    {   -- Output port entity
        type = "constant-combinator",
        name = "ring-teleporter-output",
        hidden_in_factoriopedia = true,
        collision_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
        collision_mask = {layers={}},
        selection_box = { { -0.25, -0.25 }, { 0.25, 0.25 } },
        selection_priority = 70,
        --placeable_by = { { item = "ring-teleporter", count = 1 } }, -- Nice for pipetting but causes confusion with blueprints
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
        circuit_wire_connection_points = { output_port_wire, output_port_wire, output_port_wire, output_port_wire },
        item_slot_count = 1,
        hidden=true,
        hidden_in_factoriopedia = true,
    },
    {   -- Output port item (for blueprinting)
        type = "item",
        name = "ring-teleporter-output",
        hidden=true,
        hidden_in_factoriopedia = true,
        --icon_size = invisible_icon_size,
        --icon = invisible_icon,
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        subgroup = "circuit-network",
        order = "zzz",
        place_result = "ring-teleporter-output",
        stack_size = 50,
        flags = { "hide-from-bonus-gui" }
    },


    {   -- New animation which isn't frame-tick locked, allowing more granual teleportations
        type = "animation",
        name = "ring-teleporter-back-anim",
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
                --shift = {0, -1.5 + 6.7},
                shift = { 0 - 4.5, -1.5 + 6.7 - 4.5 + 1.5 },
            },
            {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-back.png",
                size = 512,
                frame_count = 200,
                line_length = 16,
                scale = 0.8,
                animation_speed = 0.6666667,
                repeat_count = 1,
                --shift = {0, -1.5},
                shift = { 0 - 4.5, -1.5 - 4.5 + 1.5 },
            }
        }
    },
    {   -- New animation which isn't frame-tick locked, allowing more granual teleportations
        type = "animation",
        name = "ring-teleporter-front-anim",
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


    {   -- Obsolete, see the animations above
        type = "simple-entity-with-force",
        name = "ring-teleporter-back",
        render_layer = "object-under",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        hidden_in_factoriopedia=true,
        animations = {
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
                    shift = {0, -1.5 + 6.7}
                },
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-back.png",
                    size = 512,
                    frame_count = 200,
                    line_length = 16,
                    scale = 0.8,
                    animation_speed = 0.6666667,
                    repeat_count = 1,
                    shift = {0, -1.5}
                }
            }
        }
    },
    {   -- Obsolete, see the animations above
        type = "simple-entity-with-force",
        name = "ring-teleporter-front",
        render_layer = "cargo-hatch",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        hidden_in_factoriopedia=true,
        animations = {
            layers = {
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-front.png",
                    size = 512,
                    frame_count = 200,
                    line_length = 16,
                    scale = 0.8,
                    animation_speed = 0.6666667,
                    repeat_count = 1,
                    shift = {0, -1.5}
                },
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/light-medium.png",
                    size = 300,
                    frame_count = 200,
                    scale = 8,
                    draw_as_light = true,
                    shift = {0, -1.5},
                    frame_sequence = {
                        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
                        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                    }
                }
            }
        },
    },


    {   -- Teleportation physics barrier
        type = "simple-entity",
        name = "ring-teleporter-barrier",
        destructible = false,
        resistances = {{type = "impact", percent = 100}},
        flags = {"placeable-off-grid"},
        collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_mask = {
            layers = {object = true, player = true},
            not_colliding_with_itself = true
        },
        hidden = true,
        hidden_in_factoriopedia=true,
    },


    {   -- Transport sound
        type = "sound",
        name = "ring-1",
        filename = "__transport-ring-teleporter__/sound/ring-1.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "ring-2",
        filename = "__transport-ring-teleporter__/sound/ring-2.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "ring-3",
        filename = "__transport-ring-teleporter__/sound/ring-3.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "ring-4",
        filename = "__transport-ring-teleporter__/sound/ring-4.ogg",
        volume = 1
    },
    {   -- Transport sound
        type = "sound",
        name = "ring-5",
        filename = "__transport-ring-teleporter__/sound/ring-5.ogg",
        volume = 1
    },

    {   -- Transport player sound
        type = "sound",
        name = "ring-end",
        filename = "__transport-ring-teleporter__/sound/ring-end.ogg",
        volume = 1
    },

    -- Input signals on controller
    {   -- Signal: ring-id
        type = "virtual-signal",
        name = "ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z1"
    },
    {   -- Signal: goto-ring-id
        type = "virtual-signal",
        name = "goto-ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/goto-ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z2"
    },
    {   -- Signal: shield-rings (protected)
        type = "virtual-signal",
        name = "shield-rings",
        icon = "__transport-ring-teleporter__/graphics/icons/shield-rings.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z3"
    },
    {   -- Signal: ring-timer
        type = "virtual-signal",
        name = "ring-timer",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-timer.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z4"
    },

    -- Output signals on output port
    {   -- Signal: ring-status
        type = "virtual-signal",
        name = "ring-status",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z5"
    },
    {   -- Signal: ring-status-low-power
        type = "virtual-signal",
        name = "ring-status-low-power",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-low-power.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z6"
    },
    {   -- Signal: ring-status-occupied
        type = "virtual-signal",
        name = "ring-status-occupied",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-occupied.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z7"
    },
    {   -- Signal: ring-status-waiting
        type = "virtual-signal",
        name = "ring-status-waiting",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-status-waiting.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z7"
    },


    {   -- GUI sprite: diode-red
        type = "sprite",
        name = "diode-red",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        --scale = 1.5,
        size = {
            32,
            32
        },
        x = 32
    },
    {   -- GUI sprite: diode-yellow
        type = "sprite",
        name = "diode-yellow",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        --scale = 1.5,
        size = {
            32,
            32
        },
        x = 64
    },
    {   -- GUI sprite: diode-green
        type = "sprite",
        name = "diode-green",
        filename = "__core__/graphics/status.png",
        flags = {
            "gui-icon"
        },
        --scale = 1.5,
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
    order = "t-[transport-ring-teleporter]"
  },
  {
    type = "tips-and-tricks-item",
    name = "transport-ring-teleporter",
    localised_name = {"custom.tips-title"},
    localised_description = {"custom.tips-description"},
    order = "a",
    trigger =
    {
      type = "research",
      technology = "teleporter-rings"
    },
	starting_status = "unlocked",
    is_title = true,
    indent = 0,
    icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
	icon_size = 656,
    category = "trt-guide",
  }
}


data:extend(tips)