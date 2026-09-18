local indication = {}
local brightness = type(default_element_params) == "table" and default_element_params[1] or default_element_params

function indication.validated(producer)
    return function(name, position, parent, ...)
        local available = addPlaceholder(nil, {0, 0}, parent)
        available.element_params = {name .. "_VALID"}
        available.controllers = {{"parameter_compare_with_number", 0, 1}}
        local unavailable = addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X08,
            "CenterCenter", position, parent, nil, nil, CMFD_FONT_W)
        unavailable.element_params = {name .. "_VALID", brightness}
        unavailable.controllers = {{"parameter_compare_with_number", 0, 0}, {"opacity_using_parameter", 1}}
        return producer(name, position, available.name, ...)
    end
end

function indication.digital(parameter, position, parent)
    local available = addPlaceholder(nil, {0, 0}, parent)
    available.element_params = {parameter .. "_VALID"}
    available.controllers = {{"parameter_compare_with_number", 0, 1}}
    local unavailable = addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X1,
        "CenterCenter", position, parent, nil, nil, CMFD_FONT_W)
    unavailable.element_params = {parameter .. "_VALID", brightness}
    unavailable.controllers = {{"parameter_compare_with_number", 0, 0}, {"opacity_using_parameter", 1}}
    return addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X1,
        "CenterCenter", position, available.name, nil, {"%3.0f"}, CMFD_FONT_DEF)
end

function indication.fuel(name, position, parent)
    local origin = addPlaceholder(name, position, parent)
    addStrokeText(nil, "FUEL LB", CMFD_STRINGDEFS_DEF_X08, "CenterCenter",
        {0, 0.22}, origin.name, nil, nil, CMFD_FONT_W)
    for index, spec in ipairs({{"TOTAL", "EICAS_FUEL", "%05.0f"},
        {"INTR", "EICAS_FUEL_INTR_TEXT", "%s"}, {"CNTR", "EICAS_FUEL_CNTR_TEXT", "%s"},
        {"INBD", "EICAS_FUEL_INBD_TEXT", "%s"}}) do
        local vertical = 0.22 - index * 0.15
        addStrokeText(nil, spec[1], CMFD_STRINGDEFS_DEF_X08, "LeftCenter",
            {-0.20, vertical}, origin.name, nil, nil, CMFD_FONT_W)
        local value = addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X08, "RightCenter",
            {0.22, vertical}, origin.name, nil, {spec[3]}, CMFD_FONT_CYAN)
        value.element_params = {spec[2], brightness}
        value.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1}}
    end
    return origin
end

function indication.value(parameter, position, parent, format, font, stringdefs)
    stringdefs = stringdefs or CMFD_STRINGDEFS_DEF_X08
    local available = addPlaceholder(nil, {0, 0}, parent)
    available.element_params = {parameter .. "_VALID"}
    available.controllers = {{"parameter_compare_with_number", 0, 1}}
    local value = addStrokeText(nil, "", stringdefs, "RightCenter", position,
        available.name, nil, {format or "%3.0f"}, font or CMFD_FONT_CYAN)
    value.element_params = {parameter, brightness}
    value.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1}}
    local fallback = addStrokeText(nil, "---", stringdefs, "RightCenter", position,
        parent, nil, nil, CMFD_FONT_W)
    fallback.element_params = {parameter .. "_VALID", brightness}
    fallback.controllers = {{"parameter_compare_with_number", 0, 0}, {"opacity_using_parameter", 1}}
    return value
end

function indication.gauge(label, parameter, position, parent, maximum, format, unit)
    local origin = addPlaceholder(nil, position, parent)
    local radius = 0.18
    addStrokeCircle(nil, radius, {0, 0}, origin.name, nil, {math.rad(-60), math.rad(240)}, nil, nil, nil, CMFD_MATERIAL_WHITE)
    for index = 0, 5 do
        local angle = math.rad(240 - index * 60)
        addStrokeLine(nil, 0.025, {radius * math.cos(angle), radius * math.sin(angle)},
            math.deg(angle) - 90, origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    end
    local valid = addPlaceholder(nil, {0, 0}, origin.name)
    valid.element_params = {parameter .. "_VALID"}
    valid.controllers = {{"parameter_compare_with_number", 0, 1}}
    local needle = addPlaceholder(nil, {0, 0}, valid.name)
    needle.init_rot = {240}
    needle.element_params = {parameter}
    needle.controllers = {{"rotate_using_parameter", 0, math.rad(-300) / maximum}}
    addStrokeLine(nil, 0.15, {0, 0}, -90, needle.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X07, "CenterCenter", {0, 0.075}, origin.name, nil, nil, CMFD_FONT_W)
    addStrokeText(nil, unit, CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, -0.25}, origin.name, nil, nil, CMFD_FONT_W)
    indication.value(parameter, {0.16, -0.11}, origin.name, format, CMFD_FONT_W)
    return origin
end

function indication.alerts(parent, position, width, rows, row_height)
    local origin = addPlaceholder(nil, position, parent)
    for index = 1, rows do
        local vertical = -(index - 1) * row_height
        local visible = addPlaceholder(nil, {0, vertical}, origin.name)
        visible.element_params = {"EICAS_ERROR" .. index .. "_COLOR"}
        visible.controllers = {{"parameter_in_range", 0, 0.5, 5.5}}
        local fill = addFillBox(nil, width, row_height * 0.88, "CenterCenter", {0, 0}, visible.name, nil, CMFD_MATERIAL_WHITE)
        fill.additive_alpha = false
        fill.element_params = {"EICAS_ERROR" .. index .. "_COLOR", brightness}
        fill.controllers = {{"parameter_in_range", 0, 3.5, 5.5}, {"opacity_using_parameter", 1},
            {"change_color_when_parameter_equal_to_number", 0, 4, 1, 0, 0},
            {"change_color_when_parameter_equal_to_number", 0, 5, 1, 1, 0}}
        local value = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0},
            visible.name, nil, {"%s"}, CMFD_FONT_W)
        value.element_params = {"EICAS_ERROR" .. index .. "_TEXT", "EICAS_ERROR" .. index .. "_COLOR", brightness}
        value.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 2},
            {"change_color_when_parameter_equal_to_number", 1, 1, 1, 0, 0},
            {"change_color_when_parameter_equal_to_number", 1, 2, 1, 1, 0},
            {"change_color_when_parameter_equal_to_number", 1, 3, 0, 1, 1},
            {"change_color_when_parameter_equal_to_number", 1, 4, 0, 0, 0},
            {"change_color_when_parameter_equal_to_number", 1, 5, 0, 0, 0}}
        local border = addStrokeBox(nil, width, row_height * 0.88, "CenterCenter", {0, 0}, visible.name, nil, CMFD_MATERIAL_WHITE)
        border.element_params = {"EICAS_ERROR" .. index .. "_COLOR", brightness}
        border.controllers = {{"parameter_in_range", 0, 0.5, 3.5}, {"opacity_using_parameter", 1},
            {"change_color_when_parameter_equal_to_number", 0, 1, 1, 0, 0},
            {"change_color_when_parameter_equal_to_number", 0, 2, 1, 1, 0},
            {"change_color_when_parameter_equal_to_number", 0, 3, 0, 1, 1}}
    end
    return origin
end

function indication.systems(parent, position)
    local origin = addPlaceholder(nil, position, parent)
    addStrokeText(nil, "HYD", CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {-0.71, 0.06}, origin.name, nil, nil, CMFD_FONT_W)
    addStrokeText(nil, "TOT KG", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.37, 0.06}, origin.name, nil, nil, CMFD_FONT_W)
    local total = indication.value("EICAS_FUEL_KG", {0.51, 0.06}, origin.name, "%05.0f", CMFD_FONT_G)
    total.element_params = {"EICAS_FUEL_KG", brightness, "AMX_FUEL_BINGO_ACTIVE"}
    total.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1},
        {"change_color_when_parameter_equal_to_number", 2, 1, 1, 1, 0},
        {"change_color_when_parameter_equal_to_number", 2, 0, 0, 1, 0}}
    addStrokeLine(nil, 1.45, {-0.91, -0.04}, -90, origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    addStrokeText(nil, "BINGO KG", CMFD_STRINGDEFS_DEF_X05, "LeftCenter", {-0.37, -0.12}, origin.name, nil, nil, CMFD_FONT_W)
    indication.value("EICAS_BINGO_KG", {0.51, -0.12}, origin.name, "%04.0f", CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X05)
    for index, parameter in ipairs({"EICAS_HYD_1_BAR", "EICAS_HYD_2_BAR"}) do
        local horizontal = -0.82 + (index - 1) * 0.22
        addStrokeText(nil, tostring(index), CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {horizontal, -0.10}, origin.name, nil, nil, CMFD_FONT_W)
        addStrokeBox(nil, 0.10, 0.32, "CenterCenter", {horizontal, -0.31}, origin.name, nil, CMFD_MATERIAL_WHITE)
        local gate = addPlaceholder(nil, {horizontal, -0.47}, origin.name)
        gate.element_params = {parameter .. "_VALID"}
        gate.controllers = {{"parameter_compare_with_number", 0, 1}}
        local pressure = addSimpleLine(nil, 0.32, {0, 0}, 0, gate.name, nil, 0.035, CMFD_MATERIAL_CYAN)
        pressure.element_params = {parameter, brightness}
        pressure.controllers = {{"line_object_set_point_using_parameters", 1, 0, 0, 0, 0.32 * GetScale() / 225},
            {"opacity_using_parameter", 1}}
        indication.value(parameter, {horizontal + 0.09, -0.55}, origin.name, "%3.0f", CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X05)
    end
    addStrokeText(nil, "BAR", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.71, -0.63}, origin.name, nil, nil, CMFD_FONT_W)
    addStrokeBox(nil, 0.18, 0.29, "CenterCenter", {0.06, -0.32}, origin.name, nil, CMFD_MATERIAL_WHITE)
    for _, horizontal in ipairs({-0.18, 0.30}) do
        addStrokeBox(nil, 0.20, 0.10, "CenterCenter", {horizontal, -0.49}, origin.name, nil, CMFD_MATERIAL_WHITE)
        addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {horizontal, -0.49}, origin.name, nil, nil, CMFD_FONT_W)
    end
    addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.06, -0.32}, origin.name, nil, nil, CMFD_FONT_W)
    addStrokeText(nil, "OIL PSI", CMFD_STRINGDEFS_DEF_X05, "LeftCenter", {-0.38, -0.61}, origin.name, nil, nil, CMFD_FONT_W)
    indication.value("EICAS_E1_OIL_PRES", {0.51, -0.61}, origin.name, "%3.0f", CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X05)
    return origin
end

function indication.engine_panel(parent)
    indication.gauge("RPM", "EICAS_E1_ROT", {-0.65, 0.94}, parent, 120, "%3.0f", "%")
    indication.gauge("TIT", "EICAS_E1_TEMP", {-0.14, 0.94}, parent, 1200, "%4.0f", "C")
    indication.gauge("F/F", "EICAS_FLOW_KG_MIN", {0.37, 0.94}, parent, 100, "%4.1f", "KG/MIN")
    addStrokeLine(nil, 1.48, {-0.92, 0.69}, -90, parent, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    addStrokeLine(nil, 1.45, {0.61, -0.25}, 0, parent, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    indication.systems(parent, {0, 0.53})
    for index, spec in ipairs({{"NL %", "EICAS_NL"}, {"NH %", "EICAS_NH"}, {"TGT C", "EICAS_TGT"}}) do
        local horizontal = -0.66 + (index - 1) * 0.49
        addStrokeText(nil, spec[1], CMFD_STRINGDEFS_DEF_X05, "LeftCenter", {horizontal - 0.18, -0.22}, parent, nil, nil, CMFD_FONT_W)
        indication.value(spec[2], {horizontal + 0.19, -0.22}, parent, "%3.0f", CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X05)
    end
    indication.alerts(parent, {0.81, 1.08}, 0.35, 22, 0.063)
end

function indication.hsi(parent, position)
    local origin = addPlaceholder("AMX_EFI_HSI", position, parent)
    local valid = addPlaceholder(nil, {0, 0}, origin.name)
    valid.element_params = {"AVIONICS_HDG"}
    valid.controllers = {{"parameter_in_range", 0, -0.05, 360.05}}
    local card = addPlaceholder("AMX_EFI_COMPASS_CARD", {0, 0}, valid.name)
    card.element_params = {"AVIONICS_HDG"}
    card.controllers = {{"rotate_using_parameter", 0, math.rad(1)}}
    local radius = 0.42
    for angle = 0, 350, 10 do
        local radians = math.rad(angle)
        local major = angle % 30 == 0
        addStrokeLine(nil, major and 0.05 or 0.025,
            {radius * math.sin(radians), radius * math.cos(radians)}, -angle, card.name,
            nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
        if major then
            local label = ({[0] = "N", [90] = "E", [180] = "S", [270] = "W"})[angle] or tostring(angle / 10)
            local text = addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X06, "CenterCenter",
                {(radius - 0.09) * math.sin(radians), (radius - 0.09) * math.cos(radians)}, card.name, nil, nil, CMFD_FONT_W)
            text.element_params = {"AVIONICS_HDG", brightness}
            text.controllers = {{"rotate_using_parameter", 0, -math.rad(1)}, {"opacity_using_parameter", 1}}
        end
    end
    addStrokeLine(nil, 0.20, {0, -0.08}, 0, origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    addStrokeLine(nil, 0.18, {-0.09, 0.02}, -90, origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    addStrokeLine(nil, 0.07, {0, radius + 0.01}, 0, origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    local waypoint = addPlaceholder("AMX_EFI_WAYPOINT", {0, 0}, card.name)
    waypoint.element_params = {"CMFD_NAV_FYT_VALID", "CMFD_NAV_FYT_DTK_BRG"}
    waypoint.controllers = {{"parameter_compare_with_number", 0, 1}, {"rotate_using_parameter", 1, -math.rad(1)}}
    addStrokeLine(nil, 0.28, {0, 0.08}, 0, waypoint.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    addStrokeLine(nil, 0.07, {0, 0.36}, 140, waypoint.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    addStrokeLine(nil, 0.07, {0, 0.36}, -140, waypoint.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    local heading = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X07, "CenterCenter", {0, 0.57}, valid.name, nil, {"%03.0f"}, CMFD_FONT_W)
    heading.element_params = {"AVIONICS_HDG", brightness}
    heading.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1}}
    return origin
end

function indication.engine_summary(parent)
    for index, spec in ipairs({{"RPM %", "EICAS_E1_ROT", "%3.0f"}, {"TIT C", "EICAS_E1_TEMP", "%4.0f"},
        {"KG/MIN", "EICAS_FLOW_KG_MIN", "%4.1f"}, {"FUEL KG", "EICAS_FUEL_KG", "%05.0f"}}) do
        local vertical = 0.27 - (index - 1) * 0.18
        addStrokeText(nil, spec[1], CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {-0.43, vertical}, parent, nil, nil, CMFD_FONT_W)
        indication.value(spec[2], {0.43, vertical}, parent, spec[3])
    end
end

return indication