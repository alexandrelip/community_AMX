return function(handle)
    local total = handle("EICAS_FUEL_KG")
    local total_valid = handle("EICAS_FUEL_KG_VALID")
    local selected_bingo = handle("UFCP_FUEL_BINGO")
    local power = handle("ELEC_P1")
    local bingo = handle("EICAS_BINGO_KG")
    local bingo_valid = handle("EICAS_BINGO_KG_VALID")
    local bingo_active = handle("AMX_FUEL_BINGO_ACTIVE")
    local comparison_valid = handle("AMX_FUEL_BINGO_VALID")
    local initial = handle("EICAS_FUEL_INIT")
    local initial_valid = handle("EICAS_FUEL_INIT_VALID")
    local initial_recorded = false

    bingo:set(0)
    bingo_valid:set(0)
    bingo_active:set(0)
    comparison_valid:set(0)
    initial:set(0)
    initial_valid:set(0)

    local function nonnegative(value)
        return type(value) == "number" and value == value and value >= 0 and value < math.huge
    end

    return function()
        local powered = power:get() == 1
        local quantity = total:get()
        local threshold = selected_bingo:get()
        local quantity_ok = total_valid:get() == 1 and nonnegative(quantity)
        local threshold_ok = nonnegative(threshold) and threshold % 1 == 0
        local valid = powered and quantity_ok and threshold_ok
        bingo:set(threshold_ok and threshold or 0)
        bingo_valid:set(powered and threshold_ok and 1 or 0)
        comparison_valid:set(valid and 1 or 0)
        bingo_active:set(valid and quantity <= threshold and 1 or 0)

        if powered and quantity_ok and not initial_recorded then
            initial:set(math.floor(quantity + 0.5))
            initial_valid:set(1)
            initial_recorded = true
        end
    end
end