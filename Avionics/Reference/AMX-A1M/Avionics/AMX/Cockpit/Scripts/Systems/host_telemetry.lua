return function(name)
    assert(type(update) == "function", "Missing donor update: " .. name)
    local original = update
    local tick = get_param_handle("AMX_SUITE_" .. name .. "_TICK")
    local failed = get_param_handle("AMX_SUITE_" .. name .. "_ERROR")
    local reported = false
    local function invoke(callback, phase)
        local ok, message = pcall(callback)
        if not ok then
            failed:set(1)
            if not reported and log and type(log.write) == "function" then
                log.write("AMX_SUITE", log.ERROR, name .. " " .. phase .. ": " .. tostring(message))
                reported = true
            end
            error(message, 0)
        end
    end
    local initialize = post_initialize
    if type(initialize) == "function" then
        function post_initialize()
            failed:set(0)
            invoke(initialize, "post_initialize")
        end
    end
    function update()
        invoke(original, "update")
        tick:set(get_absolute_model_time())
    end
end