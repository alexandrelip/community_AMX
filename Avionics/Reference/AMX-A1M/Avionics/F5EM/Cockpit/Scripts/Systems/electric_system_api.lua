function get_elec_main_dc_bus_ok()
    return (get_batt_on() or get_elec_generator_on()) and true or false
end


function get_elec_essential_dc_bus_ok() -- essential DC bus
    return get_elec_generator_on()
end

----- api cockpit
function get_batt_on()
    return get_cockpit_draw_argument_value(387) == 1
end

local eng_left_rpm_param = get_param_handle("BASE_SENSOR_LEFT_ENGINE_RPM")
local eng_right_rpm_param = get_param_handle("BASE_SENSOR_RIGHT_ENGINE_RPM")

function get_elec_generator_on()
    return ((get_cockpit_draw_argument_value(388) == 1 and eng_left_rpm_param:get() > 0.4) or (get_cockpit_draw_argument_value(389) == 1 and eng_right_rpm_param:get() > 0.4))
end

function get_vuhf_guard_on()
    return false --get_cockpit_draw_argument_value(845) == 1
end



