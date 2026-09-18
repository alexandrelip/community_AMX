local specs = {
    {path = "CMFD/Device/cmfds.lua", tick = "CMFD", replacements = {
        {"get_cockpit_draw_argument_value(1843) > 0", "get_avionics_master_on()", 2},
    }, append = [[
local update_host_text = dofile(LockOn_Options.script_path .. "Systems/host_text.lua")(
    CMFD_TEXT, text_from_lua_function, get_param_handle, get_absolute_model_time)
local update_donor_cmfd = update
function update()
    update_donor_cmfd()
    update_host_text()
end
]]},
    {path = "CMFD/Indicator/CMFD_LT.lua", prepend = [[
local host_config = dofile(LockOn_Options.script_path .. "../../../../Config/AMX_AVIONICS.lua")
if host_config.native_flir ~= true then
    dofile(LockOn_Options.script_path .. "CMFD/Indicator/host_flir_unavailable.lua")
    return
end
]], replacements = {
        {"    text.element_params = {CMFD_BR}", '    text.formats = {"%s"}\n    text.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. callback}', 1},
        {'{"text_from_lua_function", callback, 0.5}', '{"text_using_parameter", 1, 0}', 1},
        {"laser_status.element_params = {CMFD_BR}", 'laser_status.formats = {"%s"}\nlaser_status.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. CMFD_TEXT.FLIR_LASER_STATUS}', 1},
        {'{"text_from_lua_function", CMFD_TEXT.FLIR_LASER_STATUS, 0.5}', '{"text_using_parameter", 1, 0}', 1},
        {"coords.element_params = {CMFD_BR}", 'coords.formats = {"%s"}\ncoords.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. CMFD_TEXT.FLIR_COORDS}', 1},
        {'{"text_from_lua_function", CMFD_TEXT.FLIR_COORDS, 0.5}', '{"text_using_parameter", 1, 0}', 1},
        {"date_text.element_params = {CMFD_BR}", 'date_text.element_params = {CMFD_BR, "AMX_CMFD_MISSION_TIME"}', 1},
        {'{"date_time"}', '{"text_using_parameter", 1, 0}', 1},
        {"DD-MM-YY HH:MM:SSL", "HH:MM:SSL", 1},
        {"laser_code.element_params = {CMFD_BR}", 'laser_code.formats = {"%s"}\nlaser_code.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. CMFD_TEXT.FLIR_LASER_CODE}', 1},
        {'{"text_from_lua_function", CMFD_TEXT.FLIR_LASER_CODE, 0.5}', '{"text_using_parameter", 1, 0}', 1},
        {"laser_range.element_params = {CMFD_BR}", 'laser_range.formats = {"%s"}\nlaser_range.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. CMFD_TEXT.FLIR_LRF_RANGE}', 1},
        {'{"text_from_lua_function", CMFD_TEXT.FLIR_LRF_RANGE, 0.5}', '{"text_using_parameter", 1, 0}', 1},
        {"target_info.element_params = {CMFD_BR}", 'target_info.formats = {"%s"}\ntarget_info.element_params = {CMFD_BR, "AMX_CMFD_TEXT_" .. CMFD_TEXT.FLIR_TARGET}', 1},
        {'{"text_from_lua_function", CMFD_TEXT.FLIR_TARGET, 0.5}', '{"text_using_parameter", 1, 0}', 1},
    }},
    {path = "CMFD/Indicator/CMFD_TSD.lua", replacements = {
        {'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")',
            'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")\nlocal amx_geometry = dofile(LockOn_Options.script_path .. "Indicator/host_geometry.lua")', 1},
        {'{"scale_using_parameter", 1, 1, 1}', '{"parameter_in_range", 1, 0.000001, 1000}', 1},
        {[[    addStrokeLine(nil, HSI_radius, {0, 0}, 0, boundary.name,
        nil, nil, nil, nil, CMFD_MATERIAL_CYAN)]],
            [[    amx_geometry.line(nil, "RDR_HSD_RANGE_SCALE", HSI_radius, boundary.name, CMFD_MATERIAL_CYAN)]], 1},
        {'wez.controllers = {{"scale_using_parameter", 0, HSI_radius / 0.03, 1}}',
            'wez.controllers = {{"parameter_in_range", 0, 0.000001, 1000}}', 1},
        {'addStrokeCircle(nil, 0.030, {0,0}, wez.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_RED")',
            'amx_geometry.circle("CMFD_RAP_THREAT_"..i.."_RADIUS", HSI_radius, wez.name, "CMFD_IND_RED")', 1},
    }},
    {path = "CMFD/Indicator/CMFD_MAP.lua", replacements = {
        {'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")',
            'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")\nlocal amx_geometry = dofile(LockOn_Options.script_path .. "Indicator/host_geometry.lua")', 1},
        {'wez.controllers = {{"scale_using_parameter", 0, MAP_RADIUS / 0.03, 1}}',
            'wez.controllers = {{"parameter_in_range", 0, 0.000001, 1000}}', 1},
        {'addStrokeCircle(nil, 0.030, {0,0}, wez.name, nil, nil, 0.5, 0.5, true, "CMFD_IND_RED")',
            'amx_geometry.circle("CMFD_RAP_THREAT_"..i.."_RADIUS", MAP_RADIUS, wez.name, "CMFD_IND_RED")', 1},
    }},
    {path = "CMFD/Indicator/CMFD_SURV.lua", replacements = {
        {'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")',
            'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")\nlocal amx_geometry = dofile(LockOn_Options.script_path .. "Indicator/host_geometry.lua")', 1},
        {[[    local link_line = addStrokeLine(surv_name("LINK_LINE_"..slot),
        SCOPE_RADIUS, {0,0}, 0, tactical.name, nil, nil, nil, nil,
        "CMFD_IND_MAGENTA")]],
            [[    local link_line = addSimpleLine(surv_name("LINK_LINE_"..slot),
        SCOPE_RADIUS, {0,0}, 0, tactical.name, nil, 0.004, "CMFD_IND_MAGENTA")]], 1},
        {'{"scale_using_parameter", 3, 1, 1}',
            '{"line_object_set_point_using_parameters", 1, 3, 3, 0, SCOPE_RADIUS * GetScale()}', 1},
        {'{"scale_using_parameter", 0, SCOPE_RADIUS / 0.03, 1}', '{"parameter_in_range", 0, 0.000001, 1000}', 1},
        {[[bright(addStrokeCircle(nil, 0.030, {0,0}, wez.name,
        nil, nil, 0.5, 0.5, true, "CMFD_IND_YELLOW"))]],
            [[bright(amx_geometry.circle("CMFD_RAP_THREAT_"..index.."_RADIUS", SCOPE_RADIUS, wez.name, "CMFD_IND_YELLOW"))]], 1},
    }},
    {path = "HUD/Device/hud.lua", tick = "HUD", replacements = {
        {"get_cockpit_draw_argument_value(1843) > 0", "get_avionics_master_on()", 1},
        {"get_cockpit_draw_argument_value(1483)", 'get_param_handle("AMX_HUD_DIMMER"):get()', 3},
        {"get_cockpit_draw_argument_value(1476)", 'get_param_handle("AMX_HUD_MODE"):get()', 1},
    }, append = [[
dofile(LockOn_Options.script_path .. "Systems/host_controls.lua")({
    [device_commands.UFCP_HUD_BRIGHT] = {name = "AMX_HUD_DIMMER", minimum = 0, maximum = 1},
})
]]},
    {path = "UFCP/Device/ufcp.lua", tick = "UFCP", replacements = {
        {"get_cockpit_draw_argument_value(1480)", 'get_param_handle("AMX_UFCP_BRIGHT"):get()', 2},
        {"get_cockpit_draw_argument_value(1843) > 0", "get_avionics_master_on()", 1},
    }, append = [[
dofile(LockOn_Options.script_path .. "Systems/host_controls.lua")({
    [device_commands.UFCP_UFC] = {name = "AMX_UFCP_BRIGHT", minimum = 0, maximum = 1},
    [device_commands.UFCP_DAY_NIGHT] = {name = "AMX_HUD_MODE", minimum = -1, maximum = 1},
})
local icp_format = get_param_handle("AMX_ICP_FORMAT")
local icp_edit_pos = get_param_handle("AMX_ICP_EDIT_POS")
local icp_edit_invalid = get_param_handle("AMX_ICP_EDIT_INVALID")
local update_donor_icp = update
function update()
    update_donor_icp()
    icp_format:set(ufcp_sel_format)
    icp_edit_pos:set(ufcp_edit_pos)
    icp_edit_invalid:set(ufcp_edit_invalid and 1 or 0)
end
]]},
    {path = "Systems/avionics.lua", tick = "AVIONICS", replacements = {
        {"get_cockpit_draw_argument_value(901)", 'get_param_handle("AMX_TRIM_AIL"):get()', 1},
        {"get_cockpit_draw_argument_value(902)", 'get_param_handle("AMX_TRIM_ELEV"):get()', 1},
        {'get_clickable_element_reference("THROTTLE_L_HANDLE")', "nil", 1},
        {'get_clickable_element_reference("THROTTLE_R_HANDLE")', "nil", 1},
        {"l_throttle:update()", "if l_throttle then l_throttle:update() end", 1},
        {"r_throttle:update()", "if r_throttle then r_throttle:update() end", 1},
    }},
    {path = "CMFD/Device/eicas.lua", replacements = {
        {'dofile(LockOn_Options.script_path.."Systems/engine_api.lua")',
            'dofile(LockOn_Options.script_path.."Systems/engine_api.lua")\nlocal host_eicas = dofile(LockOn_Options.script_path .. "Systems/host_eicas.lua")(sensor_data, get_param_handle)', 1},
        {"sensor_data.getEngineLeftRPM() * 100", 'host_eicas("E1_ROT")', 1},
        {"sensor_data.getEngineRightRPM() * 100", 'host_eicas("E2_ROT")', 1},
        {[[e1_temp = get_cockpit_draw_argument_value(12)
    if e1_temp <= 0.03 then e1_temp = e1_temp * 140/0.03
    elseif e1_temp <= 0.1 then e1_temp = 140 + (e1_temp-0.03) * 60/0.07
    elseif e1_temp <= 0.274 then e1_temp = 200 + (e1_temp-0.1) * 300/0.174
    elseif e1_temp <= 0.78 then e1_temp = 500 + (e1_temp-0.274) * 300/(0.78-0.174)
    else e1_temp = 800 + (e1_temp-0.78) * 400/(1-0.78)
    end]], 'e1_temp = host_eicas("E1_TEMP")', 1},
        {[[e2_temp = get_cockpit_draw_argument_value(14)
    if e2_temp <= 0.03 then e2_temp = e2_temp * 140/0.03
    elseif e2_temp <= 0.1 then e2_temp = 140 + (e2_temp-0.03) * 60/0.07
    elseif e2_temp <= 0.274 then e2_temp = 200 + (e2_temp-0.1) * 300/0.174
    elseif e2_temp <= 0.78 then e2_temp = 500 + (e2_temp-0.274) * 300/(0.78-0.174)
    else e2_temp = 800 + (e2_temp-0.78) * 400/(1-0.78)
    end]], 'e2_temp = host_eicas("E2_TEMP")', 1},
        {"sensor_data.getEngineLeftFuelConsumption()*60*60*2.20462", 'host_eicas("E1_FF")', 1},
        {"sensor_data.getEngineRightFuelConsumption()*60*60*2.20462", 'host_eicas("E2_FF")', 1},
        {"get_cockpit_draw_argument_value(22)*2500 + get_cockpit_draw_argument_value(23)*2500", 'host_eicas("FUEL_INTR")', 1},
        {"local fuel_cntr = round_to((fuel - fuel_intr)/3,5)", 'local fuel_cntr = host_eicas("FUEL_CNTR")', 1},
        {"local fuel_inbd = round_to((fuel - fuel_intr)/3*2,5)", 'local fuel_inbd = host_eicas("FUEL_INBD")', 1},
        {"get_cockpit_draw_argument_value(112)*100", 'host_eicas("E1_OIL_PRES")', 1},
        {"get_cockpit_draw_argument_value(113)*100", 'host_eicas("E2_OIL_PRES")', 1},
        {"EICAS.E1_OIL_PRES_POS:set(e1_oil_press_pos)",
            'EICAS.E1_OIL_PRES_POS:set(e1_oil_press_pos)\n    if get_param_handle("EICAS_E1_OIL_PRES_VALID"):get() ~= 1 then EICAS.E1_OIL_PRES_COLOR:set(-1) end', 1},
        {"EICAS.E2_OIL_PRES_POS:set(e2_oil_press_pos)",
            'EICAS.E2_OIL_PRES_POS:set(e2_oil_press_pos)\n    if get_param_handle("EICAS_E2_OIL_PRES_VALID"):get() ~= 1 then EICAS.E2_OIL_PRES_COLOR:set(-1) end', 1},
        {"get_cockpit_draw_argument_value(107)*100", 'host_eicas("E1_NOZZLE")', 1},
        {"get_cockpit_draw_argument_value(108)*100", 'host_eicas("E2_NOZZLE")', 1},
        {"get_cockpit_draw_argument_value(109)*4000", 'host_eicas("HYD_UTIL")', 1},
        {"get_cockpit_draw_argument_value(110)*4000", 'host_eicas("HYD_FLT")', 1},
        {[[        elseif (command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11) and EICAS_INIT:get() == 1 then
            fuel_init = fuel_init + 5
            EICAS.FUEL_INIT:set(fuel_init)
        elseif (command==device_commands.CMFD1OSS12 or command==device_commands.CMFD2OSS12) and EICAS_INIT:get() == 1 then
            fuel_init = fuel_init - 5
            EICAS.FUEL_INIT:set(fuel_init)
]], "", 1},
        {"register_as_cmfd_item(SUB_PAGE_ID.EICAS, post_initialize_eicas, update_eicas, SetCommandEicas)", [[local update_host_eicas = update_eicas
local update_host_fuel = dofile(LockOn_Options.script_path .. "Systems/host_fuel.lua")(get_param_handle)
function update_eicas()
    update_host_eicas()
    for _, name in ipairs({"FLOW_KG_MIN", "FUEL_KG", "HYD_1_BAR", "HYD_2_BAR", "NL", "NH", "TGT"}) do
        get_param_handle("EICAS_" .. name):set(host_eicas(name))
    end
    update_host_fuel()
end
register_as_cmfd_item(SUB_PAGE_ID.EICAS, post_initialize_eicas, update_eicas, SetCommandEicas)]], 1},
    }},
    {path = "Systems/sounds_callouts.lua", replacements = {
        {"local M = {}", 'local M = {}\nlocal host_runtime = dofile(LockOn_Options.script_path .. "../../runtime.lua")', 1},
        {"function M.play(id)", 'function M.play(id)\n    if host_runtime.voice_audio_available ~= true then return false end', 1},
    }},
    {path = "Systems/weapon_system_api.lua", append = [[
dofile(LockOn_Options.script_path .. "Systems/host_weapon_readiness.lua")(getfenv(1), get_param_handle)
]]},
    {path = "Systems/F5EM_EW_bridge_consumer.lua", replacements = {
        {"local ok, status = pcall(autoinstall_bridge_from_cockpit)",
            'local ok, status = true, "disabled by Alpha host"', 1},
    }},
    {path = "CMFD/Device/sms.lua", replacements = {
        {"for i=1,7 do", 'for i=1,dofile(LockOn_Options.script_path .. "Systems/host_stations.lua").count do', 1},
        {"get_cockpit_draw_argument_value(1844) > 0", "get_elec_essential_dc_bus_ok() and get_avionics_master_on() and get_sms_master_on()", 1},
        {([[    elseif command==device_commands.CMFD1OSS9 or command==device_commands.CMFD2OSS9 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO5_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS10 or command==device_commands.CMFD2OSS10 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO6_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO7_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS24 or command==device_commands.CMFD2OSS24 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO1_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS25 or command==device_commands.CMFD2OSS25 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO2_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS26 or command==device_commands.CMFD2OSS26 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO3_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)
    elseif command==device_commands.CMFD1OSS27 or command==device_commands.CMFD2OSS27 then
        sms_sj_sel = get_param_handle("WPN_SJ_STO4_SEL")
        sms_sj_sel:set((sms_sj_sel:get() + 1) % 2)]]):gsub(" then\n", " then \n"), [=[    else
        for _, station in ipairs(dofile(LockOn_Options.script_path .. "Systems/host_stations.lua").sj_buttons) do
            if command == device_commands["CMFD1OSS" .. station[1]] or command == device_commands["CMFD2OSS" .. station[1]] then
                local selection = get_param_handle("WPN_SJ_STO" .. station[2] .. "_SEL")
                selection:set((selection:get() + 1) % 2)
                break
            end
        end]=], 1},
    }},
    {path = "CMFD/Indicator/CMFD_SMS.lua", replacements = {
        {"local stores = 7", 'local stores = dofile(LockOn_Options.script_path .. "Systems/host_stations.lua").count', 2},
        {[[local sj_station_oss = {
    {9, 5}, {10, 6}, {11, 7},
    {24, 1}, {25, 2}, {26, 3}, {27, 4},
}]], 'local sj_station_oss = dofile(LockOn_Options.script_path .. "Systems/host_stations.lua").sj_buttons', 1},
        {'object = addOSSText(10, "ST6", SMS_submode_inv.name)', '', 1},
        {'object = addOSSText(11, "ST7", SMS_submode_inv.name)', '', 1},
        {[[object = addOSSStrokeBox(5, 1, SMS_mode_sj.name)
object.element_params = {default_element_params, "WPN_MASS", "WPN_LATEARM"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, WPN_MASS_IDS.LIVE}, {"parameter_compare_with_number", 2, WPN_LATEARM_IDS.ON}}]], [[object = addOSSStrokeBox(5, 1, SMS_mode_sj.name)
object.element_params = {default_element_params, "AMX_SJ_READY"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 1}}]], 1},
    }},
    {path = "Systems/weapon_system.lua", tick = "SMS", replacements = {
        {[[local sms_search_sequence = {
    {1, 7, 2, 6, 3, 5, 4},
    {7, 2, 6, 3, 5, 4, 1},
    {6, 3, 5, 4, 1, 7, 2},
    {5, 4, 1, 7, 2, 6, 3},
    {1, 7, 2, 6, 3, 5, 4},
    {4, 1, 7, 2, 6, 3, 5},
    {3, 5, 4, 1, 7, 2, 6},
    {2, 6, 3, 5, 4, 1, 7},
}]], 'local host_stations = dofile(LockOn_Options.script_path .. "Systems/host_stations.lua")\nlocal sms_search_sequence = host_stations.search', 1},
        {"local station_count = 7", "local station_count = host_stations.count", 1},
        {'wpn_sto_count[i+1] = station_info["count"]',
            'wpn_sto_count[i+1] = station_info["count"]\n            get_param_handle("AMX_SUITE_STORE_" .. (i+1)):set(station_info["count"])', 1},
        {"WPN_GUNS_R:set(wpn_guns_r)", "WPN_GUNS_R:set(0)", 1},
        {"if dev:get_flare_count() > 1 then", "if value == 1 and dev:get_flare_count() > 0 then", 2},
        {"if dev:get_chaff_count() > 1 then", "if value == 1 and dev:get_chaff_count() > 0 then", 2},
        {"dev:listen_command(iCommandPlaneDropChaffOnce)",
            "dev:listen_command(iCommandPlaneDropChaffOnce)\ndev:listen_command(cmds_commands.FlChButton)", 1},
        {"local function  update_ccip()", 'local normalize_ccip_solution = dofile(LockOn_Options.script_path .. "Systems/host_ballistics.lua")\nlocal function  update_ccip()', 1},
        {"valid, az, el, travel_dist = avSimplestWeaponSystem.CalculateRocket()",
            "valid, az, el, travel_dist = normalize_ccip_solution(avSimplestWeaponSystem.CalculateRocket())", 1},
        {"dev:emergency_jettison_rack(-1)", "dev:emergency_jettison_rack(i-1)", 1},
        {"set_wpn_sto_jet(i-1,0)", "set_wpn_sto_jet(i,0)", 1},
        {"wpn_ej_timeout = -0.5  -- abort E-J", [[wpn_ej_timeout = -3
            for station = 1, station_count do
                set_wpn_sto_jet(station, 0)
            end
            set_avionics_master_mode(get_avionics_master_mode_last())]], 1},
        {"for k, pos in pairs(sequence) do", "for k, pos in ipairs(sequence) do", 2},
        {"for k, i in pairs(sequence) do", "for k, i in ipairs(sequence) do", 1},
        {[[    if get_avionics_master_mode() ~= AVIONICS_MASTER_MODE_ID.SJ
        or get_wpn_mass() ~= WPN_MASS_IDS.LIVE
        or get_wpn_latearm() ~= WPN_LATEARM_IDS.ON
        or get_avionics_onground() then]], "    if not get_wpn_sj_ready() then", 1},
        {"if get_wpn_mass() ~= WPN_MASS_IDS.LIVE or get_wpn_latearm() ~= WPN_LATEARM_IDS.ON or get_avionics_onground() then",
            "if not get_wpn_sj_ready() then", 1},
        {"elseif ((master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) and storage_poll.ccip_piper_hidden:get() == 1 and not is_laser_guided_bomb_station(wpn_ag_sel)) then",
            "elseif ((master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) and wpn_sto_type[wpn_ag_sel] == WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB and storage_poll.ccip_piper_hidden:get() == 1 and not is_laser_guided_bomb_station(wpn_ag_sel)) then", 1},
        {"function launch_station(station)", [[function launch_station(station)
    if type(station) ~= "number" or station % 1 ~= 0 or station < 0 or station >= station_count
        or not (get_wpn_ag_ready() or get_wpn_aa_msl_ready()) then return end]], 1},
        {[[    if wpn_ripple_count > 0 then
        if master_mode == AVIONICS_MASTER_MODE_ID.CCRP]], [[    if wpn_ripple_count > 0 and not get_wpn_ag_ready() then
        wpn_ripple_count = 0
        wpn_ripple_elapsed = 0
        WPN.CCIP_DELAYED:set(0)
        WPN.WEAPON_RELEASE:set(0)
    end
    if wpn_ripple_count > 0 then
        if master_mode == AVIONICS_MASTER_MODE_ID.CCRP]], 1},
        {[[    if wpn_guns_on then
        wpn_guns_elapsed]], [[    get_param_handle("AMX_SMS_RELEASE_QUEUE"):set(wpn_ripple_count)
    get_param_handle("AMX_SJ_READY"):set(get_wpn_sj_ready() and 1 or 0)
    if wpn_guns_on then
        wpn_guns_elapsed]], 1},
    }},
    {path = "HUD/Indicator/HUD_AG.lua", replacements = {
        {[[HUD_CCIP_ROCKET_origin.element_params = {"WPN_SELECTED_WEAPON_TYPE"}
HUD_CCIP_ROCKET_origin.controllers = {
	{"parameter_compare_with_number",0,WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_ROCKET},
}]], [[HUD_CCIP_ROCKET_origin.element_params = {"WPN_SELECTED_WEAPON_TYPE", "WPN_CCIP_PIPER_AVAILABLE"}
HUD_CCIP_ROCKET_origin.controllers = {
	{"parameter_compare_with_number",0,WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_ROCKET},
	{"parameter_compare_with_number",1,1},
}]], 1},
    }},
    {path = "Systems/rwr.lua", tick = "RWR", replacements = {
        {"local dev=GetSelf()", 'local dev=GetSelf()\nlocal host_sensor_power = dofile(LockOn_Options.script_path .. "Systems/host_sensor_power.lua")(get_param_handle)', 1},
        {"rwr_power:set(1)", "rwr_power:set(0)", 1},
        {[[function update()
    local time_temp]], [[function update()
    local powered = host_sensor_power.apply_rwr(dev)
    if not powered then
        RWR.ON:set(0)
        RWR.THREAT_COUNT:set(0)
        RWR.THREAT_COUNT_PRI:set(0)
        RWR.TOP_THREAT_INDEX:set(0)
        RWR.TOP_THREAT_SIGNAL:set(0)
        RWR.TOP_THREAT_TYPE:set("")
        RWR.TOP_THREAT_DETAIL:set("")
        RWR_EFFECTIVE_SIGNAL:set(0)
        rwr_threat_table = {}
        rwrscan:stop()
        rwrtrack:stop()
        rwrlaunch:stop()
        return
    end
    local time_temp]], 1},
        {"dev:performClickableAction(device_commands.RWR, 0)", [[local birth = LockOn_Options.init_conditions.birth_place
    dev:performClickableAction(device_commands.RWR, (birth == "GROUND_HOT" or birth == "AIR_HOT") and 0 or -1)]], 1},
        {"dev:set_power(true)", "host_sensor_power.select_rwr(true)\n        host_sensor_power.apply_rwr(dev)", 1},
        {"dev:set_power(false)", "host_sensor_power.select_rwr(false)\n        host_sensor_power.apply_rwr(dev)", 1},
    }},
    {path = "Systems/rdr.lua", tick = "RADAR", prepend = [[
local host_sensor_power = dofile(LockOn_Options.script_path .. "Systems/host_sensor_power.lua")(get_param_handle)
]], replacements = {
        {"RDR.POWER:get() == 0 or RDR.OPR:get() == 0 or get_avionics_onground()", "not host_sensor_power.radar_ready()", 1},
    }},
    {path = "Systems/alarm_api.lua", append = [[
CAUTION_ID.BINGO = counter()
]]},
    {path = "Systems/alarm.lua", tick = "ALARM", prepend = [[
local host_alarm_labels = {
    ["LEFT GEN"] = "GEN 1", ["RIGHT GEN"] = "GEN 2",
    ["UTIL HYD"] = "HYD 1", ["FLT HYD"] = "HYD 2",
}
local function host_alarm_text(text)
    return host_alarm_labels[text] or text
end
]], replacements = {
        {[[local warn_translate = {}
warn_translate[531] = WARNING_ID.CANOPY

local caut_translate = {}
caut_translate[530] = CAUTION_ID.LEFT_GEN
caut_translate[532] = CAUTION_ID.RIGHT_GEN
caut_translate[533] = CAUTION_ID.UTIL_HYD
caut_translate[535] = CAUTION_ID.FLT_HYD
caut_translate[536] = CAUTION_ID.EXT_TANKS
caut_translate[538] = CAUTION_ID.OXYGEN
caut_translate[539] = CAUTION_ID.L_FUEL_LO
caut_translate[541] = CAUTION_ID.R_FUEL_LO
caut_translate[542] = CAUTION_ID.LEFT_F_P
caut_translate[543] = CAUTION_ID.AVIONICS
caut_translate[544] = CAUTION_ID.RIGHT_F_P

local adv_translate = {}
adv_translate[540] = ADVICE_ID.ANTI_ICE]], [[local host_alarm_active = dofile(LockOn_Options.script_path .. "Systems/host_alarm_sources.lua")(get_param_handle)
local warn_translate = {CANOPY_STATUS = WARNING_ID.CANOPY}
local caut_translate = {
    AMX_ELEC_GEN_L_AVAILABLE = CAUTION_ID.LEFT_GEN,
    AMX_ELEC_GEN_R_AVAILABLE = CAUTION_ID.RIGHT_GEN,
    L_HYD1 = CAUTION_ID.UTIL_HYD,
    L_HYD2 = CAUTION_ID.FLT_HYD,
    AMX_FUEL_BINGO_ACTIVE = CAUTION_ID.BINGO,
}
local adv_translate = {}]], 1},
        {"get_cockpit_draw_argument_value(i) > 0", "host_alarm_active(i)", 3},
        {"text_param:set(value.text)", "text_param:set(host_alarm_text(value.text))", 3},
        {"if i < 10 then", "if i <= 22 then", 3},
        {"while i <= 10 do", "while i <= 22 do", 1},
    }},
    {path = "UFCP/Device/egi.lua", replacements = {
        {"dev:performClickableAction(device_commands.UFCP_EGI, 0.15, true)",
            "dev:performClickableAction(device_commands.UFCP_EGI, 0.25, true)", 1},
    }},
    {path = "Systems/efi.lua", tick = "EFI"},
    {path = "FLIR/device.lua", tick = "FLIR", replacements = {
        -- The library reads this root handle as a bus voltage against electrical.voltage = {22, 29};
        -- the donor publishes the flag value 1, which fails get_screen_condition and leaves the
        -- camera render target black. Unbound, the sensor uses its own electrical model.
        {'power_bus_handle = "FLIR_ELEC"', 'power_bus_handle = nil', 1},
    }},
}

local function apply(spec, text)
    for _, replacement in ipairs(spec.replacements or {}) do
        local segments, cursor, count = {}, 1, 0
        while true do
            local first, last = text:find(replacement[1], cursor, true)
            if not first then break end
            segments[#segments + 1] = text:sub(cursor, first - 1)
            segments[#segments + 1] = replacement[2]
            cursor, count = last + 1, count + 1
        end
        assert(count == replacement[3], spec.path .. ": donor anchor count changed: " .. replacement[1])
        segments[#segments + 1] = text:sub(cursor)
        text = table.concat(segments)
    end
    text = (spec.prepend or "") .. text .. "\n" .. (spec.append or "")
    if spec.tick then
        text = text .. 'dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("' .. spec.tick .. '")\n'
    end
    assert(loadstring(text, "@" .. spec.path))
    return text
end

return {specs = specs, apply = apply, aircraft = {path = "Alpha native receiver registration", replacements = {
    {"Sensors = {", 'Sensors = { RWR = "Abstract RWR",', 1},
}}, flir_aircraft = {path = "Private Alpha LITENING compatibility probe", replacements = {
    {'use_full_connector_position=true,connector = "PYLON_R_IN",arg = 303,arg_value = -1.0\n\t\t\t},\n            {',
        'use_full_connector_position=true,connector = "PYLON_R_IN",arg = 303,arg_value = -1.0\n\t\t\t},\n            {\n                {CLSID = "{AAQ-28_LEFT}"},', 1},
}}}