dofile(current_mod_path .. "/Entry/weapons.lua")

amx_pilones_fm =
{
    pylon(1, 0, 0, 0, 0,
        {
            --arg = 308,
            --arg_value = 0.2,
            DisplayName = "1",
            use_full_connector_position = true,
            connector = "Pylon1",
        },
        montarRackList(AIM9_RACK_AMX)
    ),
    pylon(2, 0, 0, 0, 0,
        {
            arg = 309,
            arg_value = 0.2,
            DisplayName = "2",
            use_full_connector_position = true,
            connector = "Pylon2",
        },
        montarRackList(ROCKET_LEVES_AMX, BOMBAS_LEVES_AMX)
    ),
    pylon(3, 0, 0, 0, 0,
        {
            arg = 310,
            arg_value = 0.2,
            DisplayName = "3",
            use_full_connector_position = true,
            connector = "Pylon3",
        },
        montarRackList(ROCKET_LEVES_AMX, BOMBAS_LEVES_AMX)
    ),
    pylon(4, 0, 0, 0, 0,
        {
            arg = 311,
            arg_value = 0.2,
            DisplayName = "4",
            use_full_connector_position = true,
            connector = "Pylon4",
        },
        montarRackList(BOMBAS_LEVES_AMX)
    ),
    pylon(5, 0, 0, 0, 0,
        {
            arg = 312,
            arg_value = 0.2,
            DisplayName = "5",
            use_full_connector_position = true,
            connector = "Pylon5",
        },
        montarRackList(ROCKET_LEVES_AMX, BOMBAS_LEVES_AMX)
    ),
    pylon(6, 0, 0, 0, 0,
        {
            arg = 313,
            arg_value = 0.2,
            DisplayName = "6",
            use_full_connector_position = true,
            connector = "Pylon6",
        },
        montarRackList(ROCKET_LEVES_AMX, BOMBAS_LEVES_AMX)
    ),
    pylon(7, 0, 0, 0, 0,
        {
            --arg = 312,
            --arg_value = 0.2,
            DisplayName = "7",
            use_full_connector_position = true,
            connector = "Pylon8",
        },
        montarRackList(AIM9_RACK_AMX)
    ),

}
