-- =====================================================================
-- F-5EM Emergency / Normal checklist text -- PURE module (no DCS deps).
-- =====================================================================
-- Static text tables for the CMFD EMER page. Each entry is indexed by the
-- submenu id defined in CMFD/Device/emer.lua (CMFD_CHECKLIST_SUBMENU_IDS).
-- Content is deliberately terse (line-based, no prose) to fit the CMFD
-- 8x8-ish font at CMFD_STRINGDEFS_DEF_X08. Sources: F-5EM Manual do Piloto
-- PT-BR (Doc/) + generic F-5 T.O. emergency procedures. Warnings are
-- rendered by the indicator with the caller's color (R/Y/W bezel).
-- =====================================================================

local M = {}

-- Titles used on top of each checklist page (matches OSB label).
M.TITLES = {
    [1]  = "NORM PROC",
    [2]  = "GND WARN",
    [3]  = "GND CAUT",
    [4]  = "GND GNRL",
    [5]  = "TKOFF WARN",
    [6]  = "TKOFF CAUT",
    [7]  = "TKOFF GNRL",
    [8]  = "FLT WARN",
    [9]  = "FLT CAUT",
    [10] = "FLT GNRL",
    [11] = "LAND WARN",
    [12] = "LAND CAUT",
    [13] = "LAND GNRL",
}

-- Full checklist text per submenu. LEVEL 1 = fixed-length body (16 rows
-- max; anything longer would clip the CMFD viewport at font X08).
M.PAGE1 = {
    -- 1: NORMAL PROCEDURES
    [1] = ""
        .. "1 STARTUP / TAXI\n"
        .. "2 BEFORE TAKEOFF\n"
        .. "3 TAKEOFF\n"
        .. "4 CLIMB / CRUISE\n"
        .. "5 APPROACH\n"
        .. "6 LANDING\n"
        .. "7 AFTER LANDING\n"
        .. "8 SHUTDOWN\n"
        .. "\n"
        .. "SEE MORE -> LEVEL 2",

    -- 2: GROUND WARNINGS (RED)
    [2] = ""
        .. "FIRE ON GROUND\n"
        .. " THROTTLE  -- OFF\n"
        .. " FUEL SHUT -- CLOSED\n"
        .. " BATTERY   -- OFF\n"
        .. " EGRESS    -- IMMEDIATE\n"
        .. "\n"
        .. "HOT BRAKES\n"
        .. " STOP\n"
        .. " CANOPY OPEN\n"
        .. " DO NOT SET PARKING BRK\n"
        .. " ALLOW COOLING > 30 MIN\n",

    -- 3: GROUND CAUTIONS (AMBER)
    [3] = ""
        .. "LOW OIL PRESS\n"
        .. " ABORT START\n"
        .. " THROTTLE -- OFF\n"
        .. "\n"
        .. "HIGH EGT ON START\n"
        .. " ABORT / MOTOR ENG\n"
        .. "\n"
        .. "STUCK IGNITION\n"
        .. " BATTERY -- OFF\n",

    -- 4: GROUND GENERAL (WHITE)
    [4] = ""
        .. "BATTERY START\n"
        .. " BATT   -- ON\n"
        .. " EGT    -- MONITOR\n"
        .. " IGN    -- ENGAGE\n"
        .. " THR    -- IDLE @ 12%\n"
        .. "\n"
        .. "EXT PWR START\n"
        .. " GEN CHK -- BOTH ON\n"
        .. " EXT PWR -- REMOVE\n",

    -- 5: TAKEOFF WARNINGS (RED)
    [5] = ""
        .. "ENG FAIL PRE-ROTATION\n"
        .. " THROTTLE  -- OFF\n"
        .. " ABORT / MAX BRK\n"
        .. " DRAG CHUTE -- DEPLOY\n"
        .. "\n"
        .. "ENG FAIL POST-ROTATION\n"
        .. " GEAR UP / MAINTAIN 190\n"
        .. " CLIMB IF ABLE\n"
        .. " EJECT IF SINK RATE\n",

    -- 6: TAKEOFF CAUTIONS (AMBER)
    [6] = ""
        .. "HYD PRESS LOSS\n"
        .. " ABORT IF < REFUSAL\n"
        .. " EMER GEAR EXT\n"
        .. "\n"
        .. "OVERBOOST\n"
        .. " REDUCE POWER\n",

    -- 7: TAKEOFF GENERAL (WHITE)
    [7] = ""
        .. "ABORT PROCEDURE\n"
        .. " THROTTLE  -- IDLE\n"
        .. " WHEEL BRK -- MAX\n"
        .. " DRAG CHUTE -- DEPLOY\n"
        .. " NOSE WHL STEERING\n"
        .. "\n"
        .. "GO/NO-GO SPEED\n"
        .. " REFUSAL @ 120 KT\n",

    -- 8: FLIGHT WARNINGS (RED)
    [8] = ""
        .. "FLAMEOUT\n"
        .. " ZOOM 200 KT\n"
        .. " AIR START -- ATTEMPT\n"
        .. " GLIDE 220 KT / 2NM per 1000 FT\n"
        .. "\n"
        .. "ENGINE FIRE\n"
        .. " THROTTLE -- OFF\n"
        .. " FUEL SHUT -- CLOSED\n"
        .. "\n"
        .. "SEE MORE -> LEVEL 2",

    -- 9: FLIGHT CAUTIONS (AMBER)
    [9] = ""
        .. "SINGLE GEN FAIL\n"
        .. " LOAD SHED\n"
        .. " LAND ASAP\n"
        .. "\n"
        .. "FUEL IMBALANCE\n"
        .. " XFEED -- OPEN\n"
        .. " MONITOR\n"
        .. "\n"
        .. "OVER-G RECOVERY\n"
        .. " EASE OFF STICK\n"
        .. " LAND / INSPECT\n",

    -- 10: FLIGHT GENERAL (WHITE)
    [10] = ""
        .. "COMM LOST\n"
        .. " SQUAWK 7600\n"
        .. " PROCEED PER FILED\n"
        .. "\n"
        .. "IFR PROCEDURES\n"
        .. " STBY INSTRUMENTS\n"
        .. " REPORT POSITION\n"
        .. "\n"
        .. "DIVERT\n"
        .. " DTU RECALL NEAREST\n",

    -- 11: LANDING WARNINGS (RED)
    [11] = ""
        .. "GEAR UP LANDING\n"
        .. " HOOK IF AVAIL\n"
        .. " MIN FUEL\n"
        .. " FOAM RUNWAY\n"
        .. "\n"
        .. "BLOWN TIRE\n"
        .. " OPPOSITE RUDDER\n"
        .. " AERO BRK ONLY\n"
        .. " DRAG CHUTE -- DEPLOY\n",

    -- 12: LANDING CAUTIONS (AMBER)
    [12] = ""
        .. "NO FLAPS LANDING\n"
        .. " ADD 20 KT TO REF\n"
        .. " LONG FIELD ONLY\n"
        .. "\n"
        .. "CROSSWIND > 25 KT\n"
        .. " CRAB TO FLARE\n"
        .. " UPWIND WING LOW\n"
        .. "\n"
        .. "SHORT FIELD\n"
        .. " FULL FLAPS\n"
        .. " REF -5 KT / IMMEDIATE CHUTE\n",

    -- 13: LANDING GENERAL (WHITE)
    [13] = ""
        .. "NORMAL PATTERN\n"
        .. " OVERHEAD 300 KT\n"
        .. " BREAK / GEAR / FLAPS\n"
        .. " BASE 155 KT\n"
        .. " FINAL 145 KT\n"
        .. " REF 135 KT\n"
        .. "\n"
        .. "GO AROUND\n"
        .. " MAX POWER\n"
        .. " GEAR UP AFTER +VS\n"
        .. " FLAPS UP AT 200 KT\n",
}

-- LEVEL 2 (MORE) content -- expanded / secondary procedures.
M.PAGE2 = {
    -- 1: NORM PROC page 2
    [1] = ""
        .. "9  IN-FLIGHT REFUEL\n"
        .. "10 AIR TO AIR SETUP\n"
        .. "11 AIR TO GROUND SETUP\n"
        .. "12 RECOVERY BINGO\n"
        .. "\n"
        .. "13 NIGHT OPS\n"
        .. "14 IMC OPS\n"
        .. "15 FORMATION\n"
        .. "16 CARRIER PATTERN\n",

    -- 8: FLT WARN page 2
    [8] = ""
        .. "ELECTRICAL FIRE\n"
        .. " GEN 1&2 -- OFF\n"
        .. " BUS TIE -- OPEN\n"
        .. " LAND ASAP\n"
        .. "\n"
        .. "DUAL GEN FAIL\n"
        .. " EMER BATT ONLY\n"
        .. " NAV/COMM DEGRADED\n"
        .. "\n"
        .. "EJECTION\n"
        .. " HANDLE -- PULL\n"
        .. " KEEP ARMS/LEGS IN\n"
        .. " HEAD BACK\n",
}

-- get(submenu_id, level) -> string (never nil, always safe to :set()).
function M.get(submenu_id, level)
    if not submenu_id or submenu_id == 0 then return "" end
    local title = M.TITLES[submenu_id]
    if not title then return "" end   -- unknown id -> empty (page shows nothing)
    local body
    if level == 2 then
        body = M.PAGE2[submenu_id]
    else
        body = M.PAGE1[submenu_id]
    end
    if body == nil or body == "" then
        return " " .. title .. "\n\n (no data)"
    end
    return " " .. title .. "\n\n" .. body
end

return M
