local main_bus = get_param_handle("ELEC_P1")
local essential_bus = get_param_handle("ELEC_P2")
local battery = get_param_handle("AMX_ELEC_BATTERY_AVAILABLE")
local left_generator = get_param_handle("AMX_ELEC_GEN_L_AVAILABLE")
local right_generator = get_param_handle("AMX_ELEC_GEN_R_AVAILABLE")
local avionics_master = get_param_handle("AMX_AVIONICS_MASTER")
local sms_master = get_param_handle("AMX_SMS_MASTER")

function get_elec_main_dc_bus_ok()
    return main_bus:get() == 1
end

function get_elec_essential_dc_bus_ok()
    return essential_bus:get() == 1
end

function get_batt_on()
    return battery:get() == 1
end

function get_elec_generator_on()
    return left_generator:get() == 1 or right_generator:get() == 1
end

function get_avionics_master_on()
    return avionics_master:get() == 1
end

function get_vuhf_guard_on()
    return false
end

function get_sms_master_on()
    return sms_master:get() == 1
end