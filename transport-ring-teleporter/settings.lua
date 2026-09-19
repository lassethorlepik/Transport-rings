local Util = require( "scripts/Util" )

-- Build the list of groups for the settings from the internal constants
local function group_to_array( group )
    local result = {}
    for _, name in pairs( group ) do
        result[ #result + 1 ] = name
    end
    return result
end

local robot_group = Util.robot_group
local robot_groups = group_to_array( robot_group )

-- Filter available recipe groups based on installed DLCs and mods so an invalid selection cannot be made
local recipe_groups = Util.recipe_groups
local valid_recipe_groups = {}
valid_recipe_groups[ 1 ] = recipe_groups.original
if Util.SA_Installed()   then valid_recipe_groups[ #valid_recipe_groups + 1 ] = recipe_groups.space_age end
if Util.K2SE_Installed() then valid_recipe_groups[ #valid_recipe_groups + 1 ] = recipe_groups.krastorio end

data:extend({
    {
        type = "double-setting",
        name = "trt-train-limit",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 0,
        maximum_value = 32,
        order = "[trt]-a1"
    },
    
    {
        type = "string-setting",
        name = "trt-teleport-robots",
        setting_type = "runtime-global",
        default_value = robot_group.combat,    -- Default to combat only
        allowed_values = robot_groups,
        order = "[trt]-b1"
    },
    
    {
        type = "double-setting",
        name = "trt-power-multiplier",
        setting_type = "startup",
        default_value = Util.K2SE_Installed() and 5 or 1,
        minimum_value = 0,
        maximum_value = 10000,
        order = "[trt]-c1"
    },
    {
        type = "double-setting",
        name = "trt-buffer-multiplier",
        setting_type = "startup",
        default_value = Util.K2SE_Installed() and 10 or 2,
        minimum_value = 0,
        maximum_value = 10000,
        order = "[trt]-c2"
    },
    
    {
        type = "bool-setting",
        name = "trt-align-to-rail-grid",
        setting_type = "startup",
        default_value = true,
        order = "[trt]-d1"
    },
    
    {
        type = "string-setting",
        name = "trt-recipe-group",
        setting_type = "startup",
        default_value = recipe_groups.original,
        allowed_values = valid_recipe_groups,
        order = "[trt]-e1"
    }
})
