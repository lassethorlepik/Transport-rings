local Util = require( "scripts/Util" )

local recipe_groups = Util.recipe_groups
local recipe_group = Util.recipe_group()

-- DEV NOTE: 19/08/2026 : What is the point of these filters? Why do we need to do this?

--[[
local dr_tool = data.raw[ "tool" ]
local dr_tech = data.raw[ "technology" ]

local function filter_ingredients( source )
    local result = {}
    for _, ingredient in ipairs( source ) do
        if dr_tool[ ingredient[ 1 ] ] ~= nil then
            table.insert( result, ingredient )
        end
    end
    return result
end

local function filter_prerequisites( source )
    local result = {}
    for _, prerequisite in ipairs( source ) do
        if dr_tech[ prerequisite ] ~= nil then
            table.insert( result, prerequisite )
        end
    end
    return result
end
]]

-- Mk1 Tech

local mk1_prereq = ( recipe_group == recipe_groups.krastorio ) and
    {
        "se-linked-container",
        "kr-planetary-teleporter"
    } or
    {
        "space-science-pack",
        "circuit-network"
    }

local mk1_cost = ( recipe_group == recipe_groups.krastorio ) and 2000 or 1000
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

local mk1_tech = {
    type = "technology",
    name = "trt-mk1",
    icon = "__transport-ring-teleporter__/graphics/technology/rings.png",
    icon_size = 656,
    prerequisites = mk1_prereq,
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
        count = mk1_cost,
        ingredients = mk1_ingredients,
        time = 60
    },
}

--mk1_tech.unit.ingredients = filter_ingredients( mk1_tech.unit.ingredients )
--mk1_tech.prerequisites = filter_prerequisites( mk1_tech.prerequisites )


data:extend( { mk1_tech } )


--[[
local tech2 = {
    type = "technology",
    name = "trt-mk2",
    icon = "__transport-ring-teleporter__/graphics/technology/rings-2.png",
    icon_size = 1024,
    prerequisites = { "promethium-science-pack", "trt-mk1" },
    effects = {
        {
            type = "unlock-recipe",
            recipe = "trt-platform-mk2"
        },
        {
            type = "unlock-recipe",
            recipe = "trt-ring-mk2"
        },
        {
            type = "unlock-recipe",
            recipe = "trt-platform-mk2"
        },
    },
    unit = {
        count = 500,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
            { "chemical-science-pack", 1 },
            { "production-science-pack", 1 },
            { "utility-science-pack", 1 },
            { "space-science-pack", 1 },
            { "metallurgic-science-pack", 1 },
            { "electromagnetic-science-pack", 1 },
            { "cryogenic-science-pack", 1 },
            { "promethium-science-pack", 1 }
        },
        time = 60
    },
}

--mk2_tech.unit.ingredients = filter_ingredients( mk2_tech.unit.ingredients )
--mk2_tech.prerequisites = filter_prerequisites( mk2_tech.prerequisites )

data:extend( { mk2_tech } )

]]

-- Attempt to void restrictions set by other mods
data.raw[ "simple-entity-with-force"][ "trt-placer-mk1" ].surface_conditions = nil
data.raw[ "accumulator" ] [ "trt-platform-mk1" ].surface_conditions = nil
