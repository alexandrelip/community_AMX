-- =====================================================================
-- CMFD LT (Litening) sub-page  --  A-29B FLIR full-parity layout
-- =====================================================================
-- Sub-menu da pagina FLIR (SUB_PAGE_ID.LDP). Rotulo LT no menu Menu1 e
-- acessivel via botao OSS6 na pagina FLIR (backend ldp.lua dispatch).
-- Estrutura visual portada de A29MEFM/Cockpit/Scripts/CMFD/Indicator/
-- CMFD_FLIR.lua: video IR full-screen (render_target_1), overlays
-- dim/pol/contrast, escalas EL (-120..+30) e AZ (-180..+180) com marcadores
-- moveis (FLIR_EL/FLIR_AZ da base C++), reticulos por FOV (WFOV/MFOV/NFOV),
-- top-bar preta com badges de status, bottom-bar com LDP_STATUS_TEXT,
-- fallback "SEM POD LITENING" apenas quando teste sem pod estiver desligado.
--
-- Badges usam parameter_compare_with_number / parameter_in_range direto nos
-- handles FLIR_* (sem dependencia dos callbacks CMFD_TEXT.FLIR_*).
--
-- OSS1 "FLIR" retorna a pagina FLIR simples (SUB_PAGE_ID.LDP).
-- =====================================================================
dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/Device/cmfd_text.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu     = CMFDNumber:get()
local CMFD_BR    = "CMFD" .. tostring(CMFDNu) .. "_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD" .. CMFDNu .. "Format"}
page_root.controllers    = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.LT}}
default_parent = page_root.name

local aspect = GetAspect()

-- 1) VIDEO IR (render_target_1) -- geometria do CMFD_FLIR.lua do A-29.
local flir_video = CreateElement "ceTexPoly"
flir_video.name           = "flir_video_lt"
flir_video.material       = "render_target_1"
flir_video.vertices       = {{-1, 0.75}, {1, 0.75}, {1, -0.75}, {-1, -0.75}}
flir_video.indices        = {0, 1, 2, 0, 2, 3}
flir_video.tex_coords     = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
flir_video.init_pos       = {0, aspect / 4}
flir_video.level          = 1
-- Gate espelhado da ccCamera decompilada + A-29B parity (CMFD_FLIR.lua L45):
-- A-29B usa parameter_compare_with_number 1,1,1 -- video aparece assim que
-- FLIR_STATUS chega a 1 (energia eletrica OK). O antigo gate STATUS==5 do
-- F-5EM forcava esperar ~90s de warmup da DLL antes do raster aparecer.
flir_video.element_params = {CMFD_BR, "FLIR_STATUS", "FLIR_ELEC"}
flir_video.controllers    = {
    {"opacity_using_parameter", 0},
    {"parameter_compare_with_number", 1, 1, 1},
    {"parameter_compare_with_number", 2, 0.5, 1},
}
flir_video.parent_element = page_root.name
AddElementObject(flir_video)
local FLIR_VIDEO_NAME = flir_video.name
flir_video = nil

-- 2) OVERLAYS dim / polarity / contrast (gated FLIR_STATUS>=1 + energia -- A-29 parity)
local dim_veil = addFillBox(nil, 2, 2*aspect, "CenterCenter", {0, 0},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_BLACK)
dim_veil.element_params = {"FLIR_DIM", "FLIR_STATUS", "FLIR_ELEC"}
dim_veil.controllers    = {
    {"opacity_using_parameter", 0},
    {"parameter_compare_with_number", 1, 1, 1},
    {"parameter_compare_with_number", 2, 0.5, 1},
}

local pol_mask = addFillBox(nil, 2, 2*aspect, "CenterCenter", {0, 0},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_WHITE)
pol_mask.element_params = {"FLIR_POL_MASK", "FLIR_STATUS", "FLIR_ELEC"}
pol_mask.controllers    = {
    {"opacity_using_parameter", 0},
    {"parameter_compare_with_number", 1, 1, 1},
    {"parameter_compare_with_number", 2, 0.5, 1},
}

local cont_frame = addStrokeBox(nil, 1.94, 1.94*aspect, "CenterCenter", {0, 0},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_BLACK)
cont_frame.element_params = {"FLIR_CONT_FRAME", "FLIR_STATUS", "FLIR_ELEC"}
cont_frame.controllers    = {
    {"opacity_using_parameter", 0},
    {"parameter_compare_with_number", 1, 1, 1},
    {"parameter_compare_with_number", 2, 0.5, 1},
}

-- 3) Escala EL esquerda + marcador FLIR_EL
for i = 30, -120, -30 do
    local label = (i == 0) and string.format("%i-", i) or string.format("%+i-", i)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X07, "RightCenter",
        {-0.79, 0.5 - (30 - i) / 150}, FLIR_VIDEO_NAME, nil, nil, CMFD_FONT_W)
end
local el_marker = addFillBox(nil, 0.06, 0.02, "CenterCenter", {-0.78, 0.3},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_WHITE)
el_marker.element_params = {CMFD_BR, "FLIR_EL", "FLIR_STATUS", "FLIR_ELEC"}
el_marker.controllers    = {
    {"opacity_using_parameter", 0},
    {"move_up_down_using_parameter", 1, 1 / math.rad(150)},
    {"parameter_compare_with_number", 2, 1, 1},
    {"parameter_compare_with_number", 3, 0.5, 1},
}

-- 4) Escala AZ inferior + marcador FLIR_AZ
for i = -180, 180, 90 do
    local label = (i == 0) and string.format("|\n%i", i) or string.format("|\n%+i", i)
    addStrokeText(nil, label, CMFD_STRINGDEFS_DEF_X07, "CenterBottom",
        {0.6 * i / 180, -0.75}, FLIR_VIDEO_NAME, nil, nil, CMFD_FONT_W)
end
local az_marker = addFillBox(nil, 0.02, 0.06, "CenterCenter", {0, -0.62},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_WHITE)
az_marker.element_params = {CMFD_BR, "FLIR_AZ", "FLIR_STATUS", "FLIR_ELEC"}
az_marker.controllers    = {
    {"opacity_using_parameter", 0},
    {"move_left_right_using_parameter", 1, 0.6 / math.pi},
    {"parameter_compare_with_number", 2, 1, 1},
    {"parameter_compare_with_number", 3, 0.5, 1},
}

-- 5) RETICULOS por FOV -- bloco literal do CMFD_FLIR.lua do A-29.
local FLIR_recticle = addPlaceholder(nil, {0, 0}, FLIR_VIDEO_NAME)

local FLIR_recticle_NFOV = addPlaceholder(nil, {0, 0}, FLIR_recticle.name)
FLIR_recticle_NFOV.element_params = {"FLIR_FOV"}
FLIR_recticle_NFOV.controllers = {
    {"parameter_in_range", 0, 0, 2.5 * 0.02},
    {"scale_using_parameter", 0, 1/0.004, 1},
}
addStrokeLine(nil, 0.5, {0.0, 0.5}, 0,   FLIR_recticle_NFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {-0.5, 0}, 90,    FLIR_recticle_NFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {0.0, -0.5}, 180, FLIR_recticle_NFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {0.5, 0}, 270,    FLIR_recticle_NFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

local FLIR_recticle_MFOV = addPlaceholder(nil, {0, 0}, FLIR_recticle.name)
FLIR_recticle_MFOV.element_params = {"FLIR_FOV"}
FLIR_recticle_MFOV.controllers = {
    {"parameter_in_range", 0, 2.5 * 0.02, 2.5 * 0.1},
    {"scale_using_parameter", 0, 1/0.02, 1},
}
local object = addStrokeLine(nil, 0.5, {0, 0.5}, 0, FLIR_recticle_MFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.2, {0.1, 0.5}, 90, object.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.5, {-0.5, 0}, 90, FLIR_recticle_MFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.2, {0.1, 0.5}, 90, object.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.5, {0, -0.5}, 180, FLIR_recticle_MFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.2, {0.1, 0.5}, 90, object.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.5, {0.5, 0}, -90, FLIR_recticle_MFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, 0.2, {0.1, 0.5}, 90, object.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

local FLIR_recticle_WFOV = addPlaceholder(nil, {0, 0}, FLIR_recticle.name)
FLIR_recticle_WFOV.element_params = {"FLIR_FOV"}
FLIR_recticle_WFOV.controllers = {
    {"parameter_in_range", 0, 2.5 * 0.1, 2.5 * math.pi},
    {"scale_using_parameter", 0, 1/0.1, 1},
}
addStrokeLine(nil, 0.5, {0, 0.5}, 0, FLIR_recticle_WFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {-0.5, 0}, 90, FLIR_recticle_WFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {0, -0.5}, 180, FLIR_recticle_WFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine(nil, 0.5, {0.5, 0}, -90, FLIR_recticle_WFOV.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

-- 6) TOP BAR dinamica -- mesma composicao do CMFD_FLIR do A-29.
local function status_pos(i) return {-1 + 2 * i / 12, 0.005} end
local top_bar = addFillBox(nil, 2, 0.06, "CenterBottom", {0, 0.75},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_WHITE)

local function add_dynamic_status(x, placeholder, callback)
    local text = addStrokeText(nil, placeholder, CMFD_STRINGDEFS_DEF_X06,
        "CenterBottom", status_pos(x), top_bar.name, nil, nil, CMFD_FONT_K)
    text.element_params = {CMFD_BR}
    text.controllers = {
        {"opacity_using_parameter", 0},
        {"text_from_lua_function", callback, 0.5},
    }
    return text
end

add_dynamic_status(1.0,  "HI/HI/EN", CMFD_TEXT.FLIR_FILTER_STATUS)
add_dynamic_status(2.7,  "AUTO",     CMFD_TEXT.FLIR_SYMBOLOGY)
add_dynamic_status(4.0,  "AGN",      CMFD_TEXT.FLIR_GAIN)
add_dynamic_status(5.0,  "MOD",      CMFD_TEXT.FLIR_SCENE)
add_dynamic_status(6.0,  "TRK",      CMFD_TEXT.FLIR_TRACKER)
add_dynamic_status(6.5,  "AT",       CMFD_TEXT.FLIR_AUTO_TRACK_STATE)
add_dynamic_status(7.0,  "INRPT",    CMFD_TEXT.FLIR_CURRENT_MODE)
add_dynamic_status(7.5,  "L1/3",     CMFD_TEXT.FLIR_TRACK_LIST)
add_dynamic_status(8.0,  "WIDE",     CMFD_TEXT.FLIR_FOV)
add_dynamic_status(9.0,  "FRZ",      CMFD_TEXT.FLIR_FREEZE)
add_dynamic_status(9.3,  "WHT",      CMFD_TEXT.FLIR_POLARITY)
add_dynamic_status(9.7,  "IR",       CMFD_TEXT.FLIR_BAND)
add_dynamic_status(10.3, "RDY",      CMFD_TEXT.FLIR_STATUS)
add_dynamic_status(10.8, "LST",      CMFD_TEXT.FLIR_LST_STATUS)
add_dynamic_status(11.3, "IRPT",     CMFD_TEXT.FLIR_IR_PTR_STATUS)
add_dynamic_status(11.65,"COOL",     CMFD_TEXT.FLIR_THERMAL_STATE)

-- Ancora o ultimo campo na borda direita para L ARM/LASE crescer para dentro.
local laser_status = addStrokeText(nil, "L ARM", CMFD_STRINGDEFS_DEF_X06,
    "RightBottom", status_pos(12.0), top_bar.name, nil, nil, CMFD_FONT_K)
laser_status.element_params = {CMFD_BR}
laser_status.controllers = {
    {"opacity_using_parameter", 0},
    {"text_from_lua_function", CMFD_TEXT.FLIR_LASER_STATUS, 0.5},
}

-- 7) BOTTOM BAR: coordenadas, AZ/EL e data/hora.
local bot_bar = addFillBox(nil, 2, 0.06, "CenterBottom", {0, -0.81},
    FLIR_VIDEO_NAME, nil, CMFD_MATERIAL_WHITE)

local coords = addStrokeText(nil, "LAT N 00`00.00' LON E 000`00.00'",
    CMFD_STRINGDEFS_DEF_X05, "CenterBottom", status_pos(2.75),
    bot_bar.name, nil, nil, CMFD_FONT_K)
coords.element_params = {CMFD_BR}
coords.controllers = {
    {"opacity_using_parameter", 0},
    {"text_from_lua_function", CMFD_TEXT.FLIR_COORDS, 0.5},
}

local az_text = addStrokeText(nil, "0.0`AZ", CMFD_STRINGDEFS_DEF_X05,
    "RightBottom", status_pos(6.75), bot_bar.name, nil, {"%2.1f`AZ"}, CMFD_FONT_K)
az_text.element_params = {CMFD_BR, "FLIR_AZ_DEG"}
az_text.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

local el_text = addStrokeText(nil, "0.0`EL", CMFD_STRINGDEFS_DEF_X05,
    "RightBottom", status_pos(8.25), bot_bar.name, nil, {"%2.1f`EL"}, CMFD_FONT_K)
el_text.element_params = {CMFD_BR, "FLIR_EL_DEG"}
el_text.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}

local date_text = addStrokeText(nil, "DD-MM-YY HH:MM:SSL", CMFD_STRINGDEFS_DEF_X05,
    "RightBottom", status_pos(11.5), bot_bar.name, nil, {"%s"}, CMFD_FONT_K)
date_text.element_params = {CMFD_BR}
date_text.controllers = {{"opacity_using_parameter", 0}, {"date_time"}}

local laser_code = addStrokeText(nil, "L1688", CMFD_STRINGDEFS_DEF_X05,
    "RightTop", {0.95, -0.94}, FLIR_VIDEO_NAME, nil, nil, CMFD_FONT_W)
laser_code.element_params = {CMFD_BR}
laser_code.controllers = {
    {"opacity_using_parameter", 0},
    {"text_from_lua_function", CMFD_TEXT.FLIR_LASER_CODE, 0.5},
}

local laser_range = addStrokeText(nil, "R 12345 M", CMFD_STRINGDEFS_DEF_X05,
    "RightTop", {0.95, -0.99}, FLIR_VIDEO_NAME, nil, nil, CMFD_FONT_W)
laser_range.element_params = {CMFD_BR}
laser_range.controllers = {
    {"opacity_using_parameter", 0},
    {"text_from_lua_function", CMFD_TEXT.FLIR_LRF_RANGE, 0.5},
}

local target_info = addStrokeText(nil,
    "TARGET\nX  XX`XX.XX'\nX XXX`XX.XX'\n    X FT",
    CMFD_STRINGDEFS_DEF_X08, "LeftTop", {-0.50, -0.64},
    page_root.name, nil, nil, CMFD_FONT_DEF)
target_info.element_params = {CMFD_BR}
target_info.controllers = {
    {"opacity_using_parameter", 0},
    {"text_from_lua_function", CMFD_TEXT.FLIR_TARGET, 0.5},
}

-- 8) OSS exclusivos da pagina FLIR.
addOSSText(21, "COMP")
addOSSText(22, "BRT/C")
addOSSText(25, "L ARM")
addOSSText(26, "LASE")
addOSSText(13, "CODE+")
addOSSText(14, "CODE-")

-- Encobre os labels genericos do FULL_BASE e recompõe o rodape do A-29.
local nav_band = addFillBox(nil, 2, 0.16, "CenterBottom", {0, -aspect},
    page_root.name, nil, CMFD_MATERIAL_DARK)
addOSSText(20, "IND", nav_band.name)
addOSSText(17, "SWAP", nav_band.name)
addOSSText(16, "NAV", nav_band.name)
addOSSText(15, "DCLT", nav_band.name)

local flir_select = addFillBox(nil, 0.24, 0.085, "CenterCenter",
    {-0.42, -aspect + 0.045}, nav_band.name, nil, CMFD_MATERIAL_DEF)
addStrokeText(nil, "FLIR", CMFD_STRINGDEFS_DEF_X08, "CenterCenter",
    {0, 0}, flir_select.name, nil, nil, CMFD_FONT_K)

-- 9) Fallback "SEM POD LITENING" (somente quando FLIR_TEST_NO_POD=0)
local nopod = CreateElement "ceStringPoly"
nopod.material       = CMFD_FONT_DEF
nopod.stringdefs     = CMFD_STRINGDEFS_DEF_X08
nopod.init_pos       = {0, 0}
nopod.alignment      = "CenterCenter"
nopod.value          = "SEM POD LITENING\nmonte AN/AAQ-28\n(estacao 4 ventral)"
nopod.formats        = {"%s"}
nopod.element_params = {CMFD_BR, "FLIR_POD_PRESENT", "FLIR_TEST_NO_POD", "CMFD_VARIANT_F5TH"}
nopod.controllers    = {
    {"opacity_using_parameter", 0},
    {"parameter_compare_with_number", 1, 0, 1},
    {"parameter_compare_with_number", 2, 0, 1},
    {"parameter_compare_with_number", 3, 1, 1},
}
nopod.parent_element = page_root.name
AddElementObject(nopod)
nopod = nil
