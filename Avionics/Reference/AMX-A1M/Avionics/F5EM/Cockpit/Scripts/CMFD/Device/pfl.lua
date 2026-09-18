-- =====================================================================
-- F-5EM Pilot Fault List (PFL) device -- CMFD/Device/pfl.lua
-- =====================================================================
-- Aggregates the active faults the mod can honestly detect and publishes
-- them on the PFL page (CMFD_PFL.lua) via Systems/pfl_check.lua.
--
-- No fabricated codes: only faults the mod already publishes are read
-- (envelope alarms, generator/bus loss, INS align state, BIT overall,
-- BINGO fuel, filtered RWR launch, commanded radar health and AAR interlock).
--
-- CLR softkey (OSS2, top row) acknowledges every currently displayed
-- fault -- they stay hidden until the underlying flag clears and
-- re-triggers (real Elbit MFD behaviour).
-- =====================================================================

local PFL = dofile(LockOn_Options.script_path .. "Systems/pfl_check.lua")

-- Published (consumed by CMFD_PFL.lua indicator)
local PFL_TEXT     = get_param_handle("PFL_TEXT")
local PFL_COUNT    = get_param_handle("PFL_COUNT")
local PFL_HAS_WARN = get_param_handle("PFL_HAS_WARN")

-- Consumed (fault sources -- all already published by other devices)
local OVERG        = get_param_handle("AVIONICS_OVERG")
local STALL        = get_param_handle("AVIONICS_STALL")
local OVERSPEED    = get_param_handle("AVIONICS_OVERSPEED")
local INS_VALID    = get_param_handle("AVIONICS_INS_VALID")
local BIT_OVERALL  = get_param_handle("BIT_OVERALL")           -- 1=GO 2=NOGO
local BINGO_ACT    = get_param_handle("BINGO_ACTIVE")          -- from tactical_overlay
local AAR_SAFE     = get_param_handle("AAR_WEAPONS_SAFE")      -- 1 during AAR contact
local RWR_EFFECTIVE_SIGNAL = get_param_handle("RWR_EFFECTIVE_SIGNAL")
local RDR_POWER    = get_param_handle("RDR_POWER")
local RDR_OPR      = get_param_handle("RDR_OPR")
local RDR_ACTIVE   = get_param_handle("RDR_ACTIVE")

-- Initial safe state (indicator can read from t=0 without stale values).
PFL_TEXT:set("")
PFL_COUNT:set(0)
PFL_HAS_WARN:set(0)

-- Ack bitmask: pilot pressed CLR -> stash the current active mask so
-- displayed faults hide until their flag clears and re-fires. Same-value
-- edges (fault still on) stay ack'd. A fresh trigger (0 -> 1) re-shows.
local ack_mask = 0
local prev_active_mask = 0
local rdr_inactive_since = nil

local function radar_failed()
    local onground = true
    if type(get_avionics_onground) == "function" then
        local ok, value = pcall(get_avionics_onground)
        if ok then onground = value == true or (tonumber(value) or 0) > 0.5 end
    end
    local expected = not onground and RDR_POWER:get() > 0.5 and RDR_OPR:get() > 0.5
    if not expected or RDR_ACTIVE:get() > 0.5 then
        rdr_inactive_since = nil
        return false
    end

    local now = type(get_absolute_model_time) == "function"
        and (tonumber(get_absolute_model_time()) or 0) or 0
    if rdr_inactive_since == nil or now < rdr_inactive_since then
        rdr_inactive_since = now
        return false
    end
    return (now - rdr_inactive_since) >= 1.0
end

local function update_pfl()
    local elec_ok = get_elec_essential_dc_bus_ok()

    local r = PFL.evaluate({
        elec_bus_ok = elec_ok,
        overg       = OVERG:get() > 0.5,
        stall       = STALL:get() > 0.5,
        overspeed   = OVERSPEED:get() > 0.5,
        launch      = RWR_EFFECTIVE_SIGNAL:get() >= 3,
        gen_fail    = elec_ok and (not get_elec_generator_on()),
        bingo       = BINGO_ACT:get() > 0.5,
        ins_invalid = INS_VALID:get() < 0.5,
        bit_nogo    = BIT_OVERALL:get() > 1.5,             -- 2 = NO-GO
        rdr_fail    = radar_failed(),
        aar_unsafe  = AAR_SAFE:get() > 0.5,                -- during AAR contact -> weapons are inhibited
        ack_mask    = ack_mask,
    })

    -- Clear ack bits for faults that dropped (allow re-trigger to show again).
    if r.active_mask ~= prev_active_mask then
        local cleared = 0
        for i = 1, #PFL.CODES do
            local pos = 2 ^ (i - 1)
            local now_on  = math.floor(r.active_mask / pos) % 2 >= 1
            local prev_on = math.floor(prev_active_mask / pos) % 2 >= 1
            if prev_on and not now_on then
                -- Fault cleared: also clear its ack bit so the next re-trigger shows.
                if math.floor(ack_mask / pos) % 2 >= 1 then
                    ack_mask = ack_mask - pos
                end
            end
            _ = cleared
        end
        prev_active_mask = r.active_mask
    end

    PFL_TEXT:set(r.text)
    PFL_COUNT:set(r.count)
    PFL_HAS_WARN:set(r.has_warn)
end

function SetCommandPfl(command, value, CMFD)
    if value == 1 then
        -- OSS2 = CLR (see CMFD_PFL.lua osb_txt[2]).
        if command == device_commands.CMFD1OSS2 or command == device_commands.CMFD2OSS2 then
            ack_mask = prev_active_mask   -- acknowledge everything currently active
        end
    end
end

register_as_cmfd_item(SUB_PAGE_ID.PFL, nil, update_pfl, SetCommandPfl)
