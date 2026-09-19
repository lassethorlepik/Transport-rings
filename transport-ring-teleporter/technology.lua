local Util = require( "scripts/Util" )

local recipe_groups = Util.recipe_groups
local recipe_group = Util.recipe_group()

local mk1_prerequisites = ( recipe_group == recipe_groups.krastorio ) and
    {
        "se-linked-container",
        "kr-planetary-teleporter"
    } or
    {
        "space-science-pack",
        "circuit-network"
    }

local mk1_ingredients = ( recipe_group == recipe_groups.krastorio ) and
    {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "production-science-pack", 1 },
        { "utility-science-pack", 1 },
        { "space-science-pack", 1 },
        { "se-astronomic-science-pack-4", 1 },
        { "se-biological-science-pack-4", 1 },
        { "se-energy-science-pack-4", 1 },
        { "se-material-science-pack-4", 1 },
        { "se-deep-space-science-pack-4", 1 },
        { "se-kr-matter-science-pack-2", 1 },
        { "kr-singularity-tech-card", 1 }
    } or
    {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "chemical-science-pack", 1 },
        { "production-science-pack", 1 },
        { "utility-science-pack", 1 },
        { "space-science-pack", 1 }
    }

data:extend( {
    {
        type = "technology",
        name = "trt-mk1",
        icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
        icon_size = 656,
        prerequisites = mk1_prerequisites,
        effects = {
            {
                type = "unlock-recipe",
                recipe = "trt-ring-mk1"
            },
            {
                type = "unlock-recipe",
                recipe = "trt-platform-mk1"
            },
        },
        unit = {
            count = ( recipe_group == recipe_groups.krastorio ) and 2000 or 1000,
            ingredients = mk1_ingredients,
            time = 60
        },
    }
} )
