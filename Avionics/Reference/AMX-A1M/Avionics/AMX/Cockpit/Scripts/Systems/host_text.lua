return function(definitions, formatter, handle, clock)
    local fields = {}
    for name, identifier in pairs(definitions) do
        fields[#fields + 1] = {name = name, identifier = identifier,
            value = handle("AMX_CMFD_TEXT_" .. identifier)}
    end
    local flir_tick = handle("AMX_SUITE_FLIR_TICK")
    local flir_error = handle("AMX_SUITE_FLIR_ERROR")
    local mission_clock = handle("AMX_CMFD_MISSION_TIME")
    local previous = -math.huge
    return function()
        local now = clock()
        if type(now) ~= "number" or now ~= now or math.abs(now) == math.huge then return end
        if now >= previous and now - previous < 0.5 then return end
        previous = now
        local tick = flir_tick:get()
        local available = type(tick) == "number" and tick > 0 and tick <= now
            and now - tick < 1 and flir_error:get() == 0
        for _, field in ipairs(fields) do
            local text = ""
            if available then
                local ok, value = pcall(formatter, field.identifier)
                if ok and type(value) == "string" then text = value end
            elseif field.name == "FLIR_STATUS" then
                text = "UNAVAILABLE"
            end
            field.value:set(text)
        end
        local seconds = math.floor(now) % 86400
        mission_clock:set(string.format("%02d:%02d:%02dL", math.floor(seconds / 3600),
            math.floor(seconds / 60) % 60, seconds % 60))
    end
end