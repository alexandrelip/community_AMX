return function(handle)
    local sources = {
        CANOPY_STATUS = {threshold = 0.01},
        AMX_ELEC_GEN_L_AVAILABLE = {active = 0},
        AMX_ELEC_GEN_R_AVAILABLE = {active = 0},
        L_HYD1 = {active = 1},
        L_HYD2 = {active = 1},
        AMX_FUEL_BINGO_ACTIVE = {active = 1, validity = "AMX_FUEL_BINGO_VALID"},
    }
    for name, source in pairs(sources) do
        source.parameter = handle(name)
        source.valid = handle("AMX_ALERT_" .. name .. "_VALID")
        if source.validity then source.available = handle(source.validity) end
    end
    return function(name)
        local source = assert(sources[name], "Unknown Alpha alarm source: " .. tostring(name))
        local value = source.parameter:get()
        local valid = type(value) == "number" and value == value and value >= 0 and value <= 1
            and (source.threshold ~= nil or value == 0 or value == 1)
            and (not source.available or source.available:get() == 1)
        source.valid:set(valid and 1 or 0)
        if not valid then return false end
        if source.threshold then return value > source.threshold end
        return value == source.active
    end
end