return function(controls)
    local original = SetCommand
    for _, control in pairs(controls) do
        control.handle = get_param_handle(control.name)
    end
    function SetCommand(command, value)
        local control = controls[command]
        if control then
            if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
            value = math.max(control.minimum, math.min(control.maximum, value))
            control.handle:set(value)
        end
        if original then return original(command, value) end
    end
end