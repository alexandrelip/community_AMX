amx_lights_data_fm = {
    typename = "collection",
    lights = {
        -- STROBES
        [WOLALIGHT_STROBES] = {
            typename = "collection",
            lights = {
                { typename = "natostrobelight", argument = 193, period = 1.2, phase_shift = 0, color = { 0.9, 1.0, 0.7, 0.4 }, connector = "BANO_0_BACK" },
                --{typename = "argnatostrobelight", argument = 193, period = 1.2, phase_shift = 0, color = {0.9, 1.0, 0.7, 0.4}, connector = "BANO_0_BACK"},
            }
        },

        [WOLALIGHT_LANDING_LIGHTS] = {
            typename = "collection",
            lights = {
                { typename = "argumentlight", argument = 209, },
            },
        },
        [WOLALIGHT_TAXI_LIGHTS] = {
            typename = "collection",
            lights = {
                { typename = "argumentlight", argument = 208, },
            },
        },
        -- NAVLIGHTS
        [WOLALIGHT_NAVLIGHTS] = {
            typename = "collection",                 -- nav_lights_default
            lights = {
                { typename = "argumentlight", argument = 190 }, -- Left Position(red)
                { typename = "argumentlight", argument = 191 }, -- Right Position(green)
                { typename = "argumentlight", argument = 192 }, -- Tail Position white)
            },
        },
        -- FORMATION
        [WOLALIGHT_FORMATION_LIGHTS] = {
            typename = "collection",
            lights = {
                { typename = "argumentlight", argument = 200, }, --formation_lights_tail_1 = 200;
            },
        },
        [WOLALIGHT_REFUEL_LIGHTS] = {}, -- REFUEL
        [WOLALIGHT_BEACONS] = {},  -- STROBE / ANTI-COLLISION
        [WOLALIGHT_CABIN_NIGHT] = {}, --
    }
}
