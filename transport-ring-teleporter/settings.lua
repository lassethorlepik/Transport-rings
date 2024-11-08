-- settings.lua
data:extend({
    {
        type = "double-setting",
        name = "trt-train-limit",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 0,
        maximum_value = 32,
        order = "a"
    }
})
