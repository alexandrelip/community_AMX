return function(sensors, handle)
    local fields = {
        E1_ROT = {method = "getEngineLeftRPM"},
        E2_ROT = {},
        E1_TEMP = {method = "getEngineLeftTemperatureBeforeTurbine"},
        E2_TEMP = {},
        E1_FF = {method = "getEngineLeftFuelConsumption", factor = 3600 * 2.20462},
        E2_FF = {},
        FLOW_KG_MIN = {method = "getEngineLeftFuelConsumption", factor = 60},
        FUEL_KG = {method = "getTotalFuelWeight"},
        HYD_1_BAR = {source = "P_HYD1", factor = 10},
        HYD_2_BAR = {source = "P_HYD2", factor = 10},
        NL = {}, NH = {}, TGT = {},
        HYD_UTIL = {source = "P_HYD1", factor = 145.03773773022},
        HYD_FLT = {source = "P_HYD2", factor = 145.03773773022},
        FUEL_INTR = {}, FUEL_CNTR = {}, FUEL_INBD = {},
        E1_OIL_PRES = {}, E2_OIL_PRES = {}, E1_NOZZLE = {}, E2_NOZZLE = {},
    }
    for name, field in pairs(fields) do
        field.valid = handle("EICAS_" .. name .. "_VALID")
        field.text = handle("EICAS_" .. name .. "_TEXT")
        field.valid:set(0)
        field.text:set("---")
        if field.source then field.parameter = handle(field.source) end
    end
    return function(name)
        local field = assert(fields[name], "Unknown AMX EICAS field: " .. tostring(name))
        local ok, value = false, nil
        if field.parameter then
            ok, value = pcall(field.parameter.get, field.parameter)
        elseif field.method and sensors and type(sensors[field.method]) == "function" then
            ok, value = pcall(sensors[field.method])
        end
        local valid = ok and type(value) == "number" and value == value and math.abs(value) < math.huge
        field.valid:set(valid and 1 or 0)
        value = valid and value * (field.factor or 1) or 0
        field.text:set(valid and string.format("%.0f", value) or "---")
        return value
    end
end