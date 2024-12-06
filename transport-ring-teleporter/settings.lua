data:extend({
    {
        type = "double-setting",
        name = "trt-train-limit",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 0,
        maximum_value = 32,
        order = "a"
    },
    {
        type = "double-setting",
        name = "trt-power-multiplier",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 10000,
        order = "b"
    },
    {
        type = "double-setting",
        name = "trt-buffer-multiplier",
        setting_type = "startup",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 10000,
        order = "c"
    }
})
