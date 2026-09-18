local groups = dofile(LockOn_Options.script_path .. "Host/eicas_groups.lua").groups
local brightness = type(default_element_params) == "table" and default_element_params[1] or default_element_params
return function(indication)
    local layout = {}
    local function font_size(height) return {height * GetScale(), height * GetScale(), 0, 0} end
    local function label(name, value, position, parent, height, alignment, font)
        return addStrokeText(name, value, font_size(height), alignment or "LeftCenter", position,
            parent, nil, nil, font or CMFD_FONT_W)
    end
    local function rule(parent, horizontal, vertical, length, rotation)
        return addStrokeLine(nil, length, {horizontal, vertical}, rotation, parent,
            nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    end
    local function value(parameter, position, parent, height, format)
        return indication.value(parameter, position, parent, format or "%3.0f", CMFD_FONT_W, font_size(height))
    end
    local function string_value(name, parameter, position, parent, height, alignment)
        local output = addStrokeText(name, "", font_size(height), alignment or "LeftCenter",
            position, parent, nil, {"%s"}, CMFD_FONT_W)
        output.element_params = {parameter, brightness, "AMXDENIS_EICAS_GROUPS_READY"}
        output.controllers = {{"text_using_parameter", 0}, {"opacity_using_parameter", 1},
            {"parameter_compare_with_number", 2, 1}}
        return output
    end
    local function draw_groups(parent, identifier, left, top, width, height)
        local row_height = height / #groups
        local text_height = math.min(row_height * 0.52, width / 11)
        for index, group in ipairs(groups) do
            local vertical = top - (index - 0.5) * row_height
            local prefix = "AMXDENIS_EICAS_" .. group.key
            local title = label(identifier .. "_GROUP_" .. group.key .. "_LABEL", group.label,
                {left + width * 0.04, vertical + row_height * 0.20}, parent, text_height)
            title.element_params = {prefix .. "_SEVERITY", prefix .. "_VALID", brightness}
            title.controllers = {{"opacity_using_parameter", 2},
                {"change_color_when_parameter_equal_to_number", 0, 0, 0.55, 0.62, 0.6},
                {"change_color_when_parameter_equal_to_number", 0, 1, 0, 1, 1},
                {"change_color_when_parameter_equal_to_number", 0, 2, 1, 0.8, 0},
                {"change_color_when_parameter_equal_to_number", 0, 3, 1, 0.12, 0.12}}
            string_value(identifier .. "_GROUP_" .. group.key .. "_STATUS", prefix .. "_STATUS",
                {left + width * 0.96, vertical + row_height * 0.20}, parent, text_height * 0.65, "RightCenter")
            string_value(identifier .. "_GROUP_" .. group.key .. "_ORIGINS", prefix .. "_ORIGINS",
                {left + width * 0.04, vertical - row_height * 0.25}, parent, math.min(text_height * 0.58, width / 20))
        end
    end
    function layout.draw(parent, left, top, width, height, central)
        local identifier = "AMXDENIS_EICAS_" .. create_guid_string()
        local root = addPlaceholder(identifier, {left, top}, parent)
        local border = addStrokeBox(identifier .. "_BOUNDS", width, height, "CenterTop",
            {width / 2, 0}, root.name, nil, CMFD_MATERIAL_CYAN)
        local header = math.min(width * 0.31, height * 0.26)
        local content_width = width * 0.65
        local engine_height = central and height * 0.58 or height * 0.62
        local metrics_height = math.min(height * 0.10, width * 0.12)
        local system_top = -header
        local system_bottom = -engine_height + metrics_height
        local system_height = -system_bottom - header
        local font = width * 0.037
        for index, spec in ipairs({{"NL", "EICAS_NL", "%"}, {"NH", "EICAS_NH", "%"}, {"TGT", "EICAS_TGT", "C"}}) do
            local horizontal = width * (index - 0.5) / 3
            local radius = math.min(width * 0.105, header * 0.33)
            local center = -header * 0.54
            addStrokeCircle(identifier .. "_CIRCLE_" .. spec[1], radius, {horizontal, center}, root.name,
                nil, {math.rad(-60), math.rad(240)}, nil, nil, nil, CMFD_MATERIAL_WHITE)
            label(identifier .. "_TITLE_" .. spec[1], spec[1], {horizontal, center + radius + font}, root.name,
                font, "CenterCenter")
            value(spec[2], {horizontal + radius * 0.45, center}, root.name, font * 1.3)
            label(nil, spec[3], {horizontal, center - radius * 0.58}, root.name, font * 0.8, "CenterCenter")
        end
        rule(root.name, 0, -header, width, -90)
        rule(root.name, content_width, -height, height - header, 0)
        local bars_width = content_width * 0.25
        rule(root.name, bars_width, system_bottom, system_height, 0)
        label(identifier .. "_HYD_TITLE", "HYD", {bars_width * 0.5, system_top - system_height * 0.07},
            root.name, font * 0.7, "CenterCenter")
        local bar_height = system_height * 0.50
        local bar_width = bars_width * 0.17
        local bar_center = system_top - system_height * 0.49
        local bar_bottom = bar_center - bar_height * 0.5
        for index = 1, 2 do
            local horizontal = bars_width * (index == 1 and 0.29 or 0.71)
            local parameter = "EICAS_HYD_" .. index .. "_BAR"
            label(nil, tostring(index), {horizontal, system_top - system_height * 0.15}, root.name,
                font * 0.65, "CenterCenter")
            addStrokeBox(identifier .. "_HYD_SCALE_" .. index, bar_width, bar_height,
                "CenterCenter", {horizontal, bar_center}, root.name, nil, CMFD_MATERIAL_WHITE)
            addStrokeLine(identifier .. "_HYD_LOW_93_" .. index, bar_width * 0.55,
                {horizontal - bar_width * 0.78, bar_bottom + bar_height * 93 / 300}, -90,
                root.name, nil, nil, nil, nil, CMFD_MATERIAL_YELLOW)
            local available = addPlaceholder(nil, {0, 0}, root.name)
            available.element_params = {parameter .. "_VALID"}
            available.controllers = {{"parameter_compare_with_number", 0, 1}}
            local pressure = addSimpleLine(identifier .. "_HYD_BAR_" .. index, bar_height,
                {horizontal, bar_bottom}, 0, available.name, nil, bar_width * 0.65, CMFD_MATERIAL_CYAN)
            pressure.element_params = {parameter, brightness}
            pressure.controllers = {{"line_object_set_point_using_parameters", 1, 0, 0, 0,
                bar_height * GetScale() / 300}, {"opacity_using_parameter", 1}}
            value(parameter, {horizontal + bar_width * 0.65, system_top - system_height * 0.84},
                root.name, font * 0.62)
        end
        label(identifier .. "_HYD_SCALE_LABEL", "0-300 BAR",
            {bars_width * 0.5, system_top - system_height * 0.94}, root.name, font * 0.48, "CenterCenter")
        local shape = addPlaceholder(identifier .. "_UNIDENTIFIED_SYNOPTIC", {0, 0}, root.name)
        local center_x = bars_width + (content_width - bars_width) * 0.54
        local center_y = system_top - system_height * 0.56
        rule(shape.name, bars_width + width * 0.03, system_top - system_height * 0.14,
            content_width - bars_width - width * 0.06, -90)
        addStrokeBox(nil, width * 0.09, system_height * 0.47, "CenterCenter", {center_x, center_y},
            shape.name, nil, CMFD_MATERIAL_WHITE)
        addStrokeBox(nil, width * 0.27, system_height * 0.11, "CenterCenter",
            {center_x, center_y - system_height * 0.18}, shape.name, nil, CMFD_MATERIAL_WHITE)
        label(nil, "?", {center_x - width * 0.12, center_y + system_height * 0.12}, shape.name,
            font, "CenterCenter")
        rule(root.name, 0, system_bottom, content_width, -90)
        rule(root.name, 0, -engine_height, content_width, -90)
        for index, spec in ipairs({{"TOTAL kg", "EICAS_FUEL_KG", "%05.0f"}, {"FLOW kg/min", "EICAS_FLOW_KG_MIN", "%4.1f"}}) do
            local horizontal = (index - 1) * content_width / 2
            label(nil, spec[1], {horizontal + width * 0.02, system_bottom - metrics_height * 0.28}, root.name, font * 0.8)
            value(spec[2], {horizontal + content_width / 2 - width * 0.02, system_bottom - metrics_height * 0.72},
                root.name, font, spec[3])
        end
        draw_groups(root.name, identifier, content_width, -header - font * 0.1,
            width - content_width, height - header - font * 0.2)
        local bingo_vertical = -engine_height - (central and font * 0.75 or (height - engine_height) * 0.15 + font * 1.5)
        local bingo = label(identifier .. "_BINGO", "BINGO", {content_width / 2, bingo_vertical},
            root.name, font, "CenterCenter", CMFD_FONT_Y)
        bingo.element_params = {"AMX_FUEL_BINGO_ACTIVE", "AMX_FUEL_BINGO_VALID", brightness}
        bingo.controllers = {{"parameter_compare_with_number", 0, 1}, {"parameter_compare_with_number", 1, 1},
            {"opacity_using_parameter", 2}}
        if not central then
            local baseline = -engine_height - (height - engine_height) * 0.15
            label(nil, "BINGO kg", {width * 0.02, baseline}, root.name, font * 0.85)
            value("EICAS_BINGO_KG", {content_width - width * 0.02, baseline}, root.name, font, "%04.0f")
            label(nil, "DVR ---  TEST ---", {width * 0.02, -height + font}, root.name, font * 0.7)
        end
        return root, border, {content_width = content_width, engine_height = engine_height, font = font}
    end
    function layout.central(parent)
        local width, height = 1.82, 2.35
        local left, top = -width / 2, 1.10
        local root, _, geometry = layout.draw(parent, left, top, width, height, true)
        local available_height = height - geometry.engine_height
        local center_x = geometry.content_width / 2
        local center_y = -geometry.engine_height - available_height * 0.52
        local flight = addPlaceholder(nil, {0, 0}, root.name)
        flight.element_params = {"AMXDENIS_FLIGHT_VALID"}
        flight.controllers = {{"parameter_compare_with_number", 0, 1}}
        local radius = math.min(geometry.content_width * 0.23, available_height * 0.24)
        addStrokeCircle(nil, radius, {center_x, center_y}, flight.name, nil, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
        local compass = addPlaceholder(nil, {center_x, center_y}, flight.name)
        compass.element_params = {"AVIONICS_HDG"}
        compass.controllers = {{"rotate_using_parameter", 0, math.rad(1)}}
        rule(compass.name, 0, 0, radius * 0.8, 0)
        local heading_label = label(nil, "HDG", {center_x, center_y + radius + geometry.font}, root.name,
            geometry.font * 0.75, "CenterCenter")
        value("AVIONICS_HDG", {center_x + radius * 0.5, center_y}, root.name, geometry.font, "%03.0f")
        for index, spec in ipairs({{"IAS kt", "AVIONICS_IAS", "%03.0f"}, {"ALT ft", "AVIONICS_ALT", "%05.0f"}}) do
            local horizontal = (index - 1) * geometry.content_width / 2
            label(nil, spec[1], {horizontal + width * 0.02, -height + geometry.font * 3.1}, root.name, geometry.font * 0.75)
            value(spec[2], {horizontal + geometry.content_width / 2 - width * 0.02, -height + geometry.font * 1.35},
                root.name, geometry.font * 0.85, spec[3])
        end
        return root, heading_label
    end
    return layout
end