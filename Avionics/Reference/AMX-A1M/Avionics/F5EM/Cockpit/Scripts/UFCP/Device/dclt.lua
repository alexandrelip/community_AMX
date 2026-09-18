HUD_DCLT = get_param_handle("HUD_DCLT")
dofile(LockOn_Options.script_path.."Systems/avionics_api.lua")

-- [F-5EM 2026-07-12] Declutter multi-level (0=NORM, 1=REJ1, 2=REJ2).
-- Convenção Elbit F-5EM real (SO5-1F-1):
--   NORM (0): full symbology.
--   REJ1 (1): esconde elementos secundários de navegação (VS scale, VOR,
--             FTI/DTK dist, DOI) -- típico em cruzeiro.
--   REJ2 (2): esconde adicionalmente Radar Alt, Mach, AoA text, EGIR
--             -- deixa só FPM + pitch ladder + horizonte + digital
--             IAS/ALT/HDG box + master mode + warnings. Uso em combate.
--
-- Cycle: UFCP > MISC > DCLT joy right cycla 0->1->2->0.
-- Consumido em HUD_ALL.lua via controllers "parameter_in_range".

-- Variables
ufcp_dclt = 0; -- 0=NORM, 1=REJ1, 2=REJ2 (manual, do piloto)
local DCLT_LEVELS = { [0] = "ATT/FPM", [1] = "REJ1   ", [2] = "REJ2   " }
local DCLT_MAX_LEVEL = 2

-- [F-5EM 2026-07-12 v0.75] AUTO-DCLT: Elbit real automatically forca REJ1
-- em modes A-A / A-G (combate = menos clutter). Piloto pode override
-- manualmente cyclando para NORM. HUD_DCLT publicado = max(manual, auto).
local COMBAT_MODES = {
    [AVIONICS_MASTER_MODE_ID.INT_S]  = true,
    [AVIONICS_MASTER_MODE_ID.INT_M]  = true,
    [AVIONICS_MASTER_MODE_ID.DGFT_S] = true,
    [AVIONICS_MASTER_MODE_ID.DGFT_M] = true,
    [AVIONICS_MASTER_MODE_ID.GUN]    = true,
    [AVIONICS_MASTER_MODE_ID.GUN_R]  = true,
    [AVIONICS_MASTER_MODE_ID.GUN_M]  = true,
    [AVIONICS_MASTER_MODE_ID.DTOS]   = true,
    [AVIONICS_MASTER_MODE_ID.DTOS_R] = true,
    [AVIONICS_MASTER_MODE_ID.CCRP]   = true,
    [AVIONICS_MASTER_MODE_ID.CCIP]   = true,
    [AVIONICS_MASTER_MODE_ID.CCIP_R] = true,
    [AVIONICS_MASTER_MODE_ID.MAN]    = true,
}

-- Methods

function update_dclt()
    local text = ""
    text = text .. "DCLT\n\n"
    text = text .. "*" .. (DCLT_LEVELS[ufcp_dclt] or "ATT/FPM") .. "*"

    text = text .. "\n\n"
    text = replace_pos(text, 7)
    text = replace_pos(text, 15)

    -- Auto-DCLT: forca HUD_DCLT >= 1 em combat modes.
    local effective = ufcp_dclt
    local master_mode = get_avionics_master_mode()
    if COMBAT_MODES[master_mode] and effective < 1 then
        effective = 1
    end
    HUD_DCLT:set(effective)

    UFCP_TEXT:set(text)
end

function SetCommandDclt(command,value)
    if command == device_commands.UFCP_JOY_RIGHT and value == 1 then
        ufcp_dclt = (ufcp_dclt + 1) % (DCLT_MAX_LEVEL + 1)
    end
end