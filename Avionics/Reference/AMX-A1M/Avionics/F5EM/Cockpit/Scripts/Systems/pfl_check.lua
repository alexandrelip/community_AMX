-- =====================================================================
-- F-5EM Pilot Fault List (PFL) evaluator -- PURE module (no DCS deps).
-- =====================================================================
-- Aggregates the ACTIVE faults the mod can honestly detect (no invented
-- HYD/FIRE codes -- the DCS engine doesn't publish those for the F-5E
-- base). Builds a display text (top-priority first), a count, a "has
-- warn" flag for red vs amber coloring and an active bitmask so the CMFD
-- device can honour the CLR softkey (acknowledge = hide until the fault
-- clears and re-triggers). Pure: desk-checkable, no DCS API.
-- =====================================================================

local M = {}

-- Priority-ordered code table. Same order used for the bitmask -- adding
-- a code appends a bit; do NOT reorder existing entries (would flip ack).
M.CODES = {
    { key = "OVER_G",     label = "OVER G",    warn = true  },
    { key = "STALL",      label = "STALL",     warn = true  },
    { key = "OVERSPEED",  label = "OVERSPEED", warn = true  },
    { key = "LAUNCH",     label = "MSL LAUNCH",warn = true  },
    { key = "GEN_FAIL",   label = "GEN FAIL",  warn = true  },
    { key = "BINGO",      label = "BINGO FUEL",warn = false },
    { key = "INS_ALIGN",  label = "INS ALIGN", warn = false },
    { key = "BIT_FAIL",   label = "BIT NO-GO", warn = false },
    { key = "RDR_FAIL",   label = "RDR FAIL",  warn = false },
    { key = "AAR_UNSAFE", label = "AAR SAFE",  warn = false },
}

-- Bit position (0-based) for a code key. Used by the CLR softkey mask.
function M.bit_for(key)
    for i, e in ipairs(M.CODES) do
        if e.key == key then return i - 1 end
    end
    return -1
end

-- Non-destructive bit check on a 32-bit mask, Lua 5.1/5.3 safe.
local function bit_is_set(mask, pos)
    mask = mask or 0
    if pos < 0 or pos > 31 then return false end
    return math.floor(mask / (2 ^ pos)) % 2 >= 1
end

-- inp = {
--   elec_bus_ok   -- essential DC bus healthy (no bus -> everything cleared, PFL blank)
--   overg, stall, overspeed, launch, bingo,
--   ins_invalid, gen_fail, bit_nogo, rdr_fail, aar_unsafe,
--   ack_mask      -- bitmask of codes the pilot has acknowledged (CLR)
-- }
-- Returns { text, count, has_warn, active_mask }.
--   text:        multi-line "PFL\n\n<code1>\n<code2>..." for text_using_parameter
--                (empty string when no faults display -- matches real Elbit MFD)
--   count:       number of DISPLAYED faults after ack filtering
--   has_warn:    1 if any displayed fault is warn-level (red), else 0
--   active_mask: bitmask of ALL currently active faults (before ack filter);
--                use for the CLR softkey (ack_mask := active_mask)
function M.evaluate(inp)
    inp = inp or {}
    if not inp.elec_bus_ok then
        return { text = "", count = 0, has_warn = 0, active_mask = 0 }
    end

    local active = {
        OVER_G     = inp.overg       and true or false,
        STALL      = inp.stall       and true or false,
        OVERSPEED  = inp.overspeed   and true or false,
        LAUNCH     = inp.launch      and true or false,
        GEN_FAIL   = inp.gen_fail    and true or false,
        BINGO      = inp.bingo       and true or false,
        INS_ALIGN  = inp.ins_invalid and true or false,
        BIT_FAIL   = inp.bit_nogo    and true or false,
        RDR_FAIL   = inp.rdr_fail    and true or false,
        AAR_UNSAFE = inp.aar_unsafe  and true or false,
    }

    local mask = 0
    for i, e in ipairs(M.CODES) do
        if active[e.key] then mask = mask + (2 ^ (i - 1)) end
    end

    local ack = inp.ack_mask or 0
    local lines = {}
    local has_warn = 0
    for i, e in ipairs(M.CODES) do
        if active[e.key] and not bit_is_set(ack, i - 1) then
            table.insert(lines, e.label)
            if e.warn then has_warn = 1 end
        end
    end
    local count = #lines

    local text
    if count == 0 then
        text = ""
    else
        text = " PFL\n\n" .. table.concat(lines, "\n")
    end

    return { text = text, count = count, has_warn = has_warn, active_mask = mask }
end

return M
