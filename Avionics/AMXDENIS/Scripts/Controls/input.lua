return function(base, kind, config)
    assert(kind == "keyboard" or kind == "joystick", "Unknown input kind")
    assert(config.schema == "AMXDENIS_CONTROLS_1", "Unknown input contract")
    base.keyCommands, base.axisCommands = base.keyCommands or {}, base.axisCommands or {}
    local function key(spec, suffix, down, up)
        local entry = {name="AMXDENIS - " .. spec.label .. (suffix or ""), category="AMXDENIS cockpit",
            down=spec.id, value_down=down, cockpit_device_id=config.device}
        if up ~= nil then entry.up=spec.id; entry.value_up=up end
        -- Deliberately assignable: do not steal original key combinations or bind hardware.
        base.keyCommands[#base.keyCommands + 1] = entry
    end
    for _, spec in ipairs(config.controls) do
        if spec.available then
            if spec.kind == "button" then key(spec, "", 1, 0)
            elseif spec.kind == "momentary" then
                key(spec, " (+)", 1, 0)
                if spec.minimum < 0 then key(spec, " (-)", -1, 0) end
            elseif spec.kind == "egi" then
                for index, label in ipairs({" OFF", " STHD", " ALIGN", " NAV"}) do key(spec, label, index / 4) end
            elseif spec.kind == "mode" then
                for index, label in ipairs({" NAV", " A/G", " INT", " DGFT"}) do key(spec, label, index) end
            elseif spec.kind == "axis" then
                for _, value in ipairs({0,0.25,0.5,0.75,1}) do key(spec, " " .. value * 100 .. "%", value) end
                if kind == "joystick" then
                    base.axisCommands[#base.axisCommands + 1] = {name="AMXDENIS - " .. spec.label, action=assert(spec.axis_id),
                        cockpit_device_id=config.device, category="AMXDENIS cockpit"}
                end
            else
                for value = spec.minimum, spec.maximum do key(spec, " = " .. value, value) end
            end
        end
    end
    return base
end