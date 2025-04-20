local tech1 = {
    type = "technology",
    name = "teleporter-rings",
    icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
    icon_size = 656,
    prerequisites = {"space-science-pack", "circuit-network"},
    effects = {
        {
            type = "unlock-recipe",
            recipe = "transport-ring"
        },
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

local tech2 = {
    type = "technology",
    name = "teleporter-rings-advanced",
    icon = "__transport-ring-teleporter__/graphics/technology/rings-2.png",
    icon_size = 1024,
    prerequisites = {"promethium-science-pack", "teleporter-rings"},
    effects = {
        {
            type = "unlock-recipe",
            recipe = "transport-ring-2"
        },
        {
            type = "unlock-recipe",
            recipe = "ring-teleporter-2"
        },
        {
            type = "unlock-recipe",
            recipe = "ring-teleporter-2-platform"
        },
    },
    unit = {
        count = 500,
        ingredients = {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1},
            {"chemical-science-pack", 1},
            {"production-science-pack", 1},
            {"utility-science-pack", 1},
            {"space-science-pack", 1},
            {"metallurgic-science-pack", 1},
            {"electromagnetic-science-pack", 1},
            {"cryogenic-science-pack", 1},
            {"promethium-science-pack", 1}
        },
        time = 60
    },
}

local tech1_filtered_ingredients = {}
for _, ingredient in ipairs(tech1.unit.ingredients) do
    if data.raw["tool"][ingredient[1]] ~= nil then
        table.insert(tech1_filtered_ingredients, ingredient)
    end
end
tech1.unit.ingredients = tech1_filtered_ingredients

local tech1_filtered_prerequisites = {}
for _, prerequisite in ipairs(tech1.prerequisites) do
    if data.raw["technology"][prerequisite] ~= nil then
        table.insert(tech1_filtered_prerequisites, prerequisite)
    end
end
tech1.prerequisites = tech1_filtered_prerequisites

data:extend({tech1})

local tech2_filtered_ingredients = {}
for _, ingredient in ipairs(tech2.unit.ingredients) do
    if data.raw["tool"][ingredient[1]] ~= nil then
        table.insert(tech2_filtered_ingredients, ingredient)
    end
end
tech2.unit.ingredients = tech2_filtered_ingredients

local tech2_filtered_prerequisites = {}
for _, prerequisite in ipairs(tech2.prerequisites) do
    if data.raw["technology"][prerequisite] ~= nil then
        table.insert(tech2_filtered_prerequisites, prerequisite)
    end
end
tech2.prerequisites = tech2_filtered_prerequisites

data:extend({tech2})

-- Attempt to void restrictions set by other mods
data.raw["simple-entity-with-force"]["ring-teleporter-placer"].surface_conditions = nil
data.raw["accumulator"]["ring-teleporter"].surface_conditions = nil
