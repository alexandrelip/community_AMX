-- Equipment outside this milestone has explicit unavailability, never surrogate data.
for _, name in ipairs({"RDR_ACTIVE", "RDR_TRACK_COUNT", "RWR_ON", "RWR_POWER", "RWR_THREAT_COUNT",
    "RADAR_STT_VALID", "RADAR_LS_ACTIVE", "RADAR_SHOOT_CUE", "RADAR_IN_RNG_CUE", "RDR_EXP_ALIVE",
    "RWR_BRIDGE_ALIVE", "DL_MODE", "HMD_ON", "FLIR_PILOT_ENABLED", "FLIR_TGT_AVAILABLE", "TGP_POWER"}) do
    get_param_handle(name):set(0)
    get_param_handle(name .. "_VALID"):set(0)
end
get_param_handle("AMXDENIS_RADAR_AVAILABLE"):set(0)
get_param_handle("AMXDENIS_RWR_AVAILABLE"):set(0)
get_param_handle("AMXDENIS_NATIVE_RADIO_AVAILABLE"):set(0)
need_to_be_closed = true