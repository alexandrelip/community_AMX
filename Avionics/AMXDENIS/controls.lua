-- Build-time contract: one routing ID for both keyboard and the measured 3-D click.
return function(devices, command, keys, records)
    local result, used = {}, {}
    local connectors = {}
    for _, item in ipairs(records.Connectors) do
        connectors[item.name] = connectors[item.name] or {}
        table.insert(connectors[item.name], item)
    end
    local function add(name, label, owner, native, kind, minimum, maximum, argument, connector, state)
        assert(not used[name] and type(native) == "number" and type(owner) == "number", "Invalid control: " .. name)
        used[name] = true
        local spec = {name=name, label=label, owner=owner, native=native, kind=kind,
            minimum=minimum or 0, maximum=maximum or 1, id=3700 + #result + 1,
            state=state, available=true, keyboard=true, physical_mouse_validated=false}
        if connector then
            local matches = connectors[connector]
            if matches and #matches == 1 then
                local found = argument == nil
                for _, parent in ipairs(matches[1].ancestry) do
                    for _, field in ipairs({"rot_data", "pos_data", "scale_data"}) do
                        for _, track in ipairs(parent.node[field] or {}) do
                            if track[1] == argument then found = true end
                        end
                    end
                end
                assert(found, "Control argument not in REV07 ancestry: " .. name)
                spec.connector, spec.argument, spec.model_parent = connector, argument, matches[1].parent
                spec.mouse = true
            end
        end
        spec.mouse = spec.mouse or false
        spec.feedback = state or ("AMXDENIS_CONTROL_" .. name)
        if kind == "axis" then spec.axis_id = spec.id + 200 end
        if owner == devices.UFCP and kind ~= "axis" then spec.power = "ufcp" end
        if owner == devices.CMFD and kind ~= "set" then
            spec.power = name:match("^Mfd1") and "mfd1" or name:match("^Mfd2") and "mfd2" or "avionics"
        end
        result[#result + 1] = spec
        return spec
    end
    add("Battery", "Battery", devices.HOST_POWER, 3501, "set", 0, 1, nil, nil, "T_BATT")
    add("Generator1", "Generator 1", devices.HOST_POWER, 3502, "set", 0, 1, nil, nil, "T_GENEG")
    add("Generator2", "Generator 2", devices.HOST_POWER, 3503, "set", 0, 1, nil, nil, "T_GENED")
    add("Master", "Master Avionics", devices.ELEC_INTERFACE, command.AviMst, "set", 0, 1, 1843, "PNT_1843", "AMX_AVIONICS_SWITCH")
    add("SmsPower", "SMS power (inventory only)", devices.ELEC_INTERFACE, command.AviSms, "set", 0, 1, 1844, "PNT_1844", "AMX_SMS_SWITCH")
    add("Starter", "Engine starter STOP/NEUTRAL/START", devices.HOST_STARTER, 3504, "momentary", -1, 1, nil, nil, "AMX_ENGINE_START_SWITCH")
    add("FuelShutoff", "Engine fuel SHUT/OPEN", devices.HOST_STARTER, 3505, "set", 0, 1, nil, nil, "AMX_ENGINE_FUEL_OPEN")
    add("Gear", "Landing gear UP/DOWN (native request)", devices.HOST_MECHANISMS, 3506, "set", 0, 1, 6, "PTR-ARM-LAND-GEAR-084", "AMXDENIS_GEAR_SELECTED")
    add("Flaps", "Flaps UP/DOWN (native request; MID not integrated)", devices.HOST_MECHANISMS, 3507, "set", 0, 1, 59, "PNT_912", "AMX_FLAPS_HANDLE")
    add("Canopy", "Canopy toggle (native request)", devices.HOST_MECHANISMS, 3508, "button")
    add("Airbrake", "Airbrake IN/OUT", devices.HOST_MECHANISMS, 3509, "set", 0, 1, nil, nil, "AMXDENIS_AIRBRAKE_SELECTED")
    add("Mode", "Avionics master mode NAV/AG/INT/DGFT", devices.AVIONICS, keys.MasterModeSw, "mode", 1, 4)
    add("WaypointNext", "Next waypoint", devices.CMFD, command.NAV_INC_FYT, "button")
    add("WaypointPrevious", "Previous waypoint", devices.CMFD, command.NAV_DEC_FYT, "button")
    add("HudBrightness", "HUD brightness", devices.HUD, command.UFCP_HUD_BRIGHT, "axis", 0, 1, nil, nil, "AMX_HUD_DIMMER")
    add("CautionAcknowledge", "Acknowledge caution", devices.ALARM, command.CAUTION_PRESS, "button")
    local buttons = {{451,"COM1","COM1"},{452,"COM2","COM2"},{453,"NAVAIDS","NAVAIDS"},
        {454,"A_G","A/G"},{455,"NAV","NAV"},{456,"A_A","A/A"},{457,"BARO_RALT","BARO/RALT"},
        {469,"CLR","CLR"},{470,"ENTR","ENTR"},{473,"WARNRST","WARN RESET"},
        {474,"UP","INC"},{475,"DOWN","DEC"},{485,"JOY_RIGHT","CURSOR RIGHT"},
        {486,"JOY_LEFT","CURSOR LEFT"},{487,"JOY_UP","CURSOR UP"},{488,"JOY_DOWN","CURSOR DOWN"}}
    for digit = 1, 9 do buttons[#buttons + 1] = {458 + digit, tostring(digit), tostring(digit)} end
    buttons[#buttons + 1] = {468, "0", "0"}
    for _, button in ipairs(buttons) do
        add("Icp" .. button[2], "ICP " .. button[3], devices.UFCP, command["UFCP_" .. button[2]], "button",
            0, 1, button[1], "PNT_" .. button[1])
    end
    add("IcpDayNight", "ICP DAY/AUTO/NIGHT", devices.UFCP, command.UFCP_DAY_NIGHT, "set", -1, 1, 476, "PNT_476", "AMX_HUD_MODE")
    add("IcpRadarAltimeter", "Radar altimeter selector", devices.UFCP, command.UFCP_RALT, "set", 0, 1, 477, "PNT_477", "UFCP_RALT_SWITCH_STATE")
    add("IcpEgi", "EGI OFF/STHD/ALIGN/NAV (modelled)", devices.UFCP, command.UFCP_EGI, "egi", 0.25, 1, 479, "PNT_479")
    add("IcpBrightness", "ICP brightness", devices.UFCP, command.UFCP_UFC, "axis", 0, 1, 480, "PNT_480", "AMX_UFCP_BRIGHT")
    for side = 1, 2 do
        add("Mfd" .. side .. "Power", "MFD " .. side .. " power", devices.CMFD, command["CMFD" .. side .. "ButtonOn"], "set", 0, 1, nil, nil, "CMFD" .. side .. "SwOn")
        add("Mfd" .. side .. "Brightness", "MFD " .. side .. " brightness decrease/increase", devices.CMFD,
            command["CMFD" .. side .. "ButtonBright"], "momentary", -1, 1)
        for button = 1, 28 do
            add("Mfd" .. side .. "Oss" .. button, "MFD " .. side .. " OSS " .. button,
                devices.CMFD, command["CMFD" .. side .. "OSS" .. button], "button")
        end
    end
    return {schema="AMXDENIS_CONTROLS_1", model_sha256=records.ModelSHA256,
        device=devices.PILOT_INPUT, controls=result, native_validated=false}
end