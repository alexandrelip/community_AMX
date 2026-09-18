dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."functions.lua")
dofile(LockOn_Options.script_path.."HUD/HUD_ID_defs.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."Systems/alarm_api.lua")
dofile(LockOn_Options.script_path.."Systems/avionics_api.lua")
dofile(LockOn_Options.script_path.."Systems/weapon_system_api.lua")
dofile(LockOn_Options.script_path.."Systems/ufcp_api.lua")
dofile(LockOn_Options.script_path.."Systems/rdr_api.lua")
local HUD_RALT_EVAL = dofile(LockOn_Options.script_path.."Systems/hud_ralt.lua")
local COMBAT_DISPLAY = dofile(LockOn_Options.script_path.."Systems/combat_display.lua")
local HUD_CUES = dofile(LockOn_Options.script_path.."Systems/hud_nav_cues.lua")

startup_print("hud: load")

local dev = GetSelf()

local update_time_step = 0.02 --update will be called 50 times per second
make_default_activity(update_time_step)

local sensor_data = get_base_data()

-- local function round_to(value, roundto)
--     value = value + roundto/2
--     return value - value % roundto
-- end


-- [R3.12 hotfix] Lua 5.1 upvalue limit: consolidate the 22 individual
-- HUD_XXX param handles into a single table so update() closes over 1
-- upvalue instead of 22. Before this change, hud.lua's update() had
-- >60 upvalues and DCS refused to load the file with
--   [string "..."]:790: function at line 513 has more than 60 upvalues
-- Access via _HUD_PARAMS.PITCH / .ROLL / .IAS / etc.
-- ★ 2026-07-06 FIX: the initial R3.12 refactor also renamed the underlying
-- param HANDLE names to "_HUD_PARAMS.XXX", which broke every reader in
-- HUD/Indicator/HUD_ALL.lua (which reads "HUD_XXX"). IAS/ALT/FPM/pitch
-- ladder/roll indicator all froze at 0. Restored the original "HUD_XXX"
-- string names so the indicator wire works again; the table (and its
-- upvalue-count benefit) is preserved. See ci/tests/test_hud_param_wiring.lua.
local _HUD_PARAMS = {
    PITCH          = get_param_handle("HUD_PITCH"),
    ROLL           = get_param_handle("HUD_ROLL"),
    PL_GHOST       = get_param_handle("HUD_PL_GHOST"),
    IAS            = get_param_handle("HUD_IAS"),
    HDG            = get_param_handle("HUD_HDG"),
    ALT_FT         = get_param_handle("HUD_ALT_FT"),
    ALT_K          = get_param_handle("HUD_ALT_K"),
    ALT_N          = get_param_handle("HUD_ALT_N"),
    ALT_SCALE_MOVE = get_param_handle("HUD_ALT_SCALE_MOVE"),
    ALT_CUE_MOVE   = get_param_handle("HUD_ALT_CUE_MOVE"),
    ALT_CUE_VALUE  = get_param_handle("HUD_ALT_CUE_VALUE"),
    VEL_SCALE_MOVE = get_param_handle("HUD_VEL_SCALE_MOVE"),
    VEL_CUE_MOVE   = get_param_handle("HUD_VEL_CUE_MOVE"),
    VEL_CUE_VALUE  = get_param_handle("HUD_VEL_CUE_VALUE"),
    HDG_SCALE_MOVE = get_param_handle("HUD_HDG_SCALE_MOVE"),
    HDG_CUE_MOVE   = get_param_handle("HUD_HDG_CUE_MOVE"),
    HDG_CUE_VALUE  = get_param_handle("HUD_HDG_CUE_VALUE"),
    VS_CUE_MOVE    = get_param_handle("HUD_VS_CUE_MOVE"),
    FPM_SLIDE      = get_param_handle("HUD_FPM_SLIDE"),
    FPM_VERT       = get_param_handle("HUD_FPM_VERT"),
    PL_SLIDE       = get_param_handle("HUD_PL_SLIDE"),
    RI_ROLL        = get_param_handle("HUD_RI_ROLL"),
    GS             = get_param_handle("HUD_GS"),
    HDG_SCALE_NUM  = {},
    ALT_SCALE_NUM  = {},
    VEL_SCALE_NUM  = {},
}
for i = 1, 4 do
    _HUD_PARAMS.HDG_SCALE_NUM[i] = get_param_handle("HUD_HDG_SCALE_NUM_"..i)
    _HUD_PARAMS.ALT_SCALE_NUM[i] = get_param_handle("HUD_ALT_SCALE_NUM_"..i)
    _HUD_PARAMS.VEL_SCALE_NUM[i] = get_param_handle("HUD_VEL_SCALE_NUM_"..i)
end

local UFCP_RALT_SWITCH_STATE = get_param_handle("UFCP_RALT_SWITCH_STATE")

local HUD = {
    CCRP = get_param_handle("HUD_CCRP"),
    FYT_AZIMUTH = get_param_handle("HUD_FYT_AZIMUTH"),
    FYT_ELEVATION = get_param_handle("HUD_FYT_ELEVATION"),
    FYT_OS = get_param_handle("HUD_FYT_OS"),
    FYT_HIDE = get_param_handle("HUD_FYT_HIDE"),
    TD_AZIMUTH = get_param_handle("HUD_TD_AZIMUTH"),
    TD_ELEVATION = get_param_handle("HUD_TD_ELEVATION"),
    TD_OS = get_param_handle("HUD_TD_OS"),
    TD_HIDE = get_param_handle("HUD_TD_HIDE"),
    TD_ANGLE = get_param_handle("HUD_TD_ANGLE"),
    MAX_RANGE = get_param_handle("HUD_MAX_RANGE"),
    SL_AZIMUTH = get_param_handle("HUD_SL_AZIMUTH"),
    SI_ELEVATION = get_param_handle("HUD_SI_ELEVATION"),
    SI_HIDE = get_param_handle("HUD_SI_HIDE"),
    -- [A-29 parity 2026-07-21] HUD_SHOW_TD: gate for the target designator that
    -- covers CCRP + CCIP-DELAYED + MAN(AG_GUIDED_MISSILE). Consumed by
    -- HUD_AG.lua opacity controllers.
    SHOW_TD = get_param_handle("HUD_SHOW_TD"),
    EGIR = get_param_handle("HUD_EGIR"),
    RALT_STATE = get_param_handle("HUD_RALT_STATE"),
    RALT_MIN = get_param_handle("HUD_RALT_MIN"),
    RALT_ALERT = get_param_handle("HUD_RALT_ALERT"),
    RALT_MIN_INPUT = get_param_handle("UFCP_DAH_RALT"),
    COMBAT_SOURCE = get_param_handle("F5EM_COMBAT_TARGET_SOURCE"),
    COMBAT_SENSOR_STATE = get_param_handle("F5EM_COMBAT_SENSOR_STATE"),
    COMBAT_WEAPON_STATE = get_param_handle("F5EM_COMBAT_WEAPON_STATE"),
    COMBAT_MODE_ACTIVE = get_param_handle("F5EM_COMBAT_MODE_ACTIVE"),
    COMBAT_SHOW = get_param_handle("F5EM_COMBAT_TARGET_SHOW"),
    COMBAT_AZ = get_param_handle("F5EM_COMBAT_TARGET_AZ"),
    COMBAT_EL = get_param_handle("F5EM_COMBAT_TARGET_EL"),
    COMBAT_RANGE_NM = get_param_handle("F5EM_COMBAT_TARGET_RANGE_NM"),
    COMBAT_RANGE_VALID = get_param_handle("F5EM_COMBAT_TARGET_RANGE_VALID"),
    COMBAT_ALT_KFT = get_param_handle("F5EM_COMBAT_TARGET_ALT_KFT"),
    COMBAT_ALT_FT = get_param_handle("F5EM_COMBAT_TARGET_ALT_FT"),
    COMBAT_ALT_VALID = get_param_handle("F5EM_COMBAT_TARGET_ALT_VALID"),
    COMBAT_CLOSURE_KT = get_param_handle("F5EM_COMBAT_TARGET_CLOSURE_KT"),
    COMBAT_CLOSURE_VALID = get_param_handle("F5EM_COMBAT_TARGET_CLOSURE_VALID"),
    COMBAT_TTI_SEC = get_param_handle("F5EM_COMBAT_TARGET_TTI_SEC"),
    COMBAT_TTI_VALID = get_param_handle("F5EM_COMBAT_TARGET_TTI_VALID"),
    COMBAT_ASPECT = get_param_handle("F5EM_COMBAT_TARGET_ASPECT"),
    COMBAT_ASPECT_VALID = get_param_handle("F5EM_COMBAT_TARGET_ASPECT_VALID"),
    COMBAT_READY_STATE = get_param_handle("F5EM_COMBAT_READY_STATE"),
    COMBAT_IN_LS_ALT = get_param_handle("RADAR_BUG_ALT"),
    COMBAT_IN_LS_CLOSURE = get_param_handle("RADAR_BUG_CLOSURE"),
    COMBAT_IN_RADAR_MODE = get_param_handle("RDR_MODE"),
    COMBAT_IN_ACM_SUBMODE = get_param_handle("RDR_ACM_SUB"),
    CCIP_DELAYED_AZIMUTH = get_param_handle("HUD_CCIP_DELAYED_AZIMUTH"),
    CCIP_DELAYED_ELEVATION = get_param_handle("HUD_CCIP_DELAYED_ELEVATION"),
    TIME_TO_IMPACT = get_param_handle("HUD_TIME_TO_IMPACT"),

    -- [F-5EM HUD fidelity 2026-08-29] Great-circle steering cue ("tadpole"),
    -- bullseye BRA, laser-code readback and missile-launch flag. All of these
    -- live in the HUD table on purpose: update() is at 55 upvalues and the
    -- Lua 5.1 ceiling enforced by ci/lint/upvalue_guard.lua is 60.
    TADPOLE_OFFSET = get_param_handle("HUD_TADPOLE_OFFSET"),
    TADPOLE_SHOW = get_param_handle("HUD_TADPOLE_SHOW"),
    TIME_MODE = get_param_handle("HUD_TIME_MODE"),
    TIME_H = get_param_handle("HUD_TIME_H"),
    TIME_M = get_param_handle("HUD_TIME_M"),
    TIME_S = get_param_handle("HUD_TIME_S"),
    BE_BRG = get_param_handle("HUD_BE_BRG"),
    BE_RNG_NM = get_param_handle("HUD_BE_RNG_NM"),
    BE_SHOW = get_param_handle("HUD_BE_SHOW"),
    LASER_CODE = get_param_handle("HUD_LASER_CODE"),
    LASER_CODE_SHOW = get_param_handle("HUD_LASER_CODE_SHOW"),
    LAUNCH_WARN = get_param_handle("HUD_LAUNCH_WARN"),
    IN_BE_BRG = get_param_handle("BULLSEYE_BRG"),
    IN_BE_RNG = get_param_handle("BULLSEYE_RNG"),
    IN_FYT_VALID = get_param_handle("CMFD_NAV_FYT_VALID"),
    IN_VOR_DIST = get_param_handle("ADHSI_VOR_DIST"),
    IN_VOR_HDG = get_param_handle("ADHSI_VOR_HDG"),
    IN_VOR_VALID = get_param_handle("ADHSI_VOR_VALID"),
    IN_VOR_DME_VALID = get_param_handle("ADHSI_VOR_DME_VALID"),
    IN_WPN_LASER_CODE = get_param_handle("WPN_LASER_CODE"),
    IN_WPN_LASER_SELECTED = get_param_handle("WPN_LASER_SELECTED"),
    IN_RWR_LAUNCH_VALID = get_param_handle("RWR_LAUNCH_AZ_VALID"),

    OAP_HIDE = get_param_handle("HUD_OAP_HIDE"),
    OAP_OS = get_param_handle("HUD_OAP_OS"),
    OAP_AZIMUTH = get_param_handle("HUD_OAP_AZIMUTH"),
    OAP_ELEVATION = get_param_handle("HUD_OAP_ELEVATION"),

    TIP_HIDE = get_param_handle("HUD_TIP_HIDE"),
    TIP_OS = get_param_handle("HUD_TIP_OS"),
    TIP_AZIMUTH = get_param_handle("HUD_TIP_AZIMUTH"),
    TIP_ELEVATION = get_param_handle("HUD_TIP_ELEVATION"),

    STT_AZ = get_param_handle("HUD_STT_AZ"),
    STT_EL = get_param_handle("HUD_STT_EL"),
    STT_SHOW = get_param_handle("HUD_STT_SHOW"),
    -- [F-5EM 2026-07-08] Range do alvo em NM (label ao lado do TD box).
    -- Bate com fotos reais 1o/14 GAV -- pequeno numero decimal proximo
    -- ao quadrado indicando distancia atual do alvo lockado.
    STT_RANGE_NM = get_param_handle("HUD_STT_RANGE_NM"),
    -- [F-5EM 2026-07-08 aspect] Angulo de aspecto do alvo (rad).
    -- Usado p/ rotacionar o triangulo (▽/△) no topo do TD box:
    --   0 rad   = nose-on (▽ apontando para baixo)
    --   pi rad  = tail (△ apontando para cima)
    --   ±pi/2  = beam (◁/▷)
    -- Real F-5EM Elbit mostra isso p/ o piloto avaliar geometria.
    STT_ASPECT = get_param_handle("HUD_STT_ASPECT"),

    -- [F-5EM v0.61.1 2026-07-10] L&S marker (BVR bug). Distinto do TD box
    -- de STT: quadrado hollow MENOR (10x10 mils) DESENHADO SEMPRE que ha
    -- L&S ativo em INT_M/DGFT_M (radar missile master mode) SEM STT hard-
    -- lock. Bate com o F-5M FAB real (Elbit/Grifo-F) que mostra marker do
    -- L&S bugado no HUD durante intercept BVR com Derby. Nao pisca (único
    -- Elbit convention: STT hard-lock pisca, L&S bug NAO). Mutuamente
    -- exclusivo com o TD box ("promocao" a STT esconde o L&S marker).
    -- Valores de LS_SHOW: 0=oculto, 1=visivel dentro do HUD, 2=limitado
    -- pela borda do HUD (offset). LS_RANGE_NM em NM (label ao lado do
    -- marker, igual STT_RANGE_NM).
    LS_AZ = get_param_handle("HUD_LS_AZ"),
    LS_EL = get_param_handle("HUD_LS_EL"),
    LS_SHOW = get_param_handle("HUD_LS_SHOW"),
    LS_RANGE_NM = get_param_handle("HUD_LS_RANGE_NM"),

    FLIR_AZ = get_param_handle("HUD_FLIR_AZ"),
    FLIR_EL = get_param_handle("HUD_FLIR_EL"),
    FLIR_SHOW = get_param_handle("HUD_FLIR_SHOW"),
    FLIR_RANGE_NM = get_param_handle("HUD_FLIR_RANGE_NM"),
    FLIR_LASER_STATE = get_param_handle("HUD_FLIR_LASER_STATE"),
    FLIR_IN_POD = get_param_handle("FLIR_POD_PRESENT"),
    FLIR_IN_STATUS = get_param_handle("FLIR_STATUS"),
    FLIR_IN_TARGET = get_param_handle("FLIR_TGT_AVAILABLE"),
    FLIR_IN_AZ = get_param_handle("FLIR_AZ"),
    FLIR_IN_EL = get_param_handle("FLIR_EL"),
    FLIR_IN_RANGE_M = get_param_handle("FLIR_LRF_RANGE_M"),
    FLIR_IN_LASER_STATE = get_param_handle("F5EM_FLIR_LASER_STATE"),

    DLZ_MIN = get_param_handle("HUD_DLZ_MIN"),
    DLZ_MAX = get_param_handle("HUD_DLZ_MAX"),
    DLZ_BEST = get_param_handle("HUD_DLZ_BEST"),
    DLZ_NOW = get_param_handle("HUD_DLZ_NOW"),
    DLZ_MIN_NM = get_param_handle("HUD_DLZ_MIN_NM"),
    DLZ_MAX_NM = get_param_handle("HUD_DLZ_MAX_NM"),
    DLZ_BEST_NM = get_param_handle("HUD_DLZ_BEST_NM"),
}
local WPN = {
    TD_AZIMUTH = get_param_handle("WPN_TD_AZIMUTH"),
    TD_ELEVATION = get_param_handle("WPN_TD_ELEVATION"),
    -- [A-29 parity 2026-07-21] TD_AVAILABLE gate published by weapon_system.lua
    -- update_ccrp/update_man_guided_td. Consumed by hud.lua update_td for the
    -- HUD.SHOW_TD show/hide contract.
    TD_AVAILABLE = get_param_handle("WPN_TD_AVAILABLE"),
    CCRP_TIME = get_param_handle("WPN_CCRP_TIME"),
    TIME_MAX_RANGE = get_param_handle("WPN_TIME_MAX_RANGE"),
    WEAPON_RELEASE = get_param_handle("WPN_WEAPON_RELEASE"),
    CCIP_DELAYED_TIME = get_param_handle("WPN_CCIP_DELAYED_TIME"),
    CCIP_DELAYED = get_param_handle("WPN_CCIP_DELAYED"),
    TIME_TO_IMPACT = get_param_handle("WPN_TIME_TO_IMPACT"),
}

local CMFD = {
    NAV_FYT_VALID = get_param_handle("CMFD_NAV_FYT_VALID"),
    NAV_FYT_DTK_DIST = get_param_handle("CMFD_NAV_FYT_DTK_DIST"),
    NAV_OAP_AZIMUTH = get_param_handle("CMFD_NAV_OAP_AZIMUTH"),
    NAV_OAP_ELEVATION = get_param_handle("CMFD_NAV_OAP_ELEVATION"),
}

local UFCP = {
    OAP_ENABLED = get_param_handle("UFCP_OAP"), -- 0disabled 1enabled
    TIP_DIR = get_param_handle("UFCP_TIP_DIR"), -- -1left 0disabled 1right
    TIP_ALONG = get_param_handle("UFCP_TIP_ALONG"), -- in NM
    TIP_ACROSS = get_param_handle("UFCP_TIP_ACROSS"), -- in NM
}

-- ★ 2026-07-06 Elbit F-5EM HUD annunciators (safety + shoot cue). Consolidated
-- in a single table so update() closes over 1 additional upvalue (Lua 5.1 limit).
-- Inputs (published elsewhere) + outputs (consumed by HUD/Indicator/HUD_ALL.lua).
local _HUD_WARN = {
    IN_STALL     = get_param_handle("AVIONICS_STALL"),   -- Systems/avionics.lua limit_check
    IN_OVERG     = get_param_handle("AVIONICS_OVERG"),   -- Systems/avionics.lua limit_check
    IN_OVERSPEED = get_param_handle("AVIONICS_OVERSPEED"), -- Systems/limit_check.lua max_vel / max_mach
    OUT_OVERSPEED = get_param_handle("HUD_OVSPD_WARN"),
    IN_BINGO     = get_param_handle("BINGO_ACTIVE"),     -- CMFD/Device/tactical_overlay.lua
    IN_SHOOT_CUE = get_param_handle("RADAR_SHOOT_CUE"),  -- Systems/rdr.lua DLZ (TWS+L&S+Derby ready)
    -- [F-5EM auto-lock 2026-07-08] IN RNG: Rmax > alvo > NEZ (pode atirar
    -- mas alvo pode escapar). Publicado por rdr.lua tambem no bloco DLZ.
    IN_RNG_CUE   = get_param_handle("RADAR_IN_RNG_CUE"),
    -- [F-5EM v0.61.9 2026-07-11] Lock IR do seeker (Python/AIM-9/MAA-1B).
    -- Publicado pelo engine DCS via WS_IR_MISSILE_LOCK (0/1). Usado p/
    -- gate visual do losango de lock IR no HUD (aparece SEMPRE que o
    -- growl LOCK tone toca em check_sidewinder do weapon_system.lua).
    IN_IR_LOCK   = get_param_handle("WS_IR_MISSILE_LOCK"),
    IN_IR_STATE = get_param_handle("F5EM_IR_STATE"),
    IN_IR_RANGE = get_param_handle("F5EM_IR_IN_RNG"),
    OUT_STALL = get_param_handle("HUD_STALL_WARN"),
    OUT_OVERG = get_param_handle("HUD_OVERG_WARN"),
    OUT_BINGO = get_param_handle("HUD_BINGO_WARN"),
    OUT_SHOOT = get_param_handle("HUD_SHOOT_WARN"),
    OUT_IN_RNG= get_param_handle("HUD_IN_RNG_WARN"),
    -- [F-5EM Elbit 2026-07-09] Opacidade+blink do circulo ASE. Valor final ja
    -- inclui HUD_BRIGHT e o gate de blink -- HUD_ALL usa apenas este handle
    -- para opacity_using_parameter do HUD_ASE_origin.
    OUT_ASE_BLINK = get_param_handle("HUD_ASE_BLINK"),
    -- [F-5EM v0.61.9 2026-07-11] Losango de lock IR (piscando 2Hz quando
    -- WS_IR_MISSILE_LOCK == 1 + master A/A). Publicado como 1/0 -- HUD
    -- indicator usa parameter_compare_with_number,X,1.
    OUT_IR_LOCK_BLINK = get_param_handle("HUD_IR_LOCK_BLINK"),
}

-- Visuals
local HUD_DRIFT_CO = get_param_handle("HUD_DRIFT_CO")
local HUD_DCLT = get_param_handle("HUD_DCLT")
local HUD_FPM_CROSS = get_param_handle("HUD_FPM_CROSS")

local HUD_NORMAL_ACCEL = get_param_handle("HUD_NORMAL_ACCEL")
local HUD_MAX_ACCEL = get_param_handle("HUD_MAX_ACCEL")
local HUD_RDY = get_param_handle("HUD_RDY")
local HUD_DOI = get_param_handle("HUD_DOI")
local HUD_RADAR_ALT = get_param_handle("HUD_RADAR_ALT")
local HUD_RANGE = get_param_handle("HUD_RANGE")
local HUD_TIME = get_param_handle("HUD_TIME")
local HUD_FTI_DIST = get_param_handle("HUD_FTI_DIST")
local HUD_FTI_NUM = get_param_handle("HUD_FTI_NUM")
local HUD_VOR_DIST = get_param_handle("HUD_VOR_DIST")
local HUD_VOR_MAG = get_param_handle("HUD_VOR_MAG")
local HUD_MACH = get_param_handle("HUD_MACH")


local HUD_AOA = get_param_handle("HUD_AOA")
local HUD_AOA_DELTA = get_param_handle("HUD_AOA_DELTA")
local HUD_PL = get_param_handle("HUD_PL")

local HUD_ON = get_param_handle("HUD_ON")

local HUD_BRIGHT = get_param_handle("HUD_BRIGHT")

local CMFDDoi = get_param_handle("CMFDDoi")

local hud_piper_diameter = math.rad(1.8)
local hud_limit = {
    x= math.rad(6),
    y = math.rad(6)
}

-- [A-29 parity 2026-07-21] CCRP/GBU HUD calibration preset (radians; 1 mrad = 0.001 rad).
-- Only applied when master mode == CCRP AND selected weapon is AG_UNGUIDED_BOMB.
-- Values ported byte-for-byte from A29MEFM/Cockpit/Scripts/Systems/hud.lua v0.9.0.0.
local HUD_CCRP_GBU_TD_AZ_GAIN = 1.00
local HUD_CCRP_GBU_TD_EL_GAIN = 1.00
local HUD_CCRP_GBU_TD_AZ_BIAS = 0.00000
local HUD_CCRP_GBU_TD_EL_BIAS = -0.00020
local HUD_CCRP_GBU_LIMIT_GAIN = 1.05
local HUD_CCRP_GBU_SI_BIAS   = 0.00010

local HUD_PIPER_LINE_A_X = get_param_handle("HUD_PIPER_LINE_A_X")
local HUD_PIPER_LINE_A_Y = get_param_handle("HUD_PIPER_LINE_A_Y")
local HUD_PIPER_LINE_B_X = get_param_handle("HUD_PIPER_LINE_B_X")
local HUD_PIPER_LINE_B_Y = get_param_handle("HUD_PIPER_LINE_B_Y")
local HUD_PIPER_LINE_C_X = get_param_handle("HUD_PIPER_LINE_C_X")
local HUD_PIPER_LINE_C_Y = get_param_handle("HUD_PIPER_LINE_C_Y")
local HUD_PIPER_X = get_param_handle("HUD_PIPER_X")
local HUD_PIPER_Y = get_param_handle("HUD_PIPER_Y")
local HUD_PIPER_HIDDEN = get_param_handle("HUD_PIPER_HIDDEN")
local HUD_IR_MISSILE_TARGET_AZIMUTH = get_param_handle("HUD_IR_MISSILE_TARGET_AZIMUTH")
local HUD_IR_MISSILE_TARGET_ELEVATION = get_param_handle("HUD_IR_MISSILE_TARGET_ELEVATION")
local HUD_MSL_HIDDEN = get_param_handle("HUD_MSL_HIDDEN")

local HUD_CCIP_PIPER_AZIMUTH = get_param_handle("HUD_CCIP_PIPER_AZIMUTH")
local HUD_CCIP_PIPER_ELEVATION = get_param_handle("HUD_CCIP_PIPER_ELEVATION")
local HUD_CCIP_PIPER_HIDDEN = get_param_handle("HUD_CCIP_PIPER_HIDDEN")
local HUD_CCIP_DELAYED = get_param_handle("HUD_CCIP_DELAYED")

local RADAR_DLZ_ACTIVE = get_param_handle("RADAR_DLZ_ACTIVE")
local RADAR_DLZ_RMAX_NORM = get_param_handle("RADAR_DLZ_RMAX_NORM")
local RADAR_DLZ_RNE_NORM = get_param_handle("RADAR_DLZ_RNE_NORM")
local RADAR_DLZ_RMIN_NORM = get_param_handle("RADAR_DLZ_RMIN_NORM")
local RADAR_DLZ_TGT_NORM = get_param_handle("RADAR_DLZ_TGT_NORM")

-- [F-5EM auto-lock 2026-07-08] Handles do alvo L&S (BVR/TWS/Derby). Usados
-- pelo bloco Radar STT para desenhar o TD box + ASE circle no alvo BVR
-- mesmo quando o engine nao gera STT classico (INT_M com Derby -> TWS L&S).
local RADAR_LS_ACTIVE = get_param_handle("RADAR_LS_ACTIVE")
local RADAR_LS_AZ     = get_param_handle("RADAR_LS_AZ")
local RADAR_LS_EL     = get_param_handle("RADAR_LS_EL")
local RADAR_LS_RANGE  = get_param_handle("RADAR_LS_RANGE")

local WS_GUN_PIPER_AZIMUTH = get_param_handle("WS_GUN_PIPER_AZIMUTH")
local WS_GUN_PIPER_ELEVATION = get_param_handle("WS_GUN_PIPER_ELEVATION")
local WS_GUN_PIPER_SPAN = get_param_handle("WS_GUN_PIPER_SPAN")
local WS_TARGET_RANGE = get_param_handle("WS_TARGET_RANGE")
local CMFD_NAV_FYT_DTK_BRG = get_param_handle("CMFD_NAV_FYT_DTK_BRG")
local CMFD_NAV_FYT_DTK_DIST = get_param_handle("CMFD_NAV_FYT_DTK_DIST")
local CMFD_NAV_FYT_DTK_AZIMUTH = get_param_handle("CMFD_NAV_FYT_DTK_AZIMUTH")
local CMFD_NAV_FYT_DTK_ELEVATION = get_param_handle("CMFD_NAV_FYT_DTK_ELEVATION")
local CMFD_NAV_FYT_DTK_STT = get_param_handle("CMFD_NAV_FYT_DTK_STT")
local CMFD_NAV_FYT_DTK_TTD = get_param_handle("CMFD_NAV_FYT_DTK_TTD")
local CMFD_NAV_FYT_DTK_DT = get_param_handle("CMFD_NAV_FYT_DTK_DT")


local function update_piper_ccip()
    local slide = _HUD_PARAMS.FPM_SLIDE:get()
    local vert = _HUD_PARAMS.FPM_VERT:get()

    local az = WPN_CCIP_PIPER_AZIMUTH:get() 
    local el = WPN_CCIP_PIPER_ELEVATION:get()
    local limited

    --if WPN_SELECTED_WEAPON_TYPE:get() == WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB then az = az + slide end
    local roll = sensor_data:getRoll()
    local s=math.sin(roll)
    local c=math.cos(roll)

    local az1 = az-- * c - el * s
    local el1 = el-- * c + az * s
    az1 = az1 - slide
    el1 = el1 - vert
    
    local size = math.sqrt(az1 * az1 + el1 * el1)
    az1, el1, limited = limit_xy(az1, el1, hud_limit.x - slide, hud_limit.y - vert, -hud_limit.x - slide, -hud_limit.y * 1.3 - vert)

    az = az1 + slide
    el = el1 + vert

    HUD_CCIP_PIPER_AZIMUTH:set(az)
    HUD_CCIP_PIPER_ELEVATION:set(el)
    HUD_CCIP_PIPER_HIDDEN:set(limited)

    HUD_CCIP_DELAYED:set(WPN.CCIP_DELAYED:get())

    roll = math.atan2(-az1 , -el1)
    s=math.sin(roll)
    c=math.cos(roll)
    
    HUD_PIPER_LINE_A_X:set(slide - 0.004 * s)
    HUD_PIPER_LINE_A_Y:set(vert  - 0.004 * c)

    HUD_PIPER_LINE_B_X:set(az + 0.005 * s)
    HUD_PIPER_LINE_B_Y:set(el + 0.005 * c)

    HUD.CCIP_DELAYED_AZIMUTH:set(az + 0.015 * s )
    HUD.CCIP_DELAYED_ELEVATION:set(el + 0.015 * c )
end

local function global_az_el_to_cockpit(az, el)
    local p_roll = sensor_data.getRoll()
    local s = math.sin(p_roll)
    local c = math.sin(p_roll)

    local az1 = az * c - el * s
    local el1 = az * s + el * c
    return az1, el1
end

local function update_piper_lcos()

    -- WS_GUN_PIPER_SPAN is exported by the weapon system as a half-angle.
    -- Convert to diameter and clamp to a sane HUD range.
    local piper_diameter = hud_piper_diameter
    local span_half = WS_GUN_PIPER_SPAN:get() or 0
    if span_half > 0 then
        local d = span_half * 2
        if d < math.rad(0.6) then d = math.rad(0.6) end
        if d > math.rad(6.0) then d = math.rad(6.0) end
        piper_diameter = d
    end
    
    local piper_x = WS_GUN_PIPER_AZIMUTH:get()
    local piper_y = WS_GUN_PIPER_ELEVATION:get() 

    local limited = false
    piper_x, piper_y, limited = limit_xy(piper_x, piper_y, hud_limit.x, hud_limit.y)
    local piper_dist = math.sqrt(piper_x*piper_x + piper_y*piper_y)
    local piper_line_x, piper_line_y

    if piper_dist ~= 0 then 
        if  piper_dist > piper_diameter/2 then
            piper_line_x = piper_x - piper_diameter/2*piper_x/piper_dist
            piper_line_y = piper_y - piper_diameter/2*piper_y/piper_dist
            HUD_PIPER_LINE_A_X:set(piper_line_x)
            HUD_PIPER_LINE_A_Y:set(piper_line_y)
        else 
            HUD_PIPER_LINE_A_X:set(0)
            HUD_PIPER_LINE_A_Y:set(0)
        end
        piper_line_x = piper_x + piper_diameter/2*piper_x/piper_dist
        piper_line_y = piper_y + piper_diameter/2*piper_y/piper_dist
        HUD_PIPER_LINE_B_X:set(piper_line_x)
        HUD_PIPER_LINE_B_Y:set(piper_line_y)
        piper_line_x = piper_x + piper_diameter*piper_x/piper_dist
        piper_line_y = piper_y + piper_diameter*piper_y/piper_dist
        HUD_PIPER_LINE_C_X:set(piper_line_x)
        HUD_PIPER_LINE_C_Y:set(piper_line_y)
    else 
        HUD_PIPER_LINE_A_X:set(0)
        HUD_PIPER_LINE_A_Y:set(0)
        HUD_PIPER_LINE_B_X:set(0)
        HUD_PIPER_LINE_B_Y:set(0)
        HUD_PIPER_LINE_C_X:set(0)
        HUD_PIPER_LINE_C_Y:set(0)
    end

    HUD_PIPER_X:set(piper_x)
    HUD_PIPER_Y:set(piper_y)
    HUD_PIPER_HIDDEN:set(limited)
end

local function update_piper_snap()
    local bullet_speed = 1000 -- m/s
    local piper_x = WS_GUN_PIPER_AZIMUTH:get()
    local piper_y = WS_GUN_PIPER_ELEVATION:get()
    local limited = false
    local time_to_piper = WS_TARGET_RANGE:get() / bullet_speed

    -- piper_x, piper_y, limited = limit_xy(piper_x, piper_y, hud_limit.x, hud_limit.y)

    local piper_dist = math.sqrt(piper_x*piper_x + piper_y*piper_y)
    local piper_line_x = 0
    local piper_line_y = 0

    if time_to_piper ~= 0 then 
        piper_line_x = piper_x * 0.5 / time_to_piper
        piper_line_y = piper_y * 0.5 / time_to_piper
        HUD_PIPER_LINE_A_X:set(piper_line_x)
        HUD_PIPER_LINE_A_Y:set(piper_line_y)
        piper_line_x = piper_x * 0.5 / time_to_piper
        piper_line_y = piper_y * 0.5 / time_to_piper
        HUD_PIPER_LINE_B_X:set(piper_line_x)
        HUD_PIPER_LINE_B_Y:set(piper_line_y)
        piper_line_x = piper_x * 0.5 / time_to_piper
        piper_line_y = piper_y * 0.5 / time_to_piper
        HUD_PIPER_LINE_C_X:set(piper_line_x)
        HUD_PIPER_LINE_C_Y:set(piper_line_y)
    else 
        HUD_PIPER_LINE_A_X:set(0)
        HUD_PIPER_LINE_A_Y:set(0)
        HUD_PIPER_LINE_B_X:set(0)
        HUD_PIPER_LINE_B_Y:set(0)
        HUD_PIPER_LINE_C_X:set(0)
        HUD_PIPER_LINE_C_Y:set(0)
    end

    if time_to_piper > 1.5 then 
        piper_x = piper_x * 1.5 / time_to_piper
        piper_y = piper_y * 1.5 / time_to_piper
    end

    HUD_PIPER_X:set(piper_x)
    HUD_PIPER_Y:set(piper_y)
    HUD_PIPER_HIDDEN:set(limited)
end


local function update_aa()
    local wpn_aa_sight = WPN_AA_SIGHT:get()
    if  wpn_aa_sight == WPN_AA_SIGHT_IDS.LCOS or wpn_aa_sight == WPN_AA_SIGHT_IDS.SSLC then update_piper_lcos() end
    if  wpn_aa_sight == WPN_AA_SIGHT_IDS.SNAP or wpn_aa_sight == WPN_AA_SIGHT_IDS.SSLC then update_piper_snap() end
    local master_mode = get_avionics_master_mode()

    local msl_az = WS_IR_MISSILE_TARGET_AZIMUTH:get()
    local msl_el = WS_IR_MISSILE_TARGET_ELEVATION:get()
    local msl_hidden
    msl_az, msl_el, msl_hidden = limit_xy(msl_az, msl_el, hud_limit.x, hud_limit.y)
    HUD_IR_MISSILE_TARGET_AZIMUTH:set(msl_az)
    HUD_IR_MISSILE_TARGET_ELEVATION:set(msl_el)
    HUD_MSL_HIDDEN:set(msl_hidden)


    if master_mode == AVIONICS_MASTER_MODE_ID.DGFT_M or master_mode == AVIONICS_MASTER_MODE_ID.DGFT_S then
        HUD_RANGE:set(WS_TARGET_RANGE:get())
        if get_wpn_aa_msl_ready() then
        end
    else 
        HUD_RANGE:set(-1)
    end
    
end

local function update_ag()
    local master_mode = get_avionics_master_mode()
    if master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R or get_avionics_master_mode_ag_gun(master_mode) then 
        update_piper_ccip() 
    end
    if get_avionics_master_mode_ag_gun() then
        HUD_RANGE:set(WS_TARGET_RANGE:get())
    else 
        HUD_RANGE:set(-1)
    end
    
end

local function update_oap()
    if (UFCP.OAP_ENABLED:get() == 1) and (HUD.FYT_HIDE:get() == 0 or HUD.TD_HIDE:get() == 0) then
        local oap_azimuth = CMFD.NAV_OAP_AZIMUTH:get()
        local oap_elevation = CMFD.NAV_OAP_ELEVATION:get()
        local oap_angle = math.atan2(oap_elevation - math.rad(1.2), oap_azimuth)
        
        local hud_oap_azimuth, hud_oap_elevation, hud_oap_os = limit_xy(CMFD.NAV_OAP_AZIMUTH:get(), CMFD.NAV_OAP_ELEVATION:get(), hud_limit.x, hud_limit.y, -hud_limit.x, -hud_limit.y * 1.3)
        HUD.OAP_AZIMUTH:set(hud_oap_azimuth)
        HUD.OAP_ELEVATION:set(hud_oap_elevation)
        HUD.OAP_OS:set(hud_oap_os)
        HUD.OAP_HIDE:set(0)
    else
        HUD.OAP_HIDE:set(1)
    end
end

local function update_tip()
    if UFCP.TIP_DIR:get() == 0 or CMFD.NAV_FYT_VALID:get() ~= 1 or HUD.FYT_HIDE:get() ~= 0 then
        HUD.TIP_HIDE:set(1)
        HUD.TIP_OS:set(0)
        return
    end

    local dist_nm = CMFD_NAV_FYT_DTK_DIST:get()
    if dist_nm < 0.25 then dist_nm = 0.25 end

    local base_az = CMFD_NAV_FYT_DTK_AZIMUTH:get()
    local base_el = CMFD_NAV_FYT_DTK_ELEVATION:get()
    local vec_norm = math.sqrt(base_az * base_az + base_el * base_el)

    local u_x, u_y = 0, -1
    if vec_norm > 1e-4 then
        u_x = base_az / vec_norm
        u_y = base_el / vec_norm
    end

    local p_x = -u_y
    local p_y = u_x

    local along = (UFCP.TIP_ALONG:get() or 0) / dist_nm
    local across = ((UFCP.TIP_ACROSS:get() or 0) * UFCP.TIP_DIR:get()) / dist_nm

    local tip_az = base_az + u_x * along + p_x * across
    local tip_el = base_el + u_y * along + p_y * across

    local hud_tip_az, hud_tip_el, hud_tip_os = limit_xy(tip_az, tip_el, hud_limit.x, hud_limit.y, -hud_limit.x, -hud_limit.y * 1.3)
    HUD.TIP_AZIMUTH:set(hud_tip_az)
    HUD.TIP_ELEVATION:set(hud_tip_el)
    HUD.TIP_OS:set(hud_tip_os)
    HUD.TIP_HIDE:set(0)
end

-- [A-29 parity 2026-07-21] update_td ported from A29MEFM v0.9.0.0.
-- Adds:
--   * GBU tuning (TD az/el gain+bias, LIMIT_GAIN, SI_BIAS) when master_mode
--     == CCRP AND WPN_SELECTED_WEAPON_TYPE == AG_UNGUIDED_BOMB.
--   * MAN + AG_GUIDED_MISSILE branch shows TD from FLIR designation.
--   * HUD.SHOW_TD unified show_td/td_available/limit gate for opacity.
--   * time_to_impact clamp -5..+5 (was only +5 in F-5EM baseline).
--   * SI bias adds HUD_CCRP_GBU_SI_BIAS when GBU CCRP is active.
-- Preserves F-5EM handle namespace: _HUD_PARAMS.FPM_VERT (not HUD_FPM_VERT).
-- REGRA NUMERO 1: A/A (INT/DGFT) branch untouched (get_avionics_master_mode_aa()).
local function update_td()
    local master_mode = get_avionics_master_mode()
    local show_td = false

    local td_azimuth   = WPN.TD_AZIMUTH:get() or 0
    local td_elevation = WPN.TD_ELEVATION:get() or 0
    local td_available = (WPN.TD_AVAILABLE:get() or 0) == 1
    local ccrp_gbu_tuning_active = (master_mode == AVIONICS_MASTER_MODE_ID.CCRP)
        and (WPN_SELECTED_WEAPON_TYPE:get() == WPN_WEAPON_TYPE_IDS.AG_UNGUIDED_BOMB)

    if ccrp_gbu_tuning_active then
        td_azimuth   = td_azimuth   * HUD_CCRP_GBU_TD_AZ_GAIN + HUD_CCRP_GBU_TD_AZ_BIAS
        td_elevation = td_elevation * HUD_CCRP_GBU_TD_EL_GAIN + HUD_CCRP_GBU_TD_EL_BIAS
    end

    local td_angle = math.atan2(td_elevation - math.rad(1.2), td_azimuth)

    local hud_fyt_azimuth, hud_fyt_elevation, hud_fyt_os, hud_fyt_lim_x, hud_fyt_lim_y = limit_xy(CMFD_NAV_FYT_DTK_AZIMUTH:get(), CMFD_NAV_FYT_DTK_ELEVATION:get(), hud_limit.x, hud_limit.y, -hud_limit.x, -hud_limit.y * 1.3)
    HUD.FYT_AZIMUTH:set(hud_fyt_azimuth)
    HUD.FYT_ELEVATION:set(hud_fyt_elevation)
    HUD.FYT_OS:set(hud_fyt_os)
    HUD.FYT_HIDE:set(0)

    local time_to_impact = WPN.CCRP_TIME:get() or 0

    if master_mode == AVIONICS_MASTER_MODE_ID.CCRP and (get_wpn_mass() == WPN_MASS_IDS.SAFE or get_avionics_onground() or (get_wpn_mass() == WPN_MASS_IDS.LIVE and WPN_AG_SEL:get() == 0) or (get_wpn_mass() == WPN_MASS_IDS.SIM and WPN_AG_SEL:get() == 0) ) then
        HUD.CCRP:set(0)
    elseif master_mode == AVIONICS_MASTER_MODE_ID.CCRP then
        HUD.CCRP:set(1)
        HUD.FYT_HIDE:set(1)
        show_td = true
    elseif (master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) and WPN.CCIP_DELAYED:get() == 1 then
        HUD.CCRP:set(1)
        time_to_impact = WPN.CCIP_DELAYED_TIME:get() or 0
        show_td = true
    elseif master_mode == AVIONICS_MASTER_MODE_ID.MAN and WPN_SELECTED_WEAPON_TYPE:get() == WPN_WEAPON_TYPE_IDS.AG_GUIDED_MISSILE and td_available then
        HUD.CCRP:set(0)
        show_td = true
    elseif get_avionics_master_mode_aa() then
        HUD.CCRP:set(0)
        HUD.FYT_HIDE:set(1)
    else
        HUD.CCRP:set(0)
    end

    local td_limit_x = hud_limit.x
    local td_limit_y = hud_limit.y
    if ccrp_gbu_tuning_active then
        td_limit_x = td_limit_x * HUD_CCRP_GBU_LIMIT_GAIN
        td_limit_y = td_limit_y * HUD_CCRP_GBU_LIMIT_GAIN
    end

    local hud_td_azimuth, hud_td_elevation, hud_td_lim, hud_td_lim_x, hud_td_lim_y = limit_xy(td_azimuth, td_elevation, td_limit_x, td_limit_y, -td_limit_x, -td_limit_y * 1.3)

    HUD.TD_AZIMUTH:set(hud_td_azimuth)
    HUD.TD_ELEVATION:set(hud_td_elevation)
    HUD.TD_OS:set(hud_td_lim_y and 1 or 0)
    HUD.TD_ANGLE:set(td_angle)
    HUD.TD_HIDE:set((not show_td or not td_available or hud_td_lim_x) and 1 or 0)
    HUD.SHOW_TD:set((show_td and td_available) and 1 or 0)
    HUD.SL_AZIMUTH:set(td_azimuth + td_elevation * math.sin(sensor_data.getRoll()))

    local time_to_max_range = WPN.TIME_MAX_RANGE:get() or 0
    if time_to_max_range > 0 and time_to_max_range < 2 then
        HUD.MAX_RANGE:set(1)
    elseif time_to_max_range > -2 and time_to_max_range < 0 then
        local blink_time = math.floor(-time_to_max_range * 10)
        if blink_time % 2 == 0 then HUD.MAX_RANGE:set(1) else HUD.MAX_RANGE:set(0) end
    else 
        HUD.MAX_RANGE:set(0)
    end

    if time_to_impact > 5 then time_to_impact = 5 end
    if time_to_impact < -5 then time_to_impact = -5 end

    if WPN.WEAPON_RELEASE:get() == 1 or time_to_max_range <= 2 then
        HUD.SI_HIDE:set(0)
    elseif time_to_max_range > 2 then 
        HUD.SI_HIDE:set(1)
    end
    local si_bias = -0.0025
    if ccrp_gbu_tuning_active then
        si_bias = si_bias + HUD_CCRP_GBU_SI_BIAS
    end
    HUD.SI_ELEVATION:set(_HUD_PARAMS.FPM_VERT:get() + si_bias + time_to_impact/100)
end


HUD_DCLT:set(0)
HUD_DRIFT_CO:set(0)
UFCP_VAH:set(0)

-- [F-5EM v0.61.13 2026-07-11] Constante pi/4 rad para rotacionar addStrokeBox
-- 45 graus e transforma-lo visualmente em losango. Usado pelo losango de
-- LOCK IR em HUD_AA_DGFT.lua e HUD_AA_INT.lua (controller rotate_using_parameter).
-- Publicado 1x no load, nunca muda -- performance ok.
local HUD_ROT_45 = get_param_handle("HUD_ROT_45")
HUD_ROT_45:set(math.pi / 4)

local max_accel = 0

local hud_warning = get_param_handle("HUD_WARNING")

local time_elapsed = 0
local function blinking(period, duty_cycle, offset)
    period = period or 0.5
    duty_cycle = duty_cycle or 0.5
    offset = offset or 0

    local period_elapsed = ((time_elapsed + offset) % period) / period
    if period_elapsed > duty_cycle then return false
    else return true end
end

-- [F-5EM 2026-07-22 diag] Throttle + last-state p/ o log do TD/L&S box.
-- Ajuda a diagnosticar por que o quadrado nao aparece em volta do alvo:
-- imprime LS/STT az/el, os gates e a solucao combat 1x/s quando em A/A.
local _f5em_tdbox_diag_t = -999
local _f5em_tdbox_diag_last = nil

function update()
    time_elapsed = (time_elapsed + update_time_step) % 3600

    local master_mode = get_avionics_master_mode()
    local hud_on = get_elec_essential_dc_bus_ok() and get_cockpit_draw_argument_value(1843) > 0 and 1 or 0
    local hud_bright = 1-get_cockpit_draw_argument_value(1483)
    if get_cockpit_draw_argument_value(1476) == -1 then hud_bright = hud_bright * 0.5 end

    -- [F-5EM auto-lock 2026-07-08] HUD_RDY semantica alinhada ao jet real
    -- (fotos 1o/14 GAV mostram "RDY-S" quando IR selecionado). Valores:
    --   0 = nada
    --   1 = "RDY" so (gun/A-G generico)
    --   2 = "RDY-S" (Sidewinder-class IR: Python 5 / MAA-1B)
    --   3 = "RDY-M" (Medium radar: Derby)
    -- [FIX 2026-07-08 v2] Detecta pelo MASTER MODE (S=Small/Sidewinder,
    -- M=Medium/Missile), nao pelo weapon type do slot ativo. Isso resolve
    -- o caso "loaded Derby mas em DGFT_S -> gun ativo -> weapon_type=0".
    -- Convencao F-5EM: DGFT_S/INT_S = IR (Python/MAA-1B), DGFT_M/INT_M =
    -- Radar (Derby). Fallback WPN_SELECTED_WEAPON_TYPE se master mode
    -- indefinido mas alguma arma A/A esta selecionada.
    local _in_aa_or_ag = get_avionics_master_mode_ag() or get_avionics_master_mode_aa()
    local _wpn_any_ready = (WPN_READY:get() == 1) or (WPN_SIM_READY:get() == 1)
    if _in_aa_or_ag and _wpn_any_ready then
        local _mm = master_mode
        if     _mm == AVIONICS_MASTER_MODE_ID.DGFT_S or _mm == AVIONICS_MASTER_MODE_ID.INT_S then
            HUD_RDY:set(2)   -- RDY-S (IR: Python 5 / MAA-1B)
        elseif _mm == AVIONICS_MASTER_MODE_ID.DGFT_M or _mm == AVIONICS_MASTER_MODE_ID.INT_M then
            HUD_RDY:set(3)   -- RDY-M (Radar: Derby)
        else
            -- fallback pelo weapon type (A/G, GUN, etc)
            local _wtype = WPN_SELECTED_WEAPON_TYPE:get()
            if     _wtype == WPN_WEAPON_TYPE_IDS.AA_IR_MISSILE then HUD_RDY:set(2)
            elseif _wtype == WPN_WEAPON_TYPE_IDS.AA_MISSILE    then HUD_RDY:set(3)
            else                                                    HUD_RDY:set(1)
            end
        end
    else
        HUD_RDY:set(0)
    end
    update_td()
    update_tip()
    update_oap()

    hud_warning:set((get_hud_warning() == 1 and blinking(0.2, 0.5)) and 1 or 0)

    -- ★ 2026-07-06 Annunciators (STALL / BRK-X / BINGO / SHOOT). Blink speeds
    -- match Elbit convention: fast for immediate danger, slow for advisory,
    -- solid for SHOOT (already gated by rdr.lua to NEZ + weapon ready).
    -- [F-5EM 2026-07-08 Elbit cadence] Blink cadences alinhadas com o padrao
    -- Elbit F-5EM real (vs F-16 padrao anterior):
    --   STALL: 2 Hz (0.5s) -- rapido, ameaca imediata
    --   OVERG: 4 Hz (0.25s) -- muito rapido, structural danger
    --   BINGO: 1 Hz (1.0s) -- lento, advisory de combustivel
    --   SHOOT: 4 Hz (0.25s) -- Elbit real pisca em cadence rapida,
    --                          NAO solido (era erro na versao anterior).
    --   IN RNG: 1 Hz (1.0s) -- lento, informativo de range.
    _HUD_WARN.OUT_STALL:set((_HUD_WARN.IN_STALL:get()   > 0.5 and blinking(0.5, 0.5))  and 1 or 0)
    _HUD_WARN.OUT_OVERG:set((_HUD_WARN.IN_OVERG:get()   > 0.5 and blinking(0.25, 0.5)) and 1 or 0)
    -- OVSPD: 2 Hz, same class of limit exceedance as STALL. The flag itself was
    -- already computed by Systems/limit_check.lua and shown on the PFL page;
    -- only the HUD annunciator was missing.
    _HUD_WARN.OUT_OVERSPEED:set((_HUD_WARN.IN_OVERSPEED:get() > 0.5 and blinking(0.5, 0.5)) and 1 or 0)
    _HUD_WARN.OUT_BINGO:set((_HUD_WARN.IN_BINGO:get()   > 0.5 and blinking(1.0, 0.5))  and 1 or 0)
    -- [F-5EM SHOOT gate 2026-07-09] Usuario reportou que SHOOT piscava sem
    -- lock real no inimigo. RADAR_SHOOT_CUE (publicado por rdr.lua) ativa
    -- em contexto de L&S/Derby ready, o que inclui alvo apenas TRACKED
    -- (TWS) sem STT hard-lock -- e isso e errado para F-5EM Elbit real:
    -- SHOOT so pisca com lock efetivo. Gate adicionado aqui exigindo
    -- STT range > 0 (hard lock via CMFD ACM, DGFT stick ou auto-lock
    -- classico). Se no futuro o Derby BVR precisar SHOOT em L&S puro,
    -- ampliar aqui para incluir RADAR_LS_ACTIVE + designated target.
    -- [F-5EM v0.61.2 hotfix 2026-07-10] Revertida a ampliacao v0.61.1
    -- (que aceitava L&S + SHOOT_CUE como caminho valido). Teste in-game
    -- mostrou SHOOT disparando com qualquer TWS track em NEZ, sem
    -- intent-to-shoot real. Volta ao gate STT-only. O rdr.lua SHOOT_CUE
    -- tambem foi tightened p/ exigir STT hard-lock, entao esta condicao
    -- aqui e efetivamente equivalente ao gate publisher-side. Duplo
    -- filtro (rdr + hud) e defensivo -- garante consistencia mesmo se
    -- rdr for revertido no futuro.
    local _shoot_has_lock = get_avionics_master_mode_aa() and RADAR.STT_RANGE:get() > 0 and RADAR.STT_VALID:get() == 1
    local _shoot_ir_selected = WPN_SELECTED_WEAPON_TYPE:get() == WPN_WEAPON_TYPE_IDS.AA_IR_MISSILE
        and (master_mode == AVIONICS_MASTER_MODE_ID.INT_S or master_mode == AVIONICS_MASTER_MODE_ID.DGFT_S)
    local _shoot_ready = _shoot_ir_selected and _HUD_WARN.IN_IR_STATE:get() == 5
        or (not _shoot_ir_selected and _HUD_WARN.IN_SHOOT_CUE:get() > 0.5 and _shoot_has_lock)
    local _in_rng = _shoot_ir_selected and _HUD_WARN.IN_IR_RANGE:get() == 1
        or (not _shoot_ir_selected and _HUD_WARN.IN_RNG_CUE:get() > 0.5)
    _HUD_WARN.OUT_SHOOT:set((_shoot_ready and blinking(0.25, 0.5)) and 1 or 0)
    _HUD_WARN.OUT_IN_RNG:set((_in_rng and blinking(1.0, 0.5)) and 1 or 0)

    -- [F-5EM Elbit 2026-07-09] Circulo ASE: sempre visivel em A/A modes,
    -- pisca 1Hz quando lock ativo (fotos reais 1o/14 GAV -- video FAB).
    -- Valor final ja inclui HUD_BRIGHT p/ dimmer do dia/noite integrar.
    -- HUD.STT_SHOW: 0 sem lock, 1 lockado, 2 lock offset (limite HUD).
    local _ase_in_aa = get_avionics_master_mode_aa()
    local _ir_master = master_mode == AVIONICS_MASTER_MODE_ID.INT_S
        or master_mode == AVIONICS_MASTER_MODE_ID.DGFT_S
    local _ir_lock_valid = _ir_master
        and WPN_SELECTED_WEAPON_TYPE:get() == WPN_WEAPON_TYPE_IDS.AA_IR_MISSILE
        and (WPN_READY:get() == 1 or WPN_SIM_READY:get() == 1)
        and _HUD_WARN.IN_IR_LOCK:get() > 0.5
    local _ase_has_track = HUD.STT_SHOW:get() > 0.5
        or RADAR_LS_ACTIVE:get() == 1
        or _ir_lock_valid
    if _ase_in_aa and _ase_has_track then
        if HUD.STT_SHOW:get() > 0.5 then
            -- lock ativo: pisca 1Hz p/ chamar atencao (Elbit convention)
            _HUD_WARN.OUT_ASE_BLINK:set(blinking(1.0, 0.5) and hud_bright or 0)
        else
            -- L&S or IR seeker track: solid reference circle.
            _HUD_WARN.OUT_ASE_BLINK:set(hud_bright)
        end
    else
        _HUD_WARN.OUT_ASE_BLINK:set(0)
    end

    -- [F-5EM v0.61.9 2026-07-11] Losango de lock IR sobre o alvo.
    -- [F-5EM v0.61.13 2026-07-11] SOLID (removido blink) -- bate com
    -- convencao real F-16/A-29/F-5M FAB: losango de IR seeker lock
    -- e SEMPRE SOLIDO, so o texto SHOOT que pisca. Piscar o simbolo
    -- do alvo dificulta o tracking visual em dogfight.
    -- Publicado como 1/0 -- HUD indicator usa parameter_compare_with_number.
    -- Nome do handle preservado (HUD_IR_LOCK_BLINK) p/ nao quebrar refs
    -- em HUD_AA_DGFT/INT.lua, mas semantica agora e binaria (nao pisca).
    _HUD_WARN.OUT_IR_LOCK_BLINK:set(_ir_lock_valid and 1 or 0)


    local hdg = get_avionics_hdg()

    local hdg_des = CMFD_NAV_FYT_DTK_BRG:get()

    if get_avionics_master_mode_aa() then hdg_des = -1 end
    local hdg_dif = (hdg_des - hdg)
    if hdg_dif > 180 then hdg_dif = -360 + hdg_dif end
    if hdg_dif < -180 then hdg_dif = 360 + hdg_dif end 
    if hdg_dif > 15 then hdg_dif = 15 end
    if hdg_dif < -15 then hdg_dif = -15 end
    
    _HUD_PARAMS.HDG_CUE_MOVE:set(hdg_dif)
    _HUD_PARAMS.HDG_CUE_VALUE:set(round_to(hdg_des, 1))
    _HUD_PARAMS.HDG_SCALE_MOVE:set(hdg % 10)
    for i = 1,4 do
        local param = _HUD_PARAMS.HDG_SCALE_NUM[i]
        local value = round_to(hdg/10 - 1*(2.5-i), 1)%36
        if value < 0 then value = 35 end
        param:set(value * 10)
    end

    hdg = round_to(hdg,1)

    local altitude =sensor_data.getBarometricAltitude()*3.2808399

    local altitude_des = -1000

    if master_mode == AVIONICS_MASTER_MODE_ID.LANDING then altitude_des = -1000 end
    local altitude_dif = altitude_des - altitude
    if altitude_dif > 800 then altitude_dif = 800 end
    if altitude_dif < -800 then altitude_dif = -800 end
    _HUD_PARAMS.ALT_CUE_MOVE:set(altitude_dif)
    _HUD_PARAMS.ALT_CUE_VALUE:set(round_to(altitude_des/1000, 0.1))
    if master_mode == AVIONICS_MASTER_MODE_ID.LANDING then
        _HUD_PARAMS.ALT_SCALE_MOVE:set((altitude*5 - 250) % 500)
        for i = 1,4 do
            _HUD_PARAMS.ALT_SCALE_NUM[i]:set(round_to(altitude/1000 - 0.1*(3-i), 0.1))
        end
    else
        _HUD_PARAMS.ALT_SCALE_MOVE:set((altitude - 250) % 500)
        for i = 1,4 do
            _HUD_PARAMS.ALT_SCALE_NUM[i]:set(round_to(altitude/1000 - 0.5*(3-i), 0.5))
        end
    end


    local pitch = math.deg(sensor_data.getPitch())
    if pitch > 10 then pl_ghost = 1
    elseif pitch < -10 then pl_ghost = -1
    else pl_ghost = 0 end

    if master_mode == AVIONICS_MASTER_MODE_ID.DGFT_S or master_mode == AVIONICS_MASTER_MODE_ID.DGFT_M then 
        HUD_PL:set(0)
    else
        HUD_PL:set(1)
    end

    local vs = get_avionics_vv()
    if vs > 2000 then vs = 2000 end 
    if vs < -2000 then vs = -2000 end 
    _HUD_PARAMS.VS_CUE_MOVE:set(vs)


    altitude = round_to(altitude,10)
    local alt_k = math.floor(altitude/1000)
    local alt_n = altitude%1000

    -----------------------------------------------------
    local v_x, v_y, v_z = sensor_data:getSelfVelocity()

    local v = math.sqrt( v_x * v_x + v_y * v_y + v_z * v_z)

    -- Ground speed = horizontal velocity magnitude in knots (y is vertical).
    -- Own-ship speed, always valid, feeds the NAV data block GS readout.
    _HUD_PARAMS.GS:set(round_to(math.sqrt(v_x * v_x + v_z * v_z) * 1.94384, 1))

    local v_hdg = math.atan2(v_z, v_x)
    
    local v_pitch = 0

    if v ~= 0 then
        v_pitch = math.asin(v_y / v)
    end

    local p_pitch, p_roll, p_hdg
    p_pitch = sensor_data:getPitch()
    p_roll = sensor_data:getRoll()
    p_hdg = 2*math.pi - sensor_data:getHeading()
    local dif_hdg = (v_hdg - p_hdg) % (2*math.pi)
    if dif_hdg > math.pi then dif_hdg = dif_hdg - 2 * math.pi end

    local fpm_x = (dif_hdg) * math.cos(p_roll) - (-p_pitch + v_pitch) * math.sin(p_roll)
    local fpm_y = (-p_pitch + v_pitch) * math.cos(p_roll) + (dif_hdg) * math.sin(p_roll)


    if UFCP_DRIFT_CO:get() == 1 then 
        fpm_x = 0
    end

    local fpm_cross = 0        
    fpm_x, fpm_y, fpm_cross = limit_xy(fpm_x, fpm_y, hud_limit.x, hud_limit.y*1.3)

    local pl_slide = fpm_x + fpm_y * math.tan(p_roll)
    -----------------------------------------------------
    
    local ias = get_avionics_ias()
    if ias == 0 and sensor_data.getWOW_LeftMainLandingGear() > 0 then 
            fpm_x = 0
            fpm_y = 0
            pl_slide = 0
    end

    local ias_des = -1
    local nav_time = UFCP_NAV_TIME:get()
    if nav_time == UFCP_NAV_TIME_IDS.DT or nav_time == UFCP_NAV_TIME_IDS.ETA then ias_des = CMFD_NAV_FYT_DTK_STT:get() end
    if ias_des > 990 then ias_des = 990 end

    if master_mode == AVIONICS_MASTER_MODE_ID.LANDING then ias_des = -1 end

    local ias_dif = ias_des - ias
    if ias_dif > 30 then ias_dif = 30 end
    if ias_dif < -30 then ias_dif = -30 end
    _HUD_PARAMS.VEL_CUE_MOVE:set(ias_dif)
    _HUD_PARAMS.VEL_CUE_VALUE:set(round_to(ias_des/10, 1))
    
    _HUD_PARAMS.VEL_SCALE_MOVE:set((ias - 10) % 20)
    for i = 1,4 do
        _HUD_PARAMS.VEL_SCALE_NUM[i]:set(round_to(ias/10 - 2*(3-i), 2))
    end

    ri_roll = p_roll
    if ri_roll > math.rad(50) then 
        ri_roll = math.rad(50)
    elseif ri_roll < math.rad(-50) then
        ri_roll = math.rad(-50)
    end

    local normal_accel = sensor_data.getVerticalAcceleration()
    if normal_accel > max_accel then max_accel = normal_accel end
    local max_accel_val = max_accel

    if CMFDDoi:get() == 0 then hud_doi = 1 else hud_doi = 0 end

    local raw_radar_alt = get_avionics_ralt()
    if sensor_data and type(sensor_data.getRadarAltitude) == "function" then
        raw_radar_alt = sensor_data.getRadarAltitude() * 3.2808399
    end
    local ralt_state, radar_alt, _, ralt_minimum, ralt_alert =
        HUD_RALT_EVAL.evaluate(raw_radar_alt, UFCP_RALT_SWITCH_STATE:get(), HUD.RALT_MIN_INPUT:get())
    -- [F-5EM 2026-08-29] The lower-left time block used to reach the HUD only
    -- through HUD_TIME + a `%s` format. That dynamic-string path does not
    -- render in DCS 2.9.27 (same failure already fixed for the CCRP TTG), so
    -- the clock was effectively dead. It is now also published as a numeric
    -- mode + hours/minutes/seconds, which is what the indicator consumes.
    --   1 = MM:SS (CCRP, CCIP-DELAYED, TTD)   2 = CCIP countdown "T ss"
    --   3 = ahead of plan "A MM:SS"           4 = late "D MM:SS"
    --   5 = ETA HH:MM:SS                      0 = hidden
    local time_text = ""
    local time_mode, time_h, time_m, time_s = 0, 0, 0, 0
    local ttd = CMFD_NAV_FYT_DTK_TTD:get()
    local dt = CMFD_NAV_FYT_DTK_DT:get()
    local tti = HUD.TIME_TO_IMPACT:get()
    local ccrp_time = WPN.CCRP_TIME:get()
    
    if master_mode == AVIONICS_MASTER_MODE_ID.CCRP then
        -- CCRP timer takes priority when in CCRP mode
        time_text = time_text .. string.format("%02.0f:%02.0f ", math.floor(ccrp_time / 60), math.floor(ccrp_time % 60) )
        time_mode, time_m, time_s = 1, math.floor(ccrp_time / 60), math.floor(ccrp_time % 60)
    elseif (master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) and tti >= 0 then
        time_text = time_text .. string.format("T\t %2.0f", math.floor(tti))
        time_mode, time_s = 2, math.min(99, math.floor(tti))
        HUD.TIME_TO_IMPACT:set(tti - update_time_step)
    elseif (master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) and WPN.CCIP_DELAYED:get() == 1 then
        ccrp_time = WPN.CCIP_DELAYED_TIME:get()
        time_text = time_text .. string.format("%02.0f:%02.0f ", math.floor(ccrp_time / 60), math.floor(ccrp_time % 60) )
        time_mode, time_m, time_s = 1, math.floor(ccrp_time / 60), math.floor(ccrp_time % 60)
    elseif (master_mode == AVIONICS_MASTER_MODE_ID.CCIP or master_mode == AVIONICS_MASTER_MODE_ID.CCIP_R) then
    elseif nav_time == UFCP_NAV_TIME_IDS.DT then
        if dt >= 0 then time_text = "A"; time_mode = 3 else time_text = "D"; time_mode = 4 end
        dt = math.abs(dt)
        if dt >= 100*60 then dt = 100*60-1 end
        time_text = time_text .. string.format("%02.0f:%02.0f ", math.floor(dt / 60), math.floor(dt % 60) )
        time_m, time_s = math.floor(dt / 60), math.floor(dt % 60)
    elseif nav_time == UFCP_NAV_TIME_IDS.TTD then
        if ttd >= 100*60 then ttd = 100*60-1 end
        time_text = string.format("%02.0f:%02.0f", math.floor(ttd / 60), math.floor(ttd % 60) )
        time_mode, time_m, time_s = 1, math.floor(ttd / 60), math.floor(ttd % 60)
    elseif nav_time == UFCP_NAV_TIME_IDS.ETA then
        local tot = get_absolute_model_time() + ttd
        if tot > 24*3600 then tot=24*3600-1 end
        time_text = string.format("%02.0f:%02.0f:%02.0f", math.floor(tot / 3600), math.floor((tot % 3600) / 60), math.floor(tot % 60) )
        time_mode = 5
        time_h, time_m, time_s = math.floor(tot / 3600), math.floor((tot % 3600) / 60), math.floor(tot % 60)
    end
    
    local fti_dist = -1
    local fti_num = 0
    fti_dist = round_to(fti_dist, 0.1)

    -- VOR/DME readout. Sourced from the ADHSI receiver, which resolves the
    -- tuned station against the real beacon list; the distance is only
    -- published for a received DME-equipped station, so the element hides
    -- (dist = -1) instead of printing a plausible zero.
    local vor = HUD_CUES.vor_dme(HUD.IN_VOR_DIST:get(), HUD.IN_VOR_HDG:get(),
        HUD.IN_VOR_VALID:get(), HUD.IN_VOR_DME_VALID:get())
    local vor_dist = vor.distance_nm
    local vor_mag = vor.bearing_deg

    local mach = round_to(sensor_data.getMachNumber(), 0.01)
    if master_mode == AVIONICS_MASTER_MODE_ID.LANDING and not get_avionics_onground() then 
        mach = -1 
        max_accel_val = -1
    end

    local aoa = math.deg(sensor_data.getAngleOfAttack())
    if aoa < -9 then aoa = -9 end
    if aoa > 40 then aoa = 40 end
    local aoa_delta = aoa - 4.5
    
    local egi_state = UFCP_EGI.EGI_STATE:get()
    if egi_state == UFCP_EGI_STATE_IDS.OFF then HUD.EGIR:set(0)
    elseif egi_state == UFCP_EGI_STATE_IDS.ALIGNING then HUD.EGIR:set(1)
    else HUD.EGIR:set(-1)
    end

    _HUD_PARAMS.PITCH:set(p_pitch - pl_slide*math.sin(p_roll))
    _HUD_PARAMS.ROLL:set(p_roll)
    _HUD_PARAMS.HDG:set(math.deg(p_hdg))
    _HUD_PARAMS.IAS:set(ias)
    _HUD_PARAMS.ALT_FT:set(altitude)
    _HUD_PARAMS.ALT_K:set(alt_k)
    _HUD_PARAMS.ALT_N:set(alt_n)
    _HUD_PARAMS.FPM_VERT:set(fpm_y)
    _HUD_PARAMS.FPM_SLIDE:set(fpm_x)
    HUD_FPM_CROSS:set(fpm_cross)
    _HUD_PARAMS.PL_SLIDE:set(pl_slide)
    _HUD_PARAMS.PL_GHOST:set(pl_ghost) 
    _HUD_PARAMS.RI_ROLL:set(ri_roll) 

    HUD_NORMAL_ACCEL:set(normal_accel)
    HUD_MAX_ACCEL:set(max_accel_val)
    
    HUD_DOI:set(hud_doi)

    HUD_RADAR_ALT:set(radar_alt) 
    HUD.RALT_STATE:set(ralt_state)
    HUD.RALT_MIN:set(ralt_minimum)
    HUD.RALT_ALERT:set(ralt_alert)
    
    HUD_TIME:set(time_text) 
    HUD.TIME_MODE:set(time_mode)
    HUD.TIME_H:set(time_h)
    HUD.TIME_M:set(time_m)
    HUD.TIME_S:set(time_s)
    
    HUD_FTI_DIST:set(fti_dist) 
    HUD_FTI_NUM:set(fti_num) 

    HUD_VOR_DIST:set(vor_dist) 
    HUD_VOR_MAG:set(vor_mag) 

    -- [F-5EM HUD fidelity 2026-08-29] Great-circle steering cue ("tadpole").
    -- Lateral deflection = bearing to the active flight point minus the
    -- current ground track (v_hdg), saturating at 50 mil. NAV/LANDING only
    -- and hidden without a valid flight point.
    local steering = HUD_CUES.steering(CMFD_NAV_FYT_DTK_BRG:get(), math.deg(v_hdg),
        HUD.IN_FYT_VALID:get())
    local nav_master = master_mode == AVIONICS_MASTER_MODE_ID.NAV
        or master_mode == AVIONICS_MASTER_MODE_ID.LANDING
    HUD.TADPOLE_SHOW:set((nav_master and steering.show == 1) and 1 or 0)
    HUD.TADPOLE_OFFSET:set(steering.offset * 0.050)

    -- Bullseye BRA. tactical_overlay.lua publishes bearing (rad) and range (m)
    -- from the bullseye to the own-ship; hidden until a bullseye is defined.
    local bullseye = HUD_CUES.bullseye(HUD.IN_BE_BRG:get(), HUD.IN_BE_RNG:get())
    HUD.BE_SHOW:set(bullseye.valid)
    HUD.BE_BRG:set(bullseye.bearing_deg)
    HUD.BE_RNG_NM:set(bullseye.range_nm)

    -- Laser code readback, mirroring the CMFD SMS gate (a laser store must be
    -- selected). Codes outside the 1111-1788 PRF band never render.
    local laser_code = HUD.IN_WPN_LASER_CODE:get() or 0
    HUD.LASER_CODE:set(laser_code)
    HUD.LASER_CODE_SHOW:set((HUD.IN_WPN_LASER_SELECTED:get() == 1
        and laser_code >= 1111 and laser_code <= 1788) and 1 or 0)

    -- Dedicated missile-launch flag (2 Hz), driven by the same RWR launch
    -- detection the EW page uses.
    HUD.LAUNCH_WARN:set((HUD.IN_RWR_LAUNCH_VALID:get() == 1 and blinking(0.5, 0.5, 0))
        and 1 or 0)

    HUD_MACH:set(mach)
    
    HUD_AOA:set(aoa)
    HUD_AOA_DELTA:set(aoa_delta)

    HUD_ON:set(hud_on)

    HUD_BRIGHT:set(hud_bright)

    if get_avionics_master_mode_aa() then update_aa() end
    if get_avionics_master_mode_ag() then update_ag() end

    local flir_ag = get_avionics_master_mode_ag()
    local flir_ready = HUD.FLIR_IN_POD:get() > 0.5
        and HUD.FLIR_IN_STATUS:get() == 5
    HUD.FLIR_LASER_STATE:set(flir_ag and HUD.FLIR_IN_LASER_STATE:get() or 0)
    if flir_ag and flir_ready and HUD.FLIR_IN_TARGET:get() > 0.5 then
        local flir_az, flir_el, limited = limit_xy(
            HUD.FLIR_IN_AZ:get(), HUD.FLIR_IN_EL:get(),
            hud_limit.x, hud_limit.y, -hud_limit.x, -hud_limit.y * 1.3)
        HUD.FLIR_AZ:set(flir_az)
        HUD.FLIR_EL:set(flir_el)
        HUD.FLIR_SHOW:set(limited == 1 and 2 or 1)
        HUD.FLIR_RANGE_NM:set(math.max(HUD.FLIR_IN_RANGE_M:get(), 0) / 1852)
    else
        HUD.FLIR_AZ:set(0)
        HUD.FLIR_EL:set(0)
        HUD.FLIR_SHOW:set(0)
        HUD.FLIR_RANGE_NM:set(0)
    end

    -- Radar STT
    -- [F-5EM DGFT fix 2026-07-08] RADAR.MODE==3 (ACM/CMFD) e a rota "classica"
    -- para lock, mas o DGFT do stick (master mode DGFT_S/M) tambem publica STT
    -- via dispatch_action(509) sem mexer em RADAR.MODE. Sem esta extensao, a
    -- caixa TD, o circulo ASE e a barra DLZ so apareciam via CMFD ACM e nunca
    -- durante o DGFT do throttle -- o piloto travava mas nao via nada no HUD.
    -- [F-5EM auto-lock 2026-07-08] Estendido p/ INT_S/M (Derby BVR + IR
    -- stand-off) para o TD box + DLZ tambem aparecerem em auto-lock BVR.
    -- [F-5EM auto-lock 2026-07-08 v4] Em INT_M com Derby, o radar vai p/ TWS
    -- e usa L&S target (nao STT classico). RADAR.STT_RANGE fica 0. Precisamos
    -- ler os handles RADAR_LS_* (publicados pelo rdr.lua bloco DLZ) e usa-los
    -- como fallback p/ o TD box aparecer no alvo BVR.
    -- [F-5EM fix 2026-07-08 v5] SEPARAR display gates:
    --   * TD BOX: SO com STT lock REAL (RADAR.MODE==3 ou STT_RANGE>0). Bate
    --     com F-16/F-18/F-5EM real -- o quadrado so aparece com lock/designado.
    --     Antes o TD box aparecia sempre que havia L&S ativo (auto-select do
    --     contato mais proximo em TWS) -- errado, mostrava caixa sem lock.
    --   * DLZ TAPE / STEERING DOT: podem usar L&S (F-16 tambem mostra DLZ
    --     em TWS sem STT hard lock, so precisa track designado ou top).
    local _amm = get_avionics_master_mode()
    local _in_aa_master = (_amm == AVIONICS_MASTER_MODE_ID.DGFT_S
        or _amm == AVIONICS_MASTER_MODE_ID.DGFT_M
        or _amm == AVIONICS_MASTER_MODE_ID.INT_S
        or _amm == AVIONICS_MASTER_MODE_ID.INT_M)
    local _stt_range_now = RADAR.STT_RANGE:get()
    -- [F-5EM TD-box fix 2026-07-09] Alem de STT_RANGE>0, exige RADAR_STT_VALID==1
    -- (publicado por rdr.lua): o engine congela STT_RANGE no kill/perda de lock,
    -- entao STT_VALID cai a 0 quando range/az/el param de mudar (ou no unlock
    -- manual). Sem isso o TD box ficava preso e o auto-lock nao trocava de alvo.
    local _stt_locked = (_in_aa_master and _stt_range_now > 0 and RADAR.STT_VALID:get() == 1)
    local _ls_active = (_in_aa_master and RADAR_LS_ACTIVE:get() == 1)
    -- [F-5EM TD-box fix 2026-07-09] User bug: quadrado nao sumia quando
    -- alvo era abatido / target undesignate. Causa raiz: a gate anterior
    -- 'RADAR.MODE:get()==3 or _stt_locked' misturava MODO ACM do radar
    -- (submodo de scan estreito, ativado sempre que DGFT_M master mode
    -- entra) com ESTADO DE LOCK. Em DGFT_M, RADAR.MODE fica 3 mesmo sem
    -- lock, entao _td_show ficava true indefinidamente e o quadrado era
    -- desenhado com as coordenadas STT_AZIMUTH/ELEVATION antigas (engine
    -- nao zera as coords, so para de atualizar). Correcao: TD box exige
    -- STT lock efetivo (_stt_locked = STT_RANGE > 0 + master A-A). ACM
    -- submode por si so nao designa alvo -- mesma logica F-16/F-18 real.
    --
    -- [F-5EM 2026-07-22] User request: TD Box "estilo F-15" em INT_M/DGFT_M.
    -- Adiciona GATE DE RANGE: em modos radar-missile (INT_M/DGFT_M) o
    -- quadrado so aparece se o alvo estiver DENTRO do Rmax do Derby
    -- (DLZ ativa + alvo <= Rmax). Antes de estar no Rmax nada aparece,
    -- mesmo com radar tracking o contato -- bate com F-15/F-16 real onde
    -- o TD Box surge no momento em que a solucao BVR fica valida.
    -- Nos modos IR (INT_S/DGFT_S) o gate NAO se aplica: WVR e valido em
    -- qualquer range dentro do envelope IR e o piloto ve losango+box no
    -- alvo assim que o radar/seeker resolve tracking.
    local _in_aa_radar_master = (_amm == AVIONICS_MASTER_MODE_ID.DGFT_M
        or _amm == AVIONICS_MASTER_MODE_ID.INT_M)
    local _dlz_active_now = RADAR_DLZ_ACTIVE:get() == 1
    local _dlz_max_now    = RADAR_DLZ_RMAX_NORM:get()
    local _dlz_tgt_now    = RADAR_DLZ_TGT_NORM:get()
    local _tgt_in_derby_rmax = _dlz_active_now
        and _dlz_max_now > 0
        and _dlz_tgt_now > 0
        and _dlz_tgt_now <= _dlz_max_now
    -- [F-5EM 2026-07-22 RWS lock fix] Um STT HARD-LOCK sempre mostra o TD box, em
    -- QUALQUER modo do radar (RWS/TWS/VS). O gate de Rmax do Derby (_tgt_in_derby_
    -- rmax) depende da DLZ, que so e publicada em TWS -- em RWS ficava sempre 0 e
    -- escondia o quadrado de um lock VALIDO (bug reportado in-game). O envelope de
    -- tiro continua no cue SHOOT (rdr.lua), nao no TD box. Bate com F-15/F-16:
    -- travou (bug) -> ve o quadrado no alvo, independente do alcance.
    -- Rollback: _td_show = _stt_locked and ((not _in_aa_radar_master) or _tgt_in_derby_rmax).
    local _td_show = _stt_locked
    -- DLZ / steering: STT ou L&S
    local _stt_display = _td_show or _ls_active

    if _td_show then
        local src_az = RADAR.STT_AZIMUTH:get()
        local src_el = RADAR.STT_ELEVATION:get()
        local stt_az, stt_el, limited = limit_xy(src_az, src_el, hud_limit.x , hud_limit.y , -hud_limit.x , -hud_limit.y * 1.3 )

        HUD.STT_AZ:set(stt_az)
        HUD.STT_EL:set(stt_el)
        HUD.STT_SHOW:set(limited == 1 and 2 or 1)
        -- [F-5EM 2026-07-08] Range em NM do alvo lockado (label ao lado do TD)
        HUD.STT_RANGE_NM:set(RADAR.STT_RANGE:get() / 1852)
        -- [F-5EM 2026-07-08 aspect] Rotacao do triangulo de aspecto.
        -- RADAR.STT_ANGLE ja e publicado por rdr.lua como (plane_hdg - stt_hdg)
        -- que e proximo do aspecto reciproco (0 = nose-on / pi = tail).
        HUD.STT_ASPECT:set(RADAR.STT_ANGLE:get())


    else
        HUD.STT_SHOW:set(0)
        HUD.STT_RANGE_NM:set(0)
        HUD.STT_ASPECT:set(0)
    end

    -- [F-5EM v0.61.1 2026-07-10] BVR L&S marker no HUD (distinto do TD box).
    -- [F-5EM 2026-07-22 v2] Reativado com GATE DE RANGE Derby (estilo F-15).
    -- [F-5EM 2026-07-22 AUTO-ACQUIRE TWS] Pedido do usuario: o quadrado deve
    -- aparecer SOZINHO no alvo mais proximo pintado no scope em TWS, sem o
    -- piloto apontar o nariz nem esperar entrar no Rmax do Derby. Removido o
    -- gate (d) '_tgt_in_derby_rmax' do L&S box -> agora o marker aparece assim
    -- que ha track em TWS (RADAR_LS_ACTIVE=1, eleito = mais proximo do cursor;
    -- com cursor parado = o mais proximo do scope). Isso e o comportamento
    -- "auto-acquire / L&S" real do TWS: o radar continua varrendo (nao vira
    -- STT), e o quadrado HOLLOW envolve o alvo designado automaticamente.
    -- Comportamento atual:
    --   - Publica HUD_LS_* quando (a) master em modo RADAR (INT_M/DGFT_M),
    --     (b) L&S ativo (TWS+track), (c) SEM STT hard-lock (mutuo exclusivo
    --     com o TD box de STT).
    --   - O gate de Rmax passou a valer SO para os cues de tiro (DLZ/SHOOT/
    --     IN RNG) e para o STT hard-lock (F-15 style); o quadrado L&S de
    --     aquisicao aparece antes, indicando qual alvo o radar designou.
    --   - Marker segue LS_AZ/LS_EL = posicao do alvo no HUD (quadrado em
    --     volta do alvo, como F-15 mostra TDD Bug no TWS L&S).
    -- Rollback: readicionar 'and _tgt_in_derby_rmax' na condicao abaixo.
    if (not _td_show) and _ls_active and _in_aa_radar_master then
        local src_az = RADAR_LS_AZ:get()
        local src_el = RADAR_LS_EL:get()
        local ls_az, ls_el, limited = limit_xy(src_az, src_el, hud_limit.x , hud_limit.y , -hud_limit.x , -hud_limit.y * 1.3 )
        HUD.LS_AZ:set(ls_az)
        HUD.LS_EL:set(ls_el)
        HUD.LS_SHOW:set(limited == 1 and 2 or 1)
        HUD.LS_RANGE_NM:set(RADAR_LS_RANGE:get() / 1852)
    else
        HUD.LS_SHOW:set(0)
        HUD.LS_RANGE_NM:set(0)
    end

    local combat = COMBAT_DISPLAY.select({
        aa_active = _in_aa_master,
        radar_master = _in_aa_radar_master,
        radar_mode = HUD.COMBAT_IN_RADAR_MODE:get(),
        acm_submode = HUD.COMBAT_IN_ACM_SUBMODE:get(),
        stt_valid = _stt_locked,
        stt_range_m = RADAR.STT_RANGE:get(),
        stt_azimuth = RADAR.STT_AZIMUTH:get(),
        stt_elevation = RADAR.STT_ELEVATION:get(),
        stt_altitude_kft = RADAR.STT_ALT:get(),
        stt_closure_mps = RADAR.STT_REL_SPD:get(),
        stt_aspect_rad = RADAR.STT_ANGLE:get(),
        ls_active = _ls_active,
        ls_range_m = RADAR_LS_RANGE:get(),
        ls_azimuth = RADAR_LS_AZ:get(),
        ls_elevation = RADAR_LS_EL:get(),
        ls_altitude_kft = HUD.COMBAT_IN_LS_ALT:get(),
        ls_closure_kt = HUD.COMBAT_IN_LS_CLOSURE:get(),
        ir_valid = _ir_lock_valid,
        ir_azimuth = HUD_IR_MISSILE_TARGET_AZIMUTH:get(),
        ir_elevation = HUD_IR_MISSILE_TARGET_ELEVATION:get(),
        ready = WPN_READY:get(),
        sim_ready = WPN_SIM_READY:get(),
    })
    HUD.COMBAT_SOURCE:set(combat.source)
    HUD.COMBAT_SENSOR_STATE:set(combat.sensor_state)
    HUD.COMBAT_WEAPON_STATE:set(combat.weapon_state)
    HUD.COMBAT_MODE_ACTIVE:set(combat.mode_active)
    HUD.COMBAT_SHOW:set(combat.show)
    HUD.COMBAT_AZ:set(combat.azimuth)
    HUD.COMBAT_EL:set(combat.elevation)
    HUD.COMBAT_RANGE_NM:set(combat.range_nm)
    HUD.COMBAT_RANGE_VALID:set(combat.range_valid)
    HUD.COMBAT_ALT_KFT:set(combat.altitude_kft)
    HUD.COMBAT_ALT_FT:set(combat.altitude_ft)
    HUD.COMBAT_ALT_VALID:set(combat.altitude_valid)
    HUD.COMBAT_CLOSURE_KT:set(combat.closure_kt)
    HUD.COMBAT_CLOSURE_VALID:set(combat.closure_valid)
    HUD.COMBAT_TTI_SEC:set(combat.tti_sec)
    HUD.COMBAT_TTI_VALID:set(combat.tti_valid)
    HUD.COMBAT_ASPECT:set(combat.aspect_rad)
    HUD.COMBAT_ASPECT_VALID:set(combat.aspect_valid)
    HUD.COMBAT_READY_STATE:set(combat.ready_state)

    local dlz_norm_range = RADAR.NORM_RANGE:get()
    if _stt_display and RADAR_DLZ_ACTIVE:get() == 1 and dlz_norm_range > 0 then
        local dlz_min = math.max(0, math.min(1, RADAR_DLZ_RMIN_NORM:get()))
        local dlz_best = math.max(0, math.min(1, RADAR_DLZ_RNE_NORM:get()))
        local dlz_max = math.max(0, math.min(1, RADAR_DLZ_RMAX_NORM:get()))
        local dlz_now = math.max(0, math.min(1, RADAR_DLZ_TGT_NORM:get()))
        HUD.DLZ_MIN:set(dlz_min)
        HUD.DLZ_MAX:set(dlz_max)
        HUD.DLZ_BEST:set(dlz_best)
        HUD.DLZ_NOW:set(dlz_now)
        HUD.DLZ_MIN_NM:set(dlz_min * dlz_norm_range / 1852)
        HUD.DLZ_MAX_NM:set(dlz_max * dlz_norm_range / 1852)
        HUD.DLZ_BEST_NM:set(dlz_best * dlz_norm_range / 1852)
    else
        HUD.DLZ_MIN:set(0.1)
        HUD.DLZ_MAX:set(-1)
        HUD.DLZ_BEST:set(0.4)
        HUD.DLZ_NOW:set(0.75)
        HUD.DLZ_MIN_NM:set(0)
        HUD.DLZ_MAX_NM:set(0)
        HUD.DLZ_BEST_NM:set(0)
    end

    -- [F-5EM 2026-07-22 diag] Log 1x/s do estado do TD/L&S box quando em A/A.
    -- Objetivo: descobrir por que o quadrado nao envolve o alvo. Mostra os
    -- valores que decidem posicao/visibilidade do box. Remover apos root-cause.
    if _in_aa_master and log and log.info then
        local _now = 0
        pcall(function() _now = get_absolute_model_time() end)
        if (_now - _f5em_tdbox_diag_t) >= 1.0 then
            _f5em_tdbox_diag_t = _now
            local msg = string.format(
                "F5EM_TDBOX amm=%d ls_act=%d ls_az=%.3f ls_el=%.3f ls_show=%.0f "
                .."stt_lock=%s stt_az=%.3f stt_el=%.3f stt_show=%.0f td_show=%s "
                .."dlz_act=%d dlz_tgt=%.3f dlz_max=%.3f in_rmax=%s "
                .."combat_show=%.0f combat_az=%.3f combat_el=%.3f",
                _amm or -1,
                (RADAR_LS_ACTIVE:get() == 1) and 1 or 0,
                RADAR_LS_AZ:get() or 0, RADAR_LS_EL:get() or 0, HUD.LS_SHOW:get() or 0,
                tostring(_stt_locked), RADAR.STT_AZIMUTH:get() or 0, RADAR.STT_ELEVATION:get() or 0,
                HUD.STT_SHOW:get() or 0, tostring(_td_show),
                (RADAR_DLZ_ACTIVE:get() == 1) and 1 or 0,
                RADAR_DLZ_TGT_NORM:get() or 0, RADAR_DLZ_RMAX_NORM:get() or 0,
                tostring(_tgt_in_derby_rmax),
                HUD.COMBAT_SHOW:get() or 0, HUD.COMBAT_AZ:get() or 0, HUD.COMBAT_EL:get() or 0)
            if msg ~= _f5em_tdbox_diag_last then
                _f5em_tdbox_diag_last = msg
                log.info(msg)
            end
        end
    end

end

function post_initialize()
    startup_print("hud: postinit start")
    local birth = LockOn_Options.init_conditions.birth_place

    if birth=="GROUND_HOT" then
    elseif birth=="AIR_HOT" then
    elseif birth=="GROUND_COLD" then
    end
    dev:performClickableAction(device_commands.UFCP_HUD_BRIGHT,0,true)
    startup_print("hud: postinit end")
end

local iCommandHUDBrightnessUp = 746
local iCommandHUDBrightnessDown = 747
dev:listen_command(iCommandHUDBrightnessUp)
dev:listen_command(iCommandHUDBrightnessDown)

function SetCommand(command,value)
    debug_message_to_user("environ: command "..tostring(command).." = "..tostring(value))
    if command==device_commands.UFCP_WARNRST then
        if get_hud_warning() == 0 and value == 1 then 
            max_accel = 0
        end        
    elseif command == iCommandHUDBrightnessUp then
        value = get_cockpit_draw_argument_value(1483) - 0.05
        if value > 1 then value = 1 end
        dev:performClickableAction(device_commands.UFCP_HUD_BRIGHT, value, true)
    elseif command == iCommandHUDBrightnessDown then
        value = get_cockpit_draw_argument_value(1483) + 0.05
        if value < 0 then value = 0 end
        dev:performClickableAction(device_commands.UFCP_HUD_BRIGHT, value, true)
    end
end


startup_print("environ: load end")
need_to_be_closed = false -- close lua state after initialization


