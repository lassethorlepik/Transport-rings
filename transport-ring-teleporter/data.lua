data:extend({
    {
        type = "item",
        name = "ring-teleporter",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "z2[ring-teleporter]",
        place_result = "ring-teleporter",
        stack_size = 1,
        subgroup = "transport"
    },
    {
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
    {
        type = "item",
        name = "transport-ring",
        icon = "__transport-ring-teleporter__/graphics/icons/ring.png",
        icon_size = 256,
        order = "z1[ring-teleporter]",
        stack_size = 5,
        subgroup = "transport"
    },
    {
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
    {
        type = "item",
        name = "transport-ring-2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-2.png",
        icon_size = 256,
        order = "z3[ring-teleporter]",
        stack_size = 5,
        subgroup = "transport"
    },
    {
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
    {
        type = "item",
        name = "ring-teleporter-2",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter-2.png",
        icon_size = 256,
        order = "z4[ring-teleporter]",
        
        stack_size = 1,
        subgroup = "transport"
    },
    {
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
    {
        type = "item",
        name = "ring-teleporter-2-platform",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-platform.png",
        icon_size = 256,
        order = "z5[ring-teleporter]",

        stack_size = 1,
        subgroup = "transport"
    },
    {
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
    {
        type = "simple-entity-with-force",
        name = "ring-teleporter-sprite",
        destructible = false,
        render_layer = "lower-object-overlay",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        animations = {
            layers = {
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter.png",
                    width = 512,
                    height = 512,
                    scale = 0.8
                }
            }
        }
    },
    {
        type = "simple-entity-with-force",
        name = "ring-teleporter-back",
        destructible = false,
        render_layer = "object-under",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        animations = {
            layers = {
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-back.png",
                    width = 512,
                    height = 512,
                    frame_count = 200,
                    line_length = 16,
                    scale = 0.8,
                    animation_speed = 0.6666667,
                    draw_as_glow = true,
                    repeat_count = 1
                }
            }
        }
    },
    {
        type = "simple-entity-with-force",
        name = "ring-teleporter-front",
        destructible = false,
        render_layer = "cargo-hatch",
        flags = {"placeable-off-grid"},
        collision_mask = {
            layers = {}
        },
        hidden = true,
        animations = {
            layers = {
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-front.png",
                    width = 512,
                    height = 512,
                    frame_count = 200,
                    line_length = 16,
                    scale = 0.8,
                    animation_speed = 0.6666667,
                    draw_as_glow = true,
                    repeat_count = 1
                }
            }
        }
    },
    {
        type = "sound",
        name = "ring-1",
        filename = "__transport-ring-teleporter__/sound/ring-1.ogg",
        volume = 1
    },
    {
        type = "sound",
        name = "ring-2",
        filename = "__transport-ring-teleporter__/sound/ring-2.ogg",
        volume = 1
    },
    {
        type = "sound",
        name = "ring-3",
        filename = "__transport-ring-teleporter__/sound/ring-3.ogg",
        volume = 1
    },
    {
        type = "sound",
        name = "ring-4",
        filename = "__transport-ring-teleporter__/sound/ring-4.ogg",
        volume = 1
    },
    {
        type = "sound",
        name = "ring-5",
        filename = "__transport-ring-teleporter__/sound/ring-5.ogg",
        volume = 1
    },
    {
        type = "sound",
        name = "ring-end",
        filename = "__transport-ring-teleporter__/sound/ring-end.ogg",
        volume = 1
    },
    {
        type = "virtual-signal",
        name = "ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z1"
    },
    {
        type = "virtual-signal",
        name = "goto-ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/goto-ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z2"
    },
    {
        type = "virtual-signal",
        name = "shield-rings",
        icon = "__transport-ring-teleporter__/graphics/icons/shield-rings.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z3"
    },
    { -- This exists to block movement through the rings while teleporter animation is active
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
        hidden = true
    },
    {
        type = "accumulator",
        name = "ring-teleporter",
        flags = {"placeable-neutral", "player-creation"},
        collision_box = {{-0.5, 0}, {0.9, 1.49}},
        selection_box = {{-1, -0.5}, {1.25, 1.75}},
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        minable = {mining_time = 3, result = "ring-teleporter"},
        remove_decoratives = "true",
        max_health = 5000,
        corpse = "medium-remnants",
        dying_explosion = "medium-explosion",
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = "2GJ",
            input_flow_limit = "200MW"
        },
        circuit_connector = {
            points = {
                shadow = {
                    green = {0.7, 0.01},
                    red = {-0.48, 0.06}
                },
                wire = {
                    green = {0.7, 0},
                    red = {-0.48, 0.05}
                }
            }
        },
        circuit_wire_max_distance = 20,
        factoriopedia_simulation = {
            init = "game.simulation.camera_position = {0, 1}\ngame.surfaces[1].create_entity{name = \"ring-teleporter-sprite\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.85"
        }
    },
    {
        type = "simple-entity-with-force",
        name = "ring-teleporter-placer",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        destructible = false,
        remove_decoratives = "true",
        max_health = 5000,
        hidden = true,
        collision_box = {{-6, -2}, {6, 6}},
        selection_box = {{-6, -2}, {6, 6}},
        animations = {
            layers = {
                {
                    filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter.png",
                    width = 512,
                    height = 512,
                    scale = 0.8
                }
            }
        },
        order = "z[ring-teleporter]",
        subgroup = "transport",
        factoriopedia_simulation = {
            init = "game.simulation.camera_position = {0, 1}\ngame.surfaces[1].create_entity{name = \"ring-teleporter-sprite\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.85"
        }
    }
})
