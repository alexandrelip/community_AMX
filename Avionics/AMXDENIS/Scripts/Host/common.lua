local M = {}
function M.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function M.read(sensors, method, minimum, maximum)
    if type(sensors) ~= "table" or type(sensors[method]) ~= "function" then return nil end
    local ok, value = pcall(sensors[method])
    if ok and M.finite(value) and (minimum == nil or value >= minimum) and (maximum == nil or value <= maximum) then
        return value
    end
end
function M.publish(name, value)
    local valid = M.finite(value)
    get_param_handle(name):set(valid and value or 0)
    get_param_handle(name .. "_VALID"):set(valid and 1 or 0)
    return valid
end
function M.hot()
    local birth = LockOn_Options.init_conditions.birth_place
    return birth == "GROUND_HOT" or birth == "AIR_HOT"
end
function M.send(command, value)
    if type(dispatch_action) ~= "function" then return false end
    local ok, result = pcall(dispatch_action, nil, command, value)
    return ok and result ~= false
end
return M