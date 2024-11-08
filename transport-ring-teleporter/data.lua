data:extend({
    {
        type = "item",
        name = "ring-teleporter",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        order = "z[ring-teleporter]",
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
            {type="item", name="processing-unit", amount=300},
            {type="item", name="concrete", amount=200},
            {type="item", name="low-density-structure", amount=200},
            {type="item", name="accumulator", amount=500},
        },
        results = {{type="item", name="ring-teleporter", amount=1}},
        subgroup = "transport",
        order = "z[ring-teleporter]"
    },
    {
        type = "accumulator",
        name = "ring-teleporter",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-teleporter.png",
        icon_size = 256,
        flags = {"placeable-neutral", "player-creation"},
        minable = {mining_time = 1, result = "ring-teleporter"},
        factoriopedia_description = {"factoriopedia-description.ring-teleporter"},
        remove_decoratives = "true",
        max_health = 5000,
        corpse = "medium-remnants",
        dying_explosion = "medium-explosion",
        collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
        collision_mask = {
            layers = {water_tile = true}
        },
        chargable_graphics = {
            picture = {
                filename = "__transport-ring-teleporter__/graphics/entity/ring-teleporter/ring-teleporter-masked.png",
                    width = 512,
                    height = 512,
                    scale = 0.8,
            }
        },
        selection_box = {{3.5, 4}, {4.5, 5}},
        energy_source = {
            type = "electric",
            usage_priority = "secondary-input",
            buffer_capacity = "2GJ",
            input_flow_limit = "200MW"
        },
        circuit_connector = {
            points = {
                shadow = {
                    green = {3.8, 4.21},
                    red = {3.8, 4.26}
                },
                wire = {
                    green = {3.8, 4.2},
                    red = {3.8, 4.25}
                }
            }
        },
        circuit_wire_max_distance = 20,
        factoriopedia_simulation = {
            init = "game.simulation.camera_position = {0, 1}\n    game.surfaces[1].create_entity{name = \"ring-teleporter-back\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.surfaces[1].create_entity{name = \"ring-teleporter-front\", position = {0, 0}, raise_built = false, create_build_effect_smoke = false}    game.simulation.camera_zoom = 0.85"
        }
    },
    {
        type = "simple-entity-with-force",
        name = "ring-teleporter-sprite",
        destructible = false,
        render_layer = "lower-object-overlay",
        flags = {"placeable-off-grid"},
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
        type = "virtual-signal",
        name = "ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z[ring-id]"
    },
    {
        type = "virtual-signal",
        name = "goto-ring-id",
        icon = "__transport-ring-teleporter__/graphics/icons/goto-ring-id.png",
        icon_size = 64,
        subgroup = "virtual-signal",
        order = "z[ring-id]"
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
        type = "technology",
        name = "teleporter-rings",
        icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
        icon_size = 656,
        prerequisites = {"space-science-pack", "circuit-network"},
        effects = {
            {
                type = "unlock-recipe",
                recipe = "ring-teleporter"
            },
        },
        unit = {
            count = 1000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1}
            },
            time = 60
        },
    }
})
