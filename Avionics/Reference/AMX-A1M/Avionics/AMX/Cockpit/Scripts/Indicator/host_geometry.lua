local geometry = {}

function geometry.line(name, parameter, length, parent, material)
    local line = addSimpleLine(name, length, {0, 0}, 0, parent, nil, 0.002, material)
    line.element_params = {parameter}
    line.controllers = {
        {"parameter_in_range", 0, 0.000001, 1000},
        {"line_object_set_point_using_parameters", 1, 0, 0, 0, length * GetScale()},
    }
    return line
end

function geometry.circle(parameter, radius, parent, material)
    local origin = addPlaceholder(nil, {0, 0}, parent)
    for arc_start = 0, 6 do
        local arc_end = math.min(arc_start + 0.5, 2 * math.pi)
        local line = addSimpleLine(nil, radius, {0, 0}, 0, origin.name, nil, 0.002, material)
        local vertices, controllers = {}, {{"parameter_in_range", 0, 0.000001, 1000}}
        for point = 0, 8 do
            local angle = arc_start + (arc_end - arc_start) * point / 8
            local horizontal, vertical = radius * math.cos(angle), radius * math.sin(angle)
            vertices[#vertices + 1] = {horizontal, vertical}
            controllers[#controllers + 1] = {"line_object_set_point_using_parameters", point,
                0, 0, horizontal * GetScale(), vertical * GetScale()}
        end
        line.vertices = vertices
        line.element_params = {parameter}
        line.controllers = controllers
    end
    return origin
end

return geometry