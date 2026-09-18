dofile(LockOn_Options.script_path .. "HUD/Indicator/HUD_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
dofile(LockOn_Options.script_path .. "Systems/weapon_system_api.lua")


local object
local HUD_DGFT_ScaleRoot = create_hud_scaled_root("HUD_DGFT_ScaleRoot")
default_parent = HUD_DGFT_ScaleRoot.name

-- DGFT
local HUD_DGFT_origin = addPlaceholder(nil, {0, DegToMil(1.2)})
HUD_DGFT_origin.element_params = {"AVIONICS_MASTER_MODE"}
HUD_DGFT_origin.controllers = {
	{"parameter_in_range",0,AVIONICS_MASTER_MODE_ID.DGFT_S-0.5, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.5},
}
default_parent = HUD_DGFT_origin.name

local HUD_DGFT_S_origin = addPlaceholder(nil, {0, 0}, HUD_DGFT_origin.name)
HUD_DGFT_S_origin.element_params = {"AVIONICS_MASTER_MODE"}
HUD_DGFT_S_origin.controllers = {
	{"parameter_in_range", 0, AVIONICS_MASTER_MODE_ID.DGFT_S - 0.05, AVIONICS_MASTER_MODE_ID.DGFT_S + 0.05},
}

-- DGFT M expanded HUD-area acquisition window. It represents the clipped
-- 25 x 12 degree AACQ volume and disappears as soon as a target is acquired.
local HUD_DGFT_M_Search = addPlaceholder("HUD_DGFT_M_Search", {0, 5}, HUD_DGFT_origin.name)
HUD_DGFT_M_Search.element_params = {"AVIONICS_MASTER_MODE", "F5EM_COMBAT_TARGET_SHOW"}
HUD_DGFT_M_Search.controllers = {
	{"parameter_in_range", 0, AVIONICS_MASTER_MODE_ID.DGFT_M - 0.05, AVIONICS_MASTER_MODE_ID.DGFT_M + 0.05},
	{"parameter_in_range", 1, -0.05, 0.05},
}
local search_half_w = 48
local search_half_h = 24
local search_corner = 16
addStrokeLine("HUD_DGFT_M_Search_TL_H", search_corner, {-search_half_w, search_half_h}, -90, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {-search_half_w, search_half_h}, 0, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {search_half_w - search_corner, search_half_h}, -90, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {search_half_w, search_half_h}, 180, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {-search_half_w, -search_half_h}, -90, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {-search_half_w, -search_half_h + search_corner}, 0, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {search_half_w - search_corner, -search_half_h}, -90, HUD_DGFT_M_Search.name)
addStrokeLine(nil, search_corner, {search_half_w, -search_half_h + search_corner}, 180, HUD_DGFT_M_Search.name)

-- IR Caged
object = addStrokeSymbol("HUD_DGFT_IR_Search_Diamond", {"f5em_stroke_symbols", "aim9lm-caged"}, "CenterCenter", {0, -DegToMil(1.2)}, HUD_DGFT_S_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK",
    "WS_IR_MISSILE_SEEKER_DESIRED_AZIMUTH", "WS_IR_MISSILE_SEEKER_DESIRED_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 2.05},
	{"parameter_in_range", 2, -0.05, 0.05},
	{"move_left_right_using_parameter", 3, -move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

-- IR Uncaged
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "aim9lm-uncaged"}, "CenterCenter", {0, -DegToMil(1.2)}, HUD_DGFT_S_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, -0.05, 0.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}
-- [F-5EM v0.61.10 desk-check 2026-07-11] Salvar ref do uncaged para reusar
-- como parent do "IR out of screen" abaixo. v0.61.8/v0.61.9 inseriram novos
-- objects (HOBS branch + LOCK BLINK box) entre este bloco e a fpm-cross,
-- movendo o parent implicito ('object.name') para o BOX de LOCK -- resultado:
-- cross off-screen so aparecia com LOCK ativo (regressao). Fix ancora a
-- cross ao uncaged CAGED=0 explicitamente.
local _uncaged_obj = object

-- [F-5EM v0.61.8 2026-07-11] IR HOBS (CAGED==2, HMD ativo). Antes NAO
-- existia -- CAGED=2 (HOBS mode com HMD ativo) nao renderizava nenhum
-- losango no HUD, so o marker HMD. User reportou: quando growl toca
-- deveria ter losango no alvo. Correto -- adicionado este branch que
-- posiciona o mesmo simbolo aim9lm-uncaged na LOS do seeker (que em
-- HOBS = LOS do capacete via WS_IR_MISSILE_SEEKER_DESIRED_* publicado
-- por weapon_system.lua). Bate com convencao F-18 real: losango
-- aparece SEMPRE que o seeker tem tracking, independente de HMD.
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "aim9lm-uncaged"}, "CenterCenter", {0, -DegToMil(1.2)}, HUD_DGFT_S_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_IR_LOCK_BLINK", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION", "HUD_MSL_HIDDEN"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 1.95, 2.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
	-- [F-5EM 2026-07-28] Em HOBS a LOS do seeker fica quase sempre fora do
	-- campo do HUD. limit_xy nao esconde, ele PROJETA o vetor na borda, entao
	-- o losango ficava preso na moldura deslizando/girando a cada movimento
	-- de cabeca. Agora ele so aparece quando a LOS esta realmente dentro do
	-- HUD; fora disso quem indica o alvo e o HMD + a cruz abaixo.
	{"parameter_in_range", 5, -0.05, 0.05},
}

-- IR out of screen (HOBS)
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, HUD_DGFT_S_origin.name)
object.element_params = {"HUD_BRIGHT", "WPN_MSL_CAGED", "HUD_MSL_HIDDEN", "HUD_IR_MISSILE_TARGET_AZIMUTH", "HUD_IR_MISSILE_TARGET_ELEVATION"}
object.controllers = {
	{"opacity_using_parameter", 0},
	{"parameter_in_range", 1, 1.95, 2.05},
	{"parameter_in_range", 2, 0.95, 1.05},
	{"move_left_right_using_parameter", 3, move_scale},
	{"move_up_down_using_parameter", 4, move_scale},
}

-- IR out of screen
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, _uncaged_obj.name)
object.element_params = {"HUD_BRIGHT", "HUD_MSL_HIDDEN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_in_range", 1, 0.95, 1.05}}

-- Piper
local HUD_Gun_Conformal = addPlaceholder("HUD_Gun_Conformal", {0, -DegToMil(1.2)}, HUD_DGFT_origin.name)
HUD_Gun_Conformal.controllers = {{"scale", 1 / HUD_LAYOUT_SCALE, 1 / HUD_LAYOUT_SCALE, 1}}
local HUD_Piper_origin = addPlaceholder(nil, {0,0}, HUD_Gun_Conformal.name)
HUD_Piper_origin.element_params = {"HUD_PIPER_X", "HUD_PIPER_Y"}
HUD_Piper_origin.controllers = {
	{"move_left_right_using_parameter", 0, 1},
	{"move_up_down_using_parameter", 1, 1},
}


-- LCOS SSLC SNAP piper
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "impact-point"}, "CenterCenter", {0, 0}, HUD_Piper_origin.name)

-- LCOS SSLC SNAP out of screen
object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "fpm-cross"}, "CenterCenter", {0, 0}, HUD_Piper_origin.name)
object.element_params = {"HUD_BRIGHT", "HUD_PIPER_HIDDEN"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number",1,1}}

-- LCOS SSLC recticle
local HUD_DGFT_MCOS_object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "gun-recticle"}, "CenterCenter", {0, 0}, HUD_Piper_origin.name)
HUD_DGFT_MCOS_object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT"}
HUD_DGFT_MCOS_object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, WPN_AA_SIGHT_IDS.LCOS-0.05 , WPN_AA_SIGHT_IDS.SSLC+0.05}, 
}

-- LCOS Line #2
object = addSimpleLine(nil, 10, {0,0}, 0, HUD_Gun_Conformal.name, nil, 0.5, HUD_MAT_DEF)
object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_A_X", "HUD_PIPER_LINE_A_Y"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_compare_with_number", 1, WPN_AA_SIGHT_IDS.LCOS}, 
	{"line_object_set_point_using_parameters", 1, 2, 3, 1, 1}, 
}

-- LCOS line #2
object = addSimpleLine(nil, 10, {0,0}, 0, HUD_Gun_Conformal.name, nil, 0.5, HUD_MAT_DEF)
object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_B_X", "HUD_PIPER_LINE_B_Y", "HUD_PIPER_LINE_C_X", "HUD_PIPER_LINE_C_Y"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_compare_with_number", 1, WPN_AA_SIGHT_IDS.LCOS}, 
	{"line_object_set_point_using_parameters", 0, 2, 3, 1, 1}, 
	{"line_object_set_point_using_parameters", 1, 4, 5, 1, 1}, 
}


-- SNAP Line #1
local HUD_SNAP_LINE1_Object = addSimpleLine(nil, 10, {0,0}, 0, HUD_Gun_Conformal.name, nil, 0.5, HUD_MAT_DEF)
HUD_SNAP_LINE1_Object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_A_X", "HUD_PIPER_LINE_A_Y"}
HUD_SNAP_LINE1_Object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, WPN_AA_SIGHT_IDS.SSLC - 0.5, WPN_AA_SIGHT_IDS.SNAP + 0.05}, 
	{"line_object_set_point_using_parameters", 1, 2, 3, 1, 1}, 
}

-- SNAP Line #2
local HUD_SNAP_LINE2_Object = addSimpleLine(nil, 10, {0,0}, 0, HUD_SNAP_LINE1_Object.name, nil, 0.5, HUD_MAT_DEF)
HUD_SNAP_LINE2_Object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_A_X", "HUD_PIPER_LINE_A_Y", "HUD_PIPER_LINE_B_X", "HUD_PIPER_LINE_B_Y"}
HUD_SNAP_LINE2_Object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, WPN_AA_SIGHT_IDS.SSLC - 0.5, WPN_AA_SIGHT_IDS.SNAP + 0.05}, 
	{"move_left_right_using_parameter", 2, 1},
	{"move_up_down_using_parameter", 3, 1},
	{"line_object_set_point_using_parameters", 1, 4, 5, 1, 1}, 
}
object = addStrokeLine(nil, 30, {-15, 0}, -90, HUD_SNAP_LINE2_Object.name)

-- SNAP Line #3
local HUD_SNAP_LINE3_Object = addSimpleLine(nil, 10, {0,0}, 0, HUD_SNAP_LINE2_Object.name, nil, 0.5, HUD_MAT_DEF)
HUD_SNAP_LINE3_Object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_B_X", "HUD_PIPER_LINE_B_Y", "HUD_PIPER_LINE_C_X", "HUD_PIPER_LINE_C_Y"}
HUD_SNAP_LINE3_Object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, WPN_AA_SIGHT_IDS.SSLC - 0.5, WPN_AA_SIGHT_IDS.SNAP + 0.05}, 
	{"move_left_right_using_parameter", 2, 1},
	{"move_up_down_using_parameter", 3, 1},
	{"line_object_set_point_using_parameters", 1, 4, 5, 1, 1}, 
}
object = addStrokeLine(nil, 15, {-7.5, 0}, -90, HUD_SNAP_LINE3_Object.name)
object = addStrokeLine(nil, 10, {-5, 0}, -90, HUD_SNAP_LINE3_Object.name)
object.element_params = {"HUD_BRIGHT", "WPN_AA_SIGHT", "HUD_PIPER_LINE_C_X", "HUD_PIPER_LINE_C_Y"}
object.controllers = {
	{"opacity_using_parameter", 0}, 
	{"parameter_in_range", 1, WPN_AA_SIGHT_IDS.SSLC - 0.5, WPN_AA_SIGHT_IDS.SNAP + 0.05}, 
	{"move_left_right_using_parameter", 3, -1},
	{"move_up_down_using_parameter", 2, 1},
}