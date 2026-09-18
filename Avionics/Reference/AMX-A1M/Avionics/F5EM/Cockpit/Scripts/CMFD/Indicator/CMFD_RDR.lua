dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.RDR}}

local object

-- RDR OFF
object = addStrokeText(nil, "RDR OFF", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", GetMainCenter(), nil, nil, {"%05.0f"}, CMFD_FONT_R)
object.element_params = {default_element_params, "RDR_POWER"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

-- RDR BIT
object = addStrokeText(nil, "RDR BIT", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", GetMainCenter(), nil, nil, {"%05.0f"}, CMFD_FONT_Y)
object.element_params = {default_element_params, "RADAR_MODE"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 4}}

-- [Radar C++ diag] "DLL n" (canto sup. dir.): prova in-game que a avF5EMRadar.dll
-- carregou e quantos tracks ela computou dos contatos do motor. Gateado por
-- F5EM_RDR_DLL_ALIVE (so aparece se a DLL estiver viva e o debug for ativado).
-- F5EM_RDR_DEBUG nasce em 0, portanto o indicador de desenvolvimento fica
-- oculto no cockpit normal sem remover a telemetria da DLL.
local DLL_diag = addPlaceholder(nil, {0.6, 0.66})
DLL_diag.element_params = {"F5EM_RDR_DLL_ALIVE", "F5EM_RDR_DEBUG"}
DLL_diag.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, 0.95, 1.05},
}
object = addStrokeText(nil, "DLL", CMFD_STRINGDEFS_DEF_X06, "RightCenter", {0, 0}, DLL_diag.name, nil, {"DLL %01.0f"}, CMFD_FONT_Y)
object.element_params = {"F5EM_RDR_DLL_TRACKS"}
object.controllers = {{"text_using_parameter", 0, 0}}

-- [Radar Export bridge — Fatia 1] "EXP n" (logo abaixo do "DLL n"): prova in-game
-- que o F5EM_Radar_Export_bridge.lua (Scripts/Export.lua, SP-only) carregou e
-- quantos alvos aereos reais ele enxerga em alcance. Gateado por RDR_EXP_ALIVE.
-- Ciano p/ diferenciar do diag da DLL. Tambem exige F5EM_RDR_DEBUG=1.
local EXP_diag = addPlaceholder(nil, {0.6, 0.62})
EXP_diag.element_params = {"RDR_EXP_ALIVE", "F5EM_RDR_DEBUG"}
EXP_diag.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, 0.95, 1.05},
}
object = addStrokeText(nil, "EXP", CMFD_STRINGDEFS_DEF_X06, "RightCenter", {0, 0}, EXP_diag.name, nil, {"EXP %01.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RDR_EXP_COUNT"}
object.controllers = {{"text_using_parameter", 0, 0}}

local Track_counts = addPlaceholder(nil, {-0.58, 0.62})
Track_counts.element_params = {"RDR_POWER", "RDR_OPR", "RDR_MODE"}
Track_counts.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, 0.95, 1.05},
    {"parameter_in_range", 2, -0.05, 1.05},
}
object = addStrokeText(nil, "N", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
    {0, 0}, Track_counts.name, nil, {"N %02.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RDR_NATIVE_TRACK_COUNT"}
object.controllers = {{"text_using_parameter", 0, 0}}
object = addStrokeText(nil, "A", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
    {0, -0.035}, Track_counts.name, nil, {"A %02.0f"}, CMFD_FONT_Y)
object.element_params = {"RDR_AUX_TRACK_COUNT"}
object.controllers = {{"text_using_parameter", 0, 0}}


-- RDR ON
local RDR_On = addPlaceholder(nil, nil)
RDR_On.element_params = {"RDR_POWER", "RADAR_MODE"}
RDR_On.controllers = {{"parameter_compare_with_number", 0, 1}, {"parameter_compare_with_number", 1, 4, -1}}
default_parent = RDR_On.name

object = addOSSMultipleOptions(2, {"RWS", "TWS", "VS", "ACM"}, "RDR_MODE")
object = addOSSMultipleOptions(5, {"STBY", "OPR"}, "RDR_OPR")
object = addOSSStrokeBox(5,1,nil,nil,nil,nil,4)
object.element_params = {default_element_params, "RDR_OPR"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number", 1, 0}}

object = addOSSText(6, "CNTL")

-- [Fase 1] OSS9 alterna A/A vs A/G master mode do radar (sim Grifo)
object = addOSSMultipleOptions(9, {"A/A", "A/G"}, "RDR_AA_AG")

local AgModeGroup = addPlaceholder(nil, nil)
AgModeGroup.element_params = {"RDR_AA_AG"}
AgModeGroup.controllers = {{"parameter_compare_with_number", 0, 1}}
local _ag_mode_parent = default_parent
default_parent = AgModeGroup.name
object = addOSSMultipleOptions(8, {"GMT", "SEA", "MAP"}, "RDR_AG_SUB")
default_parent = _ag_mode_parent

-- [Fase 1] OSS3 mostra/cicla ACM submode (BORE/VACQ/AACQ). So aparece se RDR_MODE==3.
local AcmGroup = addPlaceholder(nil, nil)
AcmGroup.element_params = {"RDR_MODE"}
AcmGroup.controllers = {{"parameter_compare_with_number", 0, 3}}
local _saved_parent = default_parent
default_parent = AcmGroup.name
object = addOSSMultipleOptions(3, {"BORE", "VACQ", "AACQ"}, "RDR_ACM_SUB")
default_parent = _saved_parent

local AaSearchGroup = addPlaceholder(nil, nil)
AaSearchGroup.element_params = {"RDR_AA_AG", "RDR_MODE"}
AaSearchGroup.controllers = {
    {"parameter_in_range", 0, -0.05, 0.05},
    {"parameter_in_range", 1, -0.05, 1.05},
}
_saved_parent = default_parent
default_parent = AaSearchGroup.name
object = addOSSText(7, "AZ\n\n60", nil, nil, nil, {"AZ\n\n%02.0f"})
object.element_params = {default_element_params, "RDR_SCAN_AZ_DEG"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
object = addOSSText(8, "BAR\n\n4", nil, nil, nil, {"BAR\n\n%1.0f"})
object.element_params = {default_element_params, "RDR_SCAN_BARS"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}
default_parent = _saved_parent

local RDR_Base = addPlaceholder()
RDR_Base.element_params = {"RDR_CNTL"}
RDR_Base.controllers = {{"parameter_compare_with_number", 0, 0}}

default_parent = RDR_Base.name

local external_control = addPlaceholder(nil, nil, RDR_Base.name)
external_control.element_params = {"RDR_CNTL", "RDR_AA_AG"}
external_control.controllers = {
    {"parameter_in_range", 0, -0.05, 0.05},
    {"parameter_in_range", 1, -0.05, 0.05},
}
for state, label in ipairs({"EXT\nOFF", "EXT\nON"}) do
    object = addOSSText(10, label, external_control.name)
    object.element_params = {default_element_params, "RDR_EXT_ENABLED", "RDR_CNTL", "RDR_AA_AG"}
    object.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, state - 1.05, state - 0.95},
        {"parameter_in_range", 2, -0.05, 0.05},
        {"parameter_in_range", 3, -0.05, 0.05},
    }
end

-- Range
object = addOSSMidText(27.5," 60",nil, nil, nil, {"%3.0f"})
object.element_params = {default_element_params, "RDR_RANGE"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

-- CNTL Page
local RDR_Cntl = addPlaceholder(nil, {0,0}, RDR_On.name)
RDR_Cntl.element_params = {"RDR_CNTL"}
RDR_Cntl.controllers = {{"parameter_compare_with_number", 0, 1}}
default_parent = RDR_Cntl.name

object = addOSSStrokeBox(6, 1, nil, nil, nil, nil, 4)

object = addOSSText(4, "TGT\nHIS")
object = addOSSText(4, "\n\n0", nil, nil, nil, {"\n\n%1.0f"})
object.element_params = {default_element_params, "RDR_HIS"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addOSSMultipleOptions(28, {"MTR\nAA\nLO", "MTR\nAA\nHI"}, "RDR_MTR_AA")
object = addOSSMultipleOptions(27, {"MTR\nAG\nLO", "MTR\nAG\nHI"}, "RDR_MTR_AG")
object = addOSSMultipleOptions(26, {"ALT\nTRK\nOFF", "ALT\nTRK\nON"}, "RDR_ALT_TRK")
object = addOSSText(24, "LVL 1\n1,3,4\nA")
object = addOSSArrow(10,1)
object = addOSSMidText(10.5, "SYM\nINT")
object = addOSSArrow(11,0)
object = addOSSText(9, "CHN\n23")
object = addOSSText(8, "BCN\nDLY\n21.1")
object = addOSSText(7, "BCN\nCOD\n11")

------------------------------------------
local Grid_base = addPlaceholder(nil, {0, GetMainCenter()[2]-0.025}, RDR_On.name)
default_parent = Grid_base.name
save_default_material = default_material
default_material = CMFD_MATERIAL_CYAN

local grid_w = 1.7
local grid_h = 1.45

-- Left Scale
local function addLeftScale(pos, size, small_tick_size, large_tick_size, carret_size)
    local LeftScale_base = addPlaceholder(nil, pos)
    local object
    object = addStrokeLine(nil, large_tick_size, {0,0}, 90, LeftScale_base.name)
    for i=1, 3 do
        object = addStrokeLine(nil, small_tick_size, {0,size / 4 / 3 * i}, 90, LeftScale_base.name)
        object = addStrokeLine(nil, small_tick_size, {0,-size / 4 / 3 * i}, 90, LeftScale_base.name)
    end
    object = addPlaceholder(nil, nil, LeftScale_base.name)
    object.element_params = {"SCAN_ZONE_ORIGIN_ELEVATION_NORM"}
    object.controllers = {{"move_up_down_using_parameter", 0, size/4 * GetScale()}}
    object = addStrokeLine(nil, large_tick_size/2, {0,0}, 90, object.name)
    object = addStrokeLine(nil, large_tick_size/2, {0,-large_tick_size/4}, 0, object.parent_element)
    return LeftScale_base
end
object = addLeftScale({-0.8, 0}, grid_h, 0.02, 0.06)

-- Top Bottom Scale
local function addBottomScale(pos, size, small_tick_size, large_tick_size, carret_size)
    local Scale_base = addPlaceholder(nil, pos)
    local object
    object = addStrokeLine(nil, large_tick_size, {0, -grid_h/2}, 0, Scale_base.name)
    object = addStrokeLine(nil, large_tick_size, {0, grid_h/2}, 180, Scale_base.name)
    for i=1, 2 do
        object = addStrokeLine(nil, small_tick_size, {size / 4 / 2 * i, -grid_h/2}, 0, Scale_base.name)
        object = addStrokeLine(nil, small_tick_size, {-size / 4 / 2 * i, -grid_h/2}, 0, Scale_base.name)

        object = addStrokeLine(nil, small_tick_size, {size / 4 / 2 * i, grid_h/2}, 180, Scale_base.name)
        object = addStrokeLine(nil, small_tick_size, {-size / 4 / 2 * i, grid_h/2}, 180, Scale_base.name)
    end
    object = addPlaceholder(nil, {0, -grid_h/2 + large_tick_size/4}, Scale_base.name)
    object.element_params = {"SCAN_ZONE_ORIGIN_AZIMUTH_NORM"}
    object.controllers = {{"move_left_right_using_parameter", 0, size/4 * GetScale()}}
    object = addStrokeLine(nil, large_tick_size/2, {0,0}, 0, object.name)
    object = addStrokeLine(nil, large_tick_size/2, {-large_tick_size/4, large_tick_size/2}, -90, object.parent_element)
    return Scale_base
end
object = addBottomScale({0, 0 }, grid_w, 0.02, 0.06)

local Scan_limits = addPlaceholder(nil, {0, 0})
Scan_limits.element_params = {"RDR_MODE", "RDR_AA_AG", "RDR_OPR"}
Scan_limits.controllers = {
    {"parameter_in_range", 0, -0.05, 1.05},
    {"parameter_in_range", 1, -0.05, 0.05},
    {"parameter_in_range", 2, 0.95, 1.05},
}
local function addScanBoundary(param)
    local boundary = addPlaceholder(nil, {0, -grid_h/2}, Scan_limits.name)
    boundary.element_params = {param}
    boundary.controllers = {{"move_left_right_using_parameter", 0, grid_w * GetScale()}}
    addStrokeLine(nil, grid_h, {0, 0}, 0, boundary.name,
        nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
end
addScanBoundary("RDR_SCAN_LEFT_NORM")
addScanBoundary("RDR_SCAN_RIGHT_NORM")

object = addStrokeText(nil, "B1/4", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
    {-grid_w/2 + 0.02, grid_h/2 - 0.10}, Scan_limits.name,
    nil, {"B%1.0f/", "%1.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RDR_SCAN_CURRENT_BAR", "RDR_SCAN_BARS"}
object.controllers = {
    {"text_using_parameter", 0, 0},
    {"text_using_parameter", 1, 1},
}

-- [Grifo B-scope 2026-08-30] Aneis de alcance. A escala esquerda so trazia ticks
-- de elevacao, entao o alcance de um contato era puramente implicito pela altura
-- no scope. Agora ha marcas a 1/4, 1/2 e 3/4 com o valor em NM, derivado do
-- alcance selecionado por RDR_RANGE (o indicador nao multiplica parametros, por
-- isso CMFD/Device/rdr.lua publica as fracoes prontas). Somente RWS/TWS: no VS o
-- eixo vertical e closure, nao alcance.
local RangeRings = addPlaceholder(nil, {0, 0})
RangeRings.element_params = {"RDR_MODE"}
RangeRings.controllers = {{"parameter_in_range", 0, -0.05, 1.05}}
local function addRangeRing(fraction, range_param)
    local y = -grid_h/2 + grid_h * fraction
    addStrokeLine(nil, 0.05, {-grid_w/2, y}, 90, RangeRings.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    addStrokeLine(nil, 0.05, {grid_w/2 - 0.05, y}, 90, RangeRings.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    local label = addStrokeText(nil, "20", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {-grid_w/2 + 0.06, y}, RangeRings.name, nil, {"%2.0f"}, CMFD_FONT_CYAN)
    label.element_params = {"RDR_MODE", range_param}
    label.controllers = {
        {"parameter_in_range", 0, -0.05, 1.05},
        {"text_using_parameter", 1, 0},
    }
end
addRangeRing(0.25, "RDR_RANGE_Q1")
addRangeRing(0.50, "RDR_RANGE_Q2")
addRangeRing(0.75, "RDR_RANGE_Q3")

default_material = CMFD_MATERIAL_BLUE

-- Horizon
local function addHorizon(pos, size, tick_size, gap_size)
    local Horizon_base = addPlaceholder(nil, pos)
    Horizon_base.element_params = {"RDR_HORIZ_PITCH", "RDR_HORIZ_ROLL"}
    Horizon_base.controllers = {{"move_up_down_using_parameter", 0, -grid_h / math.rad(45) * GetScale() / 2 }, {"rotate_using_parameter", 1, 1}}

    local object 
    object = addStrokeLine(nil, (size-gap_size)/2, {-gap_size/2,0}, 90, Horizon_base.name)
    object = addStrokeLine(nil, (size-gap_size)/2, {gap_size/2,0}, -90, Horizon_base.name)
    object = addStrokeLine(nil, tick_size, {-size/2,0}, 180, Horizon_base.name)
    object = addStrokeLine(nil, tick_size, {size/2,0}, 180, Horizon_base.name)
    return Horizon_base
end
object = addHorizon({0,0}, 1, 0.03, 0.2)


-- Flight Level
object = addStrokeText(nil, "20", CMFD_STRINGDEFS_DEF_X08, "CenterBottom", {0.35, -0.75 + 0.06}, nil, nil, {"%02.0f"})
object.element_params = {default_element_params, "HUD_ALT_K"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

-- Heading
object = addStrokeText(nil, " 130`", CMFD_STRINGDEFS_DEF_X08, "CenterBottom", {0, -0.75 + 0.06}, nil, nil, {"% 03.0f`"})
object.element_params = {default_element_params, "HUD_HDG"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "300", CMFD_STRINGDEFS_DEF_X08, "CenterBottom", {-0.35, -0.75 + 0.06}, nil, nil, {"%03.0f"})
object.element_params = {default_element_params, "HUD_IAS"}
object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}}

default_material = save_default_material


-------------------------------
-- [RWS clean 2026-07-22] Apresentacao digital Grifo/F-15-like.
-- O renderer antigo desenhava 140 RADAR_CONTACT_NN_* brancos em TODOS os
-- modos, sobrepondo raw video, coast e tracks TWS. Agora RWS/VS consomem
-- apenas os 20 contatos consolidados por radar_search.lua:
--   SOURCE=0 nativo/lockavel -> brick ciano solido
--   SOURCE=1 Export bridge -> caixa amarela E, awareness-only
-- TWS tem renderer proprio abaixo; ACM mostra apenas a janela de aquisicao.
local lr_scale = grid_w * GetScale() --/ math.rad(120) 
local ud_scale = grid_h * GetScale() --/ 20 / 1852
local vs_scale = (grid_h / 2) * GetScale()

local function gateSearchElement(element, mode, active_param, source_param, source, text_param)
    local params = {
        default_element_params,
        "RDR_MODE",
        active_param,
        source_param,
        "RADAR_STT_VALID",
    }
    local controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, mode - 0.05, mode + 0.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, source - 0.05, source + 0.05},
        {"parameter_in_range", 4, -0.05, 0.05},
    }
    if text_param then
        params[#params + 1] = text_param
        controllers[#controllers + 1] = {"text_using_parameter", #params - 1, 0}
    end
    element.element_params = params
    element.controllers = controllers
end

local function gateSearchIff(element, a)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_SEARCH_"..a.."_ACTIVE",
        "RADAR_SEARCH_"..a.."_SOURCE",
        "RADAR_SEARCH_"..a.."_IFF_SOURCE",
        "RADAR_SEARCH_"..a.."_IFF_RESULT",
        "RADAR_STT_VALID",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, -0.05, 0.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, 0.95, 1.05},
        {"parameter_in_range", 5, 0.95, 1.05},
        {"parameter_in_range", 6, -0.05, 0.05},
    }
end

-- Coalition affiliation from Export/datalink is not an IFF interrogation.
-- It changes only the remote symbol shape; the native IFF bar/I stays separate.
local function gateSearchAffiliation(element, mode, a, friend)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_SEARCH_"..a.."_ACTIVE",
        "RADAR_SEARCH_"..a.."_SOURCE",
        "RADAR_SEARCH_"..a.."_FRIEND",
        "RADAR_STT_VALID",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, mode - 0.05, mode + 0.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, 0.95, 1.05},
        {"parameter_in_range", 4, friend - 0.05, friend + 0.05},
        {"parameter_in_range", 5, -0.05, 0.05},
    }
end

for i=1,20 do
    local a = string.format("%02.0f", i)

    -- RWS: posicao azimute x alcance.
    local RWS_base = addPlaceholder(nil, {0, -grid_h/2})
    RWS_base.element_params = {
        "RADAR_SEARCH_"..a.."_AZIMUTH_NORM",
        "RADAR_SEARCH_"..a.."_RANGE_NORM",
    }
    RWS_base.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
    }
    object = addFillBox(nil, 0.032, 0.008, "CenterCenter", {0,0}, RWS_base.name, nil, CMFD_MATERIAL_CYAN)
    gateSearchElement(object, 0, "RADAR_SEARCH_"..a.."_ACTIVE", "RADAR_SEARCH_"..a.."_SOURCE", 0)
    object = addStrokeBox(nil, 0.032, 0.020, "CenterCenter", {0,0},
        RWS_base.name, nil, CMFD_MATERIAL_YELLOW)
    gateSearchAffiliation(object, 0, a, -1)
    object = addStrokeBox(nil, 0.026, 0.026, "CenterCenter", {0,0},
        RWS_base.name, nil, CMFD_MATERIAL_RED)
    object.init_rot = {45}
    gateSearchAffiliation(object, 0, a, 0)
    object = addStrokeCircle(nil, 0.016, {0,0}, RWS_base.name,
        nil, nil, 0.5, 0.5, false, CMFD_MATERIAL_CYAN)
    gateSearchAffiliation(object, 0, a, 1)
    object = addStrokeText(nil, "EX", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
        {0.020, 0.012}, RWS_base.name, nil, nil, CMFD_FONT_Y)
    gateSearchElement(object, 0, "RADAR_SEARCH_"..a.."_ACTIVE", "RADAR_SEARCH_"..a.."_SOURCE", 1)
    object = addStrokeLine(nil, 0.040, {0, 0.015}, 90,
        RWS_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateSearchIff(object, a)
    object = addStrokeText(nil, "I", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
        {0.024, 0.015}, RWS_base.name, nil, nil, CMFD_FONT_CYAN)
    gateSearchIff(object, a)

    -- VS: azimute x closure normalizada (-1 opening, +1 closing).
    local VS_contact = addPlaceholder(nil, {0, 0})
    VS_contact.element_params = {
        "RADAR_SEARCH_"..a.."_AZIMUTH_NORM",
        "RADAR_SEARCH_"..a.."_VS_NORM",
    }
    VS_contact.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, vs_scale},
    }
    object = addFillBox(nil, 0.032, 0.008, "CenterCenter", {0,0}, VS_contact.name, nil, CMFD_MATERIAL_CYAN)
    gateSearchElement(object, 2, "RADAR_SEARCH_"..a.."_ACTIVE", "RADAR_SEARCH_"..a.."_SOURCE", 0)
    -- Closure numerica ao lado do contato: no VS o eixo vertical ja e range-rate,
    -- mas sem o numero o piloto so tinha a posicao relativa.
    object = addStrokeText(nil, "   0", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {0.026, 0}, VS_contact.name, nil, {"%+04.0f"}, CMFD_FONT_CYAN)
    gateSearchElement(object, 2, "RADAR_SEARCH_"..a.."_ACTIVE", "RADAR_SEARCH_"..a.."_SOURCE", 0,
        "RADAR_SEARCH_"..a.."_CLOSURE_KT")
end

-- RWS/SAM designation overlays are independent from raw search bricks. This
-- preserves RWS presentation while keeping the selected L&S and DT2 visible.
local function addRwsDesignation(active_param, az_param, range_param, label, is_primary)
    local base = addPlaceholder(nil, {0, -grid_h/2})
    base.element_params = {az_param, range_param, active_param, "RDR_MODE", "RADAR_STT_VALID"}
    base.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, -0.05, 0.05},
    }
    local size = is_primary and 0.085 or 0.070
    addStrokeBox(nil, size, size, "CenterCenter", {0,0},
        base.name, nil, is_primary and CMFD_MATERIAL_CYAN or CMFD_MATERIAL_YELLOW)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {size * 0.60, size * 0.42}, base.name, nil, nil,
        is_primary and CMFD_FONT_CYAN or CMFD_FONT_Y)
end

addRwsDesignation("RADAR_SOFT_LS_ACTIVE", "RADAR_SOFT_LS_AZ_NORM",
    "RADAR_SOFT_LS_RANGE_NORM", "1", true)
addRwsDesignation("RADAR_SOFT_DT2_ACTIVE", "RADAR_SOFT_DT2_AZ_NORM",
    "RADAR_SOFT_DT2_RANGE_NORM", "2", false)

-- E-99 Link-BR2 overlay: separate awareness symbols, never radar returns.
-- Visible in RWS/TWS only; rdr.lua removes contacts already seen natively.
for i=1,8 do
    local a = string.format("%02d", i)
    local dl = addPlaceholder(nil, {0, -grid_h/2})
    dl.element_params = {
        "RADAR_DL_"..a.."_AZ_NORM", "RADAR_DL_"..a.."_RNG_NORM",
        "RADAR_DL_"..a.."_ACTIVE", "RDR_MODE", "RADAR_STT_VALID", "DL_MODE",
        "RDR_EXT_ENABLED",
    }
    dl.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 1.05},
        {"parameter_in_range", 4, -0.05, 0.05},
        -- Defense in depth: stale RADAR_DL_* handles cannot remain visible
        -- after the pilot selects DL OFF.
        {"parameter_in_range", 5, 1.95, 2.05},
        {"parameter_in_range", 6, 0.95, 1.05},
    }

    local unknown = addPlaceholder(nil, {0,0}, dl.name)
    unknown.element_params = {"RADAR_DL_"..a.."_SIDE"}
    unknown.controllers = {{"parameter_in_range", 0, -0.05, 0.05}}
    addStrokeBox(nil, 0.030, 0.030, "CenterCenter", {0,0},
        unknown.name, nil, CMFD_MATERIAL_YELLOW)

    local hostile = addPlaceholder(nil, {0,0}, dl.name)
    hostile.element_params = {"RADAR_DL_"..a.."_SIDE"}
    hostile.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
    object = addStrokeBox(nil, 0.030, 0.030, "CenterCenter", {0,0},
        hostile.name, nil, CMFD_MATERIAL_RED)
    object.init_rot = {45}

    local friendly = addPlaceholder(nil, {0,0}, dl.name)
    friendly.element_params = {"RADAR_DL_"..a.."_SIDE"}
    friendly.controllers = {{"parameter_in_range", 0, 1.95, 2.05}}
    addStrokeCircle(nil, 0.020, {0,0}, friendly.name,
        nil, nil, 0.5, 0.5, false, CMFD_MATERIAL_CYAN)

    addStrokeText(nil, "AW", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
        {0.020, 0.020}, dl.name, nil, nil, CMFD_FONT_CYAN)
end

-- [TWS CLEAN] Ate 10 tracks confirmados continuam visiveis. Contato nativo e
-- diamante ciano; Export e caixa amarela E, sempre awareness-only. Vetor, ID,
-- altitude e alcance aparecem somente no L&S nativo.
-- Isso altera apenas a apresentacao: deteccao, track slots, L&S e STT permanecem.
local track_w = 0.030
local track_h = 0.030
local function gateTrackElement(element, a, source)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, source - 0.05, source + 0.05},
    }
end

local function gateTrackAffiliation(element, a, friend)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
        "RADAR_TRACK_"..a.."_FRIEND",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, 0.95, 1.05},
        {"parameter_in_range", 4, friend - 0.05, friend + 0.05},
    }
end

local function gateTrackIff(element, a)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
        "RADAR_TRACK_"..a.."_IFF_SOURCE",
        "RADAR_TRACK_"..a.."_IFF_RESULT",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, 0.95, 1.05},
        {"parameter_in_range", 5, 0.95, 1.05},
    }
end

local function gateTrackLsText(element, a, value_param)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
        "RADAR_TRACK_"..a.."_LS",
        value_param,
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, 0.95, 1.05},
        {"text_using_parameter", 5, 0},
    }
end

local function gateTrackLsElement(element, a)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
        "RADAR_TRACK_"..a.."_LS",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, 0.95, 1.05},
    }
end

local function gateTrackDt2Element(element, a)
    element.element_params = {
        default_element_params,
        "RDR_MODE",
        "RADAR_TRACK_"..a.."_ACTIVE",
        "RADAR_TRACK_"..a.."_SOURCE",
        "RADAR_TRACK_"..a.."_DT2",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, 0.95, 1.05},
        {"parameter_in_range", 3, -0.05, 0.05},
        {"parameter_in_range", 4, 0.95, 1.05},
    }
end

local TWS_Group = addPlaceholder(nil, nil)
TWS_Group.element_params = {"RDR_MODE", "RADAR_STT_VALID"}
TWS_Group.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, -0.05, 0.05},
}
local _saved_parent = default_parent
default_parent = TWS_Group.name
for i=1,10 do
    local a = string.format("%02.0f", i)
    local Track_base = addPlaceholder(nil, {0, -grid_h/2})
    Track_base.element_params = {
        "RADAR_TRACK_"..a.."_AZIMUTH_NORM",
        "RADAR_TRACK_"..a.."_RANGE_NORM",
        "RADAR_TRACK_"..a.."_ACTIVE",
    }
    Track_base.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
        {"parameter_compare_with_number", 2, 1},
    }
    -- Diamante (4 segmentos)
    object = addStrokeLine(nil, track_h/1.4, {0,  track_h/2}, 135, Track_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackElement(object, a, 0)
    object = addStrokeLine(nil, track_h/1.4, {track_w/2, 0}, -135, Track_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackElement(object, a, 0)
    object = addStrokeLine(nil, track_h/1.4, {0, -track_h/2}, -45, Track_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackElement(object, a, 0)
    object = addStrokeLine(nil, track_h/1.4, {-track_w/2, 0}, 45, Track_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackElement(object, a, 0)
    object = addStrokeBox(nil, track_w, track_h, "CenterCenter", {0,0},
        Track_base.name, nil, CMFD_MATERIAL_YELLOW)
    gateTrackAffiliation(object, a, -1)
    object = addStrokeBox(nil, track_w, track_h, "CenterCenter", {0,0},
        Track_base.name, nil, CMFD_MATERIAL_RED)
    object.init_rot = {45}
    gateTrackAffiliation(object, a, 0)
    object = addStrokeCircle(nil, track_w * 0.55, {0,0}, Track_base.name,
        nil, nil, 0.5, 0.5, false, CMFD_MATERIAL_CYAN)
    gateTrackAffiliation(object, a, 1)
    object = addStrokeText(nil, "EX", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
        {track_w*0.65, track_h*0.55}, Track_base.name, nil, nil, CMFD_FONT_Y)
    gateTrackElement(object, a, 1)
    object = addStrokeLine(nil, track_w*1.25, {0, track_h*0.9}, 90,
        Track_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackIff(object, a)
    object = addStrokeText(nil, "I", CMFD_STRINGDEFS_DEF_X04, "RightCenter",
        {-track_w*0.8, track_h*0.2}, Track_base.name, nil, nil, CMFD_FONT_CYAN)
    gateTrackIff(object, a)
    -- Export/datalink aparece como caixa amarela E, mas permanece awareness-only:
    -- SOURCE_EXPORT nao e lockable nem elegivel a L&S.
    -- [Grifo A/A] Vetor de velocidade do alvo: linha saindo do diamante,
    -- rotacionada pela proa relativa (RADAR_TRACK_NN_HDG), padrao TWS moderno.
    local Vel_base = addPlaceholder(nil, {0, 0}, Track_base.name)
    Vel_base.element_params = {"RADAR_TRACK_"..a.."_HDG"}
    Vel_base.controllers = {{"rotate_using_parameter", 0, 1}}
    object = addStrokeLine(nil, track_h*2.0, {0, track_h*0.5}, 0, Vel_base.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackLsElement(object, a)
    -- ID do track (1..10) acima do diamante
    object = addStrokeText(nil, tostring(i), CMFD_STRINGDEFS_DEF_X06, "CenterBottom", {0, track_h/2}, Track_base.name, nil, {"%s"}, CMFD_FONT_W)
    gateTrackLsElement(object, a)
    -- [Grifo A/A] Altitude do alvo (kft) abaixo do diamante
    object = addStrokeText(nil, "12", CMFD_STRINGDEFS_DEF_X06, "CenterTop", {0, -track_h*0.7}, Track_base.name, nil, {"%02.0f"}, CMFD_FONT_CYAN)
    gateTrackLsText(object, a, "RADAR_TRACK_"..a.."_ALT")
    -- [Grifo polish] Alcance do alvo (nm) a direita do diamante (estilo Grifo:
    -- range explicito por contato, antes so implicito pela posicao vertical).
    object = addStrokeText(nil, "20", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {track_w*0.7, 0}, Track_base.name, nil, {"%2.0f"}, CMFD_FONT_CYAN)
    gateTrackLsText(object, a, "RADAR_TRACK_"..a.."_RANGE_NM")
    -- L&S and DT2 are persistent fire-control designations keyed by track ID.
    -- Moving the TDC alone cannot transfer either role.
    local LS_box = addPlaceholder(nil, {0, 0}, Track_base.name)
    LS_box.element_params = {"RADAR_TRACK_"..a.."_LS"}
    LS_box.controllers = {{"parameter_compare_with_number", 0, 1}}
    local bw = track_w * 2.8
    local bh = track_h * 2.8
    object = addStrokeLine(nil, bw, {-bw/2,  bh/2}, 90,  LS_box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackLsElement(object, a)
    object = addStrokeLine(nil, bw, { bw/2, -bh/2}, -90, LS_box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackLsElement(object, a)
    object = addStrokeLine(nil, bh, {-bw/2, -bh/2}, 0,   LS_box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackLsElement(object, a)
    object = addStrokeLine(nil, bh, { bw/2, -bh/2}, 0,   LS_box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    gateTrackLsElement(object, a)
    object = addStrokeText(nil, "1", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {bw * 0.58, bh * 0.42}, LS_box.name, nil, nil, CMFD_FONT_CYAN)
    gateTrackLsElement(object, a)

    local DT2_box = addPlaceholder(nil, {0, 0}, Track_base.name)
    DT2_box.element_params = {"RADAR_TRACK_"..a.."_DT2"}
    DT2_box.controllers = {{"parameter_compare_with_number", 0, 1}}
    object = addStrokeBox(nil, track_w * 2.3, track_h * 2.3, "CenterCenter",
        {0,0}, DT2_box.name, nil, CMFD_MATERIAL_YELLOW)
    gateTrackDt2Element(object, a)
    object = addStrokeText(nil, "2", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {track_w * 1.45, track_h * 1.05}, DT2_box.name, nil, nil, CMFD_FONT_Y)
    gateTrackDt2Element(object, a)
end
default_parent = _saved_parent

local function gateIffCue(element, status)
    element.element_params = {
        default_element_params,
        "IFF_QUERY_ACTIVE",
        "IFF_QUERY_STATUS",
        "RDR_MODE",
        "RADAR_STT_VALID",
    }
    element.controllers = {
        default_controllers[1],
        {"parameter_in_range", 1, 0.95, 1.05},
        {"parameter_in_range", 2, status - 0.05, status + 0.05},
        {"parameter_in_range", 3, -0.05, 1.05},
        {"parameter_in_range", 4, -0.05, 0.05},
    }
end

object = addStrokeText(nil, "IFF UNK", CMFD_STRINGDEFS_DEF_X08,
    "CenterCenter", {0, grid_h/2 - 0.20}, nil, nil, nil, CMFD_FONT_CYAN)
gateIffCue(object, 2)
object = addStrokeText(nil, "IFF AMB", CMFD_STRINGDEFS_DEF_X08,
    "CenterCenter", {0, grid_h/2 - 0.20}, nil, nil, nil, CMFD_FONT_Y)
gateIffCue(object, 3)
object = addStrokeText(nil, "IFF N/A", CMFD_STRINGDEFS_DEF_X08,
    "CenterCenter", {0, grid_h/2 - 0.20}, nil, nil, nil, CMFD_FONT_Y)
gateIffCue(object, 4)

object = addStrokeText("RDR_STT_IFF_FRIEND", "FRIEND", CMFD_STRINGDEFS_DEF_X08,
    "CenterCenter", {0, grid_h/2 - 0.20}, nil, nil, nil, CMFD_FONT_Y)
object.element_params = {default_element_params, "RADAR_STT_VALID", "IFF_QUERY_ACTIVE",
    "IFF_QUERY_RESULT", "IFF_QUERY_SOURCE", "IFF_QUERY_MODE",
    "RADAR_MODE", "RADAR_STT_RANGE", "RDR_ACTIVE", "RDR_AA_AG"}
object.controllers = {default_controllers[1],
    {"parameter_in_range", 1, 0.95, 1.05},
    {"parameter_in_range", 2, 0.95, 1.05},
    {"parameter_in_range", 3, 0.95, 1.05},
    {"parameter_in_range", 4, 0.95, 1.05},
    {"parameter_in_range", 5, 1.95, 2.05},
    {"parameter_in_range", 6, 2.95, 3.05},
    {"parameter_in_range", 7, 0.1, 1000000},
    {"parameter_in_range", 8, 0.95, 1.05},
    {"parameter_in_range", 9, -0.05, 0.05},
}

-- [Grifo Export A/G] Marcas de solo/mar sinteticas (GMT) do bridge: quadradinhos
-- so em A/G (RDR_AA_AG==1), por slot RADAR_AGT_NN_ACTIVE==1. Inerte sem bridge.
local AG_Group = addPlaceholder(nil, nil)
AG_Group.element_params = {"RDR_AA_AG"}
AG_Group.controllers = {{"parameter_compare_with_number", 0, 1}}
local _ag_parent = default_parent
default_parent = AG_Group.name
for i=1,10 do
    local a = string.format("%02.0f", i)
    local g = addPlaceholder(nil, {0, -grid_h/2})
    g.element_params = {"RADAR_AGT_"..a.."_AZ_NORM", "RADAR_AGT_"..a.."_RNG_NORM", "RADAR_AGT_"..a.."_ACTIVE"}
    g.controllers = {{"move_left_right_using_parameter", 0, lr_scale}, {"move_up_down_using_parameter", 1, ud_scale}, {"parameter_compare_with_number", 2, 1}}
    addStrokeBox(nil, 0.022, 0.022, "CenterCenter", {0,0}, g.name, nil, nil, CMFD_MATERIAL_WHITE)
end
default_parent = _ag_parent

-- [Grifo BVR] Data block do alvo primario (track mais proximo): altitude (kft),
-- velocidade (kt) e closure (kt, + fechando). So aparece em TWS com track ativo.
local Bug_block = addPlaceholder(nil, {-grid_w/2 + 0.07, grid_h/2 - 0.16})
Bug_block.element_params = {"RADAR_BUG_ACTIVE"}
Bug_block.controllers = {{"parameter_compare_with_number", 0, 1}}
object = addStrokeText(nil, "12", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0, 0.045}, Bug_block.name, nil, {"%02.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RADAR_BUG_ALT"}
object.controllers = {{"text_using_parameter", 0, 0}}
object = addStrokeText(nil, "450", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0, 0}, Bug_block.name, nil, {"%03.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RADAR_BUG_SPD"}
object.controllers = {{"text_using_parameter", 0, 0}}
object = addStrokeText(nil, "0", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0, -0.045}, Bug_block.name, nil, {"%+04.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RADAR_BUG_CLOSURE"}
object.controllers = {{"text_using_parameter", 0, 0}}

-- [Grifo NCTR 2026-08-30] Tipo reconhecido do alvo L&S. O codigo NCTR so existia
-- como string (`set_text` + formato `%s`), caminho que nao renderiza no DCS
-- 2.9.27 -- por isso a identificacao nunca aparecia no scope. rdr.lua agora
-- publica RADAR_BUG_NCTR_ID e cada tipo tem um rotulo estatico gateado por faixa.
local NCTR_LABELS = {
    { 2, "F-5"  }, { 3, "F-16" }, { 4, "F-15" }, { 5, "F-18" }, { 6, "F-14" },
    { 7, "F-4"  }, { 8, "MG21" }, { 9, "MG23" }, {10, "MG25" }, {11, "MG29" },
    {12, "MG31" }, {13, "SU25" }, {14, "SU27" }, {15, "SU30" }, {16, "SU33" },
    {17, "SU34" }, {18, "TU95" }, {19, "TU16" }, {20, "MIR"  }, {21, "RAF"  },
    {22, "GRP"  }, {23, "EFA"  }, {24, "A-10" }, {25, "A-4"  }, {26, "F117" },
    {27, "B-1"  }, {28, "B-52" }, {29, "AWAC" }, {30, "AH64" }, {31, "MI24" },
    {32, "SU24" },
}

-- Manual Designate on an Export contact creates a persistent AUX L&S. This is
-- a datalink designation, not STT; native correlation still owns the 509 pulse.
local AuxLock_base = addPlaceholder(nil, {0, -grid_h/2})
AuxLock_base.element_params = {
    "RADAR_ASSIST_AZ_NORM", "RADAR_ASSIST_RANGE_NORM",
    "RADAR_ASSIST_ACTIVE", "RADAR_ASSIST_MANUAL", "RDR_MODE", "RADAR_STT_VALID",
}
AuxLock_base.controllers = {
    {"move_left_right_using_parameter", 0, lr_scale},
    {"move_up_down_using_parameter", 1, ud_scale},
    {"parameter_in_range", 2, 0.95, 1.05},
    {"parameter_in_range", 3, 0.95, 1.05},
    {"parameter_in_range", 4, -0.05, 1.05},
    {"parameter_in_range", 5, -0.05, 0.05},
}
addStrokeBox(nil, 0.10, 0.10, "CenterCenter", {0,0},
    AuxLock_base.name, nil, CMFD_MATERIAL_YELLOW)
addStrokeText(nil, "AUX", CMFD_STRINGDEFS_DEF_X04, "LeftCenter",
    {0.058, 0.045}, AuxLock_base.name, nil, nil, CMFD_FONT_Y)
for _, entry in ipairs(NCTR_LABELS) do
    object = addStrokeText(nil, entry[2], CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {0.058, 0.005}, AuxLock_base.name, nil, nil, CMFD_FONT_W)
    object.element_params = {"RADAR_ASSIST_TYPE_ID"}
    object.controllers = {{"parameter_in_range", 0, entry[1] - 0.05, entry[1] + 0.05}}
end
object = addStrokeText(nil, "UNK", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
    {0.058, 0.005}, AuxLock_base.name, nil, nil, CMFD_FONT_Y)
object.element_params = {"RADAR_ASSIST_TYPE_ID"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}
object = addStrokeText(nil, "R00", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
    {0.058, -0.035}, AuxLock_base.name, nil, {"R%02.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RADAR_ASSIST_RANGE_NM"}
object.controllers = {{"text_using_parameter", 0, 0}}
object = addStrokeText(nil, "A00", CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
    {0.058, -0.070}, AuxLock_base.name, nil, {"A%02.0f"}, CMFD_FONT_CYAN)
object.element_params = {"RADAR_ASSIST_ALT_KFT"}
object.controllers = {{"text_using_parameter", 0, 0}}
for _, entry in ipairs({
    {-1, "U", CMFD_FONT_Y}, {0, "H", CMFD_FONT_R}, {1, "F", CMFD_FONT_CYAN},
}) do
    object = addStrokeText(nil, entry[2], CMFD_STRINGDEFS_DEF_X06, "RightCenter",
        {-0.058, 0.045}, AuxLock_base.name, nil, nil, entry[3])
    object.element_params = {"RADAR_ASSIST_FRIEND"}
    object.controllers = {{"parameter_in_range", 0, entry[1] - 0.05, entry[1] + 0.05}}
end
for _, entry in ipairs(NCTR_LABELS) do
    object = addStrokeText(nil, entry[2], CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0, -0.090}, Bug_block.name, nil, nil, CMFD_FONT_CYAN)
    object.element_params = {"RADAR_BUG_NCTR_ID"}
    object.controllers = {{"parameter_in_range", 0, entry[1] - 0.05, entry[1] + 0.05}}
end
-- Retorno NCTR presente mas sem match na tabela: honesto, nao inventa tipo.
object = addStrokeText(nil, "UNK", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0, -0.090}, Bug_block.name, nil, nil, CMFD_FONT_Y)
object.element_params = {"RADAR_BUG_NCTR_ID"}
object.controllers = {{"parameter_in_range", 0, 0.95, 1.05}}

-- Classe do alvo ao lado do tipo (F=caca, B=bombardeiro, A=ataque, H=helo, S=apoio).
for _, entry in ipairs({{1, "F"}, {2, "B"}, {3, "A"}, {4, "H"}, {5, "S"}}) do
    object = addStrokeText(nil, entry[2], CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0.11, -0.090}, Bug_block.name, nil, nil, CMFD_FONT_CYAN)
    object.element_params = {"RADAR_BUG_NCTR_CLASS"}
    object.controllers = {{"parameter_in_range", 0, entry[1] - 0.05, entry[1] + 0.05}}
end

-- Raid assessment: so aparece quando o cluster tem 2+ contatos (formacao).
object = addStrokeText(nil, "R2", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {0.16, -0.090}, Bug_block.name, nil, {"R%1.0f"}, CMFD_FONT_Y)
object.element_params = {"RADAR_BUG_RAID"}
object.controllers = {
    {"text_using_parameter", 0, 0},
    {"parameter_in_range", 0, 1.95, 9.05},
}

-- [Grifo F-16] DLZ (Dynamic Launch Zone) do Derby: FITA VERTICAL na borda direita
-- (estilo F-16). Haste vertical + ticks Rmax/Rne/Rmin + caret do alcance do alvo
-- L&S (sobe/desce na fita). So aparece com RADAR_DLZ_ACTIVE==1 (TWS + alvo L&S).
local dlz_x = grid_w/2 - 0.10
local DLZ_group = addPlaceholder(nil, {0, 0})
DLZ_group.element_params = {"RADAR_DLZ_ACTIVE"}
DLZ_group.controllers = {{"parameter_compare_with_number", 0, 1}}
-- haste vertical da fita (fundo -> topo do scope)
addStrokeLine(nil, grid_h, {dlz_x, -grid_h/2}, 0, DLZ_group.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
-- tick horizontal num alcance normalizado da fita
local function addDlzTick(norm_param, mat)
    local base = addPlaceholder(nil, {dlz_x, -grid_h/2}, DLZ_group.name)
    base.element_params = {norm_param}
    base.controllers = {{"move_up_down_using_parameter", 0, grid_h * GetScale()}}
    addStrokeLine(nil, 0.05, {-0.05, 0}, 90, base.name, nil, nil, nil, nil, mat)
    return base
end
addDlzTick("RADAR_DLZ_RMAX_NORM", CMFD_MATERIAL_CYAN)
addDlzTick("RADAR_DLZ_RNE_NORM",  CMFD_MATERIAL_WHITE)
addDlzTick("RADAR_DLZ_RMIN_NORM", CMFD_MATERIAL_CYAN)
-- caret do alvo L&S (bloco) na posicao do alcance dele na fita
local DLZ_tgt = addPlaceholder(nil, {dlz_x, -grid_h/2}, DLZ_group.name)
DLZ_tgt.element_params = {"RADAR_DLZ_TGT_NORM"}
DLZ_tgt.controllers = {{"move_up_down_using_parameter", 0, grid_h * GetScale()}}
addFillBox(nil, 0.03, 0.02, "CenterCenter", {-0.03, 0}, DLZ_tgt.name, nil, CMFD_MATERIAL_CYAN)

-- [Grifo F-16] ASE (Allowable Steering Error): circulo central + ponto de steering.
-- Ativo com Derby selecionado; centrar o ponto no circulo = apontar no alvo L&S.
local ASE_group = addPlaceholder(nil, {0, 0})
ASE_group.element_params = {"RADAR_ASE_ACTIVE"}
ASE_group.controllers = {{"parameter_compare_with_number", 0, 1}}
addStrokeCircle(nil, 0.16, {0, 0}, ASE_group.name, nil, nil, nil, nil, false, CMFD_MATERIAL_CYAN)
local ASE_dot = addPlaceholder(nil, {0, 0}, ASE_group.name)
ASE_dot.element_params = {"RADAR_ASE_AZ_NORM"}
ASE_dot.controllers = {{"move_left_right_using_parameter", 0, grid_w * GetScale()}}
addFillBox(nil, 0.03, 0.03, "CenterCenter", {0, 0}, ASE_dot.name, nil, CMFD_MATERIAL_CYAN)

-- [Grifo BVR-2] Cue de SHOOT: alvo L&S dentro da DLZ do Derby + Derby pronto.
local Shoot_cue = addStrokeText(nil, "SHOOT", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, grid_h/2 - 0.12}, nil, nil, {"%s"}, CMFD_FONT_W)
Shoot_cue.element_params = {"RADAR_SHOOT_CUE", "RADAR_ACQ_STATE", "RADAR_ACQ_REASON", "F5EM_DERBY_CUE"}
Shoot_cue.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, -0.05, 0.05},
    {"parameter_in_range", 2, -0.05, 0.05},
    {"parameter_in_range", 3, -0.05, 0.05},
}

-- [Precisao 2026-06-26] Cue "IN RNG": alvo entre NEZ e Rmax (pode atirar, mas pode
-- escapar). Mutuamente exclusivo com SHOOT (que so acende na NEZ). Ciano p/ diferenciar.
local InRng_cue = addStrokeText(nil, "IN RNG", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, grid_h/2 - 0.12}, nil, nil, {"%s"}, CMFD_FONT_CYAN)
InRng_cue.element_params = {"RADAR_IN_RNG_CUE", "RADAR_ACQ_STATE", "RADAR_ACQ_REASON", "F5EM_DERBY_CUE"}
InRng_cue.controllers = {
    {"parameter_in_range", 0, 0.95, 1.05},
    {"parameter_in_range", 1, -0.05, 0.05},
    {"parameter_in_range", 2, -0.05, 0.05},
    {"parameter_in_range", 3, -0.05, 0.05},
}

local Acq_cue = addStrokeText(nil, "ACQ", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, grid_h/2 - 0.12}, nil, nil, {"%s"}, CMFD_FONT_Y)
Acq_cue.element_params = {"RADAR_ACQ_STATE", "F5EM_DERBY_CUE"}
Acq_cue.controllers = {{"parameter_in_range", 0, 0.95, 1.05}, {"parameter_in_range", 1, -0.05, 0.05}}

local NoLock_cue = addStrokeText(nil, "NO LOCK", CMFD_STRINGDEFS_DEF_X2, "CenterCenter", {0, grid_h/2 - 0.12}, nil, nil, {"%s"}, CMFD_FONT_R)
NoLock_cue.element_params = {"RADAR_ACQ_STATE", "RADAR_ACQ_REASON", "F5EM_DERBY_CUE"}
NoLock_cue.controllers = {
    {"parameter_in_range", 0, 1.95, 2.05},
    {"parameter_in_range", 1, -0.05, 0.05},
    {"parameter_in_range", 2, -0.05, 0.05},
}

local function addAcqReason(label, reason, material, state_min, state_max)
    local cue = addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X2, "CenterCenter",
        {0, grid_h/2 - 0.12}, nil, nil, {"%s"}, material)
    cue.element_params = {"RADAR_ACQ_REASON", "RADAR_ACQ_STATE", "F5EM_DERBY_CUE"}
    cue.controllers = {
        {"parameter_in_range", 0, reason - 0.05, reason + 0.05},
        {"parameter_in_range", 1, state_min, state_max},
        {"parameter_in_range", 2, -0.05, 0.05},
    }
end
addAcqReason("CUE",      1, CMFD_FONT_Y, -0.05, 0.05)
addAcqReason("NO TGT",   2, CMFD_FONT_R, -0.05, 0.05)
addAcqReason("NO TGT",   2, CMFD_FONT_R,  1.95, 2.05)
addAcqReason("NO ACK",   3, CMFD_FONT_R,  1.95, 2.05)
addAcqReason("LOCK LOST",4, CMFD_FONT_R, -0.05, 0.05)
addAcqReason("FRIEND",   5, CMFD_FONT_Y, -0.05, 0.05)
addAcqReason("AMB",      7, CMFD_FONT_Y, -0.05, 0.05)

local derby_cues = dofile(LockOn_Options.script_path.."Systems/radar_engagement_sequence.lua").CUE_TEXT
for index, label in ipairs(derby_cues) do
    local cue = addStrokeText("CMFD_Derby_Cue_"..index, label, CMFD_STRINGDEFS_DEF_X2,
        "CenterCenter", {0, grid_h/2 - 0.12}, nil, nil, nil, CMFD_FONT_CYAN)
    cue.element_params = {"F5EM_DERBY_CUE"}
    cue.controllers = {{"parameter_in_range", 0, index - 0.05, index + 0.05}}
end

-- [Fase 1] Grifo-F VS overlay (Velocity Search): eixo vertical = closure.
-- Os contatos ja sao posicionados por RADAR_SEARCH_NN_VS_NORM (azimute x
-- range-rate); o que faltava era a propria escala, sem a qual a altura no scope
-- nao tinha leitura. VS_NORM = closure_mps / 686, logo +-1 = +-686 m/s = +-1330 kt.
local VS_Group = addPlaceholder(nil, nil)
VS_Group.element_params = {"RDR_MODE"}
VS_Group.controllers = {{"parameter_compare_with_number", 0, 2}}
_saved_parent = default_parent
default_parent = VS_Group.name
object = addStrokeText(nil, "VS", CMFD_STRINGDEFS_DEF_X08, "LeftTop", {-grid_w/2 + 0.04, grid_h/2 - 0.04}, nil, nil, {"%s"}, CMFD_FONT_CYAN)
object = addStrokeText(nil, "VC KT", CMFD_STRINGDEFS_DEF_X06, "LeftTop", {-grid_w/2 + 0.04, grid_h/2 - 0.13}, nil, nil, {"%s"}, CMFD_FONT_CYAN)
-- Referencia de closure zero: acima fecha, abaixo abre.
addStrokeLine(nil, grid_w, {-grid_w/2, 0}, 90, VS_Group.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
local function addVsTick(norm, label)
    local y = (grid_h/2) * norm
    addStrokeLine(nil, 0.06, {-grid_w/2, y}, 90, VS_Group.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X06, "LeftCenter",
        {-grid_w/2 + 0.07, y}, VS_Group.name, nil, nil, CMFD_FONT_CYAN)
end
addVsTick( 1.0, "+1330")
addVsTick( 0.5, "+670")
addVsTick(-0.5, "-670")
addVsTick(-1.0, "-1330")
default_parent = _saved_parent

-- [Fase 1] Grifo-F ACM scan window overlay: caixa cyan na posicao da janela
-- selecionada (BORE/VACQ/AACQ) no centro do grid (boresight do nariz).
local ACM_Group = addPlaceholder(nil, nil)
ACM_Group.element_params = {"RDR_MODE"}
ACM_Group.controllers = {{"parameter_compare_with_number", 0, 3}}
_saved_parent = default_parent
default_parent = ACM_Group.name
-- Tres caixas, uma por submodo. Cada uma so aparece quando o submodo bate.
local function addAcmBox(sub_id, w_norm, h_norm, label)
    local Box = addPlaceholder(nil, {0, 0})
    Box.element_params = {"RDR_ACM_SUB"}
    Box.controllers = {{"parameter_compare_with_number", 0, sub_id}}
    local bx = w_norm/2
    local by = h_norm/2
    object = addStrokeLine(nil, w_norm, {-bx,  by}, 90,  Box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    object = addStrokeLine(nil, w_norm, { bx, -by}, -90, Box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    object = addStrokeLine(nil, h_norm, {-bx, -by}, 0,   Box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    object = addStrokeLine(nil, h_norm, {-bx,  by}, 180, Box.name, nil, nil, nil, nil, CMFD_MATERIAL_CYAN)
    object = addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X06, "CenterTop", {0, -by - 0.005}, Box.name, nil, {"%s"}, CMFD_FONT_CYAN)
end
addAcmBox(0, 0.10, 0.10, "BORE")  -- cone 1 deg, caixa pequena
addAcmBox(1, 0.04, 0.40, "VACQ")  -- vertical estreita longa
addAcmBox(2, 0.40, 0.20, "AACQ")  -- HUD area
default_parent = _saved_parent

-- Cursor
function addRadarCursor(rel_size)
    local size_w = rel_size * grid_w
    local size_h = rel_size * grid_h
    local base = addPlaceholder(nil, {0, -grid_h/2})
    base.element_params = {
        "RADAR_TDC_AZIMUTH_NORM",
        "RADAR_TDC_RANGE_NORM",
    }
    base.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
    }
    local object
    object = addStrokeLine(nil, size_h, {size_w/2, -size_h/2}, 0, base.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    object = addStrokeLine(nil, size_h, {-size_w/2, -size_h/2}, 0, base.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
    object = addStrokeText(nil, "HA", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {size_w/1.5, size_h/2}, base.name, nil, {"%02.0f"}, CMFD_FONT_W)
    object.element_params = {default_element_params, "RADAR_TDC_ALT_UPPER",}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1,0}}
    

    object = addStrokeText(nil, "LA", CMFD_STRINGDEFS_DEF_X06, "LeftCenter", {size_w/1.5, -size_h/2}, base.name, nil, {"%02.0f"}, CMFD_FONT_W)
    object.element_params = {default_element_params, "RADAR_TDC_ALT_LOWER",}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1,0}}
    return base
end
object = addRadarCursor(0.05)

-- STT
function addSTT(radius)
    local base = addPlaceholder(nil, {0, -grid_h/2})
    local stt_material = CMFD_MATERIAL_CYAN
    -- [F-5EM 2026-07-22 RWS lock fix] A "bolinha" de alvo travado (STT) agora
    -- aparece sempre que ha um STT lock VALIDO (RADAR_STT_VALID==1), em QUALQUER
    -- modo do radar (RWS/TWS/VS). O gate antigo era RADAR_MODE==3 (ACM legado do
    -- AN/APQ-159), entao no Grifo (RWS/TWS/VS) o circulo NUNCA aparecia mesmo com
    -- lock. STT_VALID e publicado pelo rdr.lua e cai a 0 no kill/perda de lock,
    -- entao a bolinha some sozinha quando o lock acaba.
    base.element_params = {
        "RADAR_STT_AZIMUTH_NORM",
        "RADAR_STT_RANGE_NORM",
        "RADAR_STT_VALID"
    }
    base.controllers = {
        {"move_left_right_using_parameter", 0, lr_scale},
        {"move_up_down_using_parameter", 1, ud_scale},
        {"parameter_in_range", 2, 0.95, 1.05}
    }
    local object
    object = addStrokeCircle(nil, radius, {0,0}, base.name, nil, nil, nil, nil, nil, stt_material)
    object.thickness = 0.1
    object.element_params = {default_element_params, "RADAR_STT_ANGLE"}
    object.controllers = {default_controllers[1], {"rotate_using_parameter", 1, 1}}
    object = addStrokeLine(nil, radius, {0,radius}, 0, object.name, nil, nil, nil, nil, stt_material)
    object.thickness = 0.1
    object = addStrokeLine(nil, radius, {0,0}, 0, object.parent_element, nil, nil, nil, nil, stt_material)
    object.thickness = 0.1
    object.vertices = {{0, radius}, {-radius * 0.707, -radius *0.707}, {radius * 0.707, -radius *0.707}}
    object.indices = {0,1, 1,2, 2,0}


    object = addStrokeText(nil, "HA", CMFD_STRINGDEFS_DEF_X06, "CenterTop", {0, -radius*1.2 }, base.name, nil, {"%02.0f\n","%02.00f"}, CMFD_FONT_CYAN)
    object.element_params = {default_element_params, "RADAR_STT_ALT", "RADAR_STT_SPD"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}}


    -- HPT Bulls Eye information
    object = addStrokeText(nil, "135`\n10 ", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {-0.65, -0.7}, nil, nil, {"%03.0f'\n%02.0f"})
    object.element_params = {default_element_params, "RDR_HPT_BULLS_AZ", "RDR_HPT_BULLS_DIST", "RDR_HPT_AVAIL"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"parameter_compare_with_number", 3, 1}}

    -- HPT Data Block
    object = addStrokeText(nil, "135`\n450\n11L", CMFD_STRINGDEFS_DEF_X08, "LeftBottom", {0.65, -0.75 + 0.06}, nil, nil, {"%03.0f`\n", "%03.0f\n", "%02.0f", "%s"})
    object.element_params = {default_element_params, "RDR_HPT_HDG", "RDR_HPT_REL_SPD", "RDR_HPT_DIR", "RDR_HPT_DIR_LR", "RDR_HPT_AVAIL"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"text_using_parameter", 3, 2}, {"text_using_parameter", 4, 3}, {"parameter_compare_with_number", 5, 1}}

    -- HPT Time to Target
    object = addStrokeText(nil, "00:00", CMFD_STRINGDEFS_DEF_X08, "RightCenter", {-0.65, 0.68}, nil, nil, {"%02.0f:", "%02.0f"})
    object.element_params = {default_element_params, "RDR_HPT_TTT_MIN", "RDR_HPT_TTT_SEC", "RDR_HPT_AVAIL"}
    object.controllers = {default_controllers[1], {"text_using_parameter", 1, 0}, {"text_using_parameter", 2, 1}, {"parameter_compare_with_number", 3, 1}}

    return base
end
object = addSTT(0.045)

object = addDLZ({0.8,0}, 0.03, 0.5, nil, CMFD_STRINGDEFS_DEF_X08, false)