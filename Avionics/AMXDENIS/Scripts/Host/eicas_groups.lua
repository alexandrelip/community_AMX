local model = {schema = "AMXDENIS_EICAS_GROUPS_1"}
model.groups = {
    {key = "ENG", label = "ENG"},
    {key = "OIL", label = "OIL"},
    {key = "CANOPY", label = "CANOPY", sources = {
        {name = "POSITION", state = "EICAS_ERROR_CANOPY", valid = "AMX_ALERT_CANOPY_STATUS_VALID", severity = 3},
    }},
    {key = "ELEC", label = "ELEC", sources = {
        {name = "GEN 1", state = "EICAS_ERROR_LEFT_GEN", valid = "AMX_ALERT_AMX_ELEC_GEN_L_AVAILABLE_VALID", severity = 2},
        {name = "GEN 2", state = "EICAS_ERROR_RIGHT_GEN", valid = "AMX_ALERT_AMX_ELEC_GEN_R_AVAILABLE_VALID", severity = 2},
    }},
    {key = "HYD", label = "HYD", sources = {
        {name = "HYD 1", state = "EICAS_ERROR_UTIL_HYD", valid = "AMX_ALERT_L_HYD1_VALID", severity = 2},
        {name = "HYD 2", state = "EICAS_ERROR_FLT_HYD", valid = "AMX_ALERT_L_HYD2_VALID", severity = 2},
    }},
    {key = "AVIONICS", label = "AVIONICS"},
    {key = "FUEL_BAL", label = "FUEL BAL"},
    {key = "FUEL_XFER", label = "FUEL XFER"},
    {key = "FUEL_LO", label = "FUEL LO"},
    {key = "FUEL_PRESS", label = "FUEL PRESS"},
    {key = "EXT_TANKS", label = "EXT TANKS"},
    {key = "OXYGEN", label = "OXYGEN"},
    {key = "TO_CONFIG", label = "T/O CONFIG"},
    {key = "SEAT_PIN", label = "SEAT PIN"},
    {key = "ANTI_ICE", label = "ANTI-ICE"},
}

function model.new(handle, definitions)
    local groups = definitions or model.groups
    local remembered = {}
    local function publish(prefix, name, value) handle(prefix .. "_" .. name):set(value) end
    return function()
        local powered = handle("ELEC_P1"):get() == 1 and handle("AMX_AVIONICS_MASTER"):get() == 1
        local details = {}
        for index, group in ipairs(groups) do
            local prefix = "AMXDENIS_EICAS_" .. group.key
            local states = remembered[index] or {}
            remembered[index] = states
            local origins, severity, acknowledged = {}, 0, true
            local sources = group.sources or {}
            local valid = powered and #sources > 0
            for source_index, source in ipairs(sources) do
                local state = handle(source.state):get()
                local available = powered and handle(source.valid):get() == 1 and
                    (state == 0 or state == 1 or state == 2)
                if available then states[source_index] = state else valid = false end
                local retained = states[source_index] or 0
                if retained > 0 then
                    origins[#origins + 1] = source.name .. (available and "" or "?")
                    severity = math.max(severity, source.severity)
                    acknowledged = acknowledged and retained == 2
                end
            end
            local active = #origins > 0
            local text = table.concat(origins, " / ")
            publish(prefix, "ACTIVE", active and 1 or 0)
            publish(prefix, "SEVERITY", severity)
            publish(prefix, "ACK", active and acknowledged and 1 or 0)
            publish(prefix, "VALID", valid and 1 or 0)
            publish(prefix, "COMPLETE", 0)
            publish(prefix, "ORIGINS", text)
            publish(prefix, "STATUS", active and (not valid and "?" or (acknowledged and "ACK" or "!")) or "---")
            if active then details[#details + 1] = group.label .. ": " .. text end
        end
        handle("AMXDENIS_EICAS_DETAILS"):set(table.concat(details, "\n"))
        handle("AMXDENIS_EICAS_GROUPS_READY"):set(1)
    end
end

return model