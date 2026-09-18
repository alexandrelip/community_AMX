dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber=get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_in_range", 0, SUB_PAGE_ID.MENU2 - 0.05, SUB_PAGE_ID.MENU2 + 0.05}}

local MENU_BRIGHT_PARAM = "CMFD"..tostring(CMFDNu).."_BRIGHT"
local MENU_FORMAT_PARAM = "CMFD"..CMFDNu.."Format"
local MENU_PARAMS = {MENU_BRIGHT_PARAM, MENU_FORMAT_PARAM}
local MENU_CONTROLLERS = {
    {"opacity_using_parameter", 0},
    {"parameter_in_range", 1, SUB_PAGE_ID.MENU2 - 0.05, SUB_PAGE_ID.MENU2 + 0.05},
}

local HW = 0.15
local HH = 0.04 * H2W_SCALE

local osb_txt = {
    {value="MENU\n1",       init_pos={CMFD_FONT_UD1_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={}},
    {value="MSMD\nRST",     init_pos={CMFD_FONT_UD2_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={}},
    {value="SG\nRST",       init_pos={CMFD_FONT_UD4_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={}},
}

local text_strpoly
local mesh_poly

for i=1, #(osb_txt) do
    text_strpoly                = CreateElement "ceStringPoly"
    text_strpoly.material       = CMFD_FONT_DEF
    text_strpoly.stringdefs     = CMFD_STRINGDEFS_DEF_X08
    text_strpoly.init_pos       = osb_txt[i].init_pos
    text_strpoly.alignment      = osb_txt[i].align
    text_strpoly.formats        = osb_txt[i].formats
    text_strpoly.element_params = MENU_PARAMS
    text_strpoly.controllers    = MENU_CONTROLLERS
    text_strpoly.name = "osb_txt_" .. i
    if osb_txt[i].value ~= nil then
        text_strpoly.value = osb_txt[i].value
    else
        text_strpoly.value = "OSB" .. i
    end
    text_strpoly.parent_element    = page_root.name
    AddElementObject(text_strpoly)
    text_strpoly = nil
end

local function add_page_entry(pos, text, code, size, lines)
    size = size or #text
    lines = lines or (1 + select(2, text:gsub('\n', '\n')))
    addOSSText(pos, text, page_root.name, MENU_PARAMS, MENU_CONTROLLERS)
    local box = addOSSStrokeBox(pos, lines, page_root.name, nil, nil, nil, size)
    box.element_params = {MENU_BRIGHT_PARAM, "CMFD"..CMFDNu.."Sel", MENU_FORMAT_PARAM}
    box.controllers = {
        {"opacity_using_parameter", 0},
        {"parameter_in_range", 1, code - 0.05, code + 0.05},
        {"parameter_in_range", 2, SUB_PAGE_ID.MENU2 - 0.05, SUB_PAGE_ID.MENU2 + 0.05},
    }
end

local function add_page_entry_variant(pos, text, code, variant_param, variant_value, size, lines)
    size = size or #text
    lines = lines or (1 + select(2, text:gsub('\n', '\n')))
    addOSSText(pos, text, page_root.name,
        {MENU_BRIGHT_PARAM, variant_param, MENU_FORMAT_PARAM}, {
            {"opacity_using_parameter", 0},
            {"parameter_in_range", 1, variant_value - 0.05, variant_value + 0.05},
            {"parameter_in_range", 2, SUB_PAGE_ID.MENU2 - 0.05, SUB_PAGE_ID.MENU2 + 0.05},
        })
    local box = addOSSStrokeBox(pos, lines, page_root.name, nil, nil, nil, size)
    box.element_params = {
        MENU_BRIGHT_PARAM,
        "CMFD"..CMFDNu.."Sel",
        variant_param,
        MENU_FORMAT_PARAM,
    }
    box.controllers = {
        {"opacity_using_parameter", 0},
        {"parameter_in_range", 1, code - 0.05, code + 0.05},
        {"parameter_in_range", 2, variant_value - 0.05, variant_value + 0.05},
        {"parameter_in_range", 3, SUB_PAGE_ID.MENU2 - 0.05, SUB_PAGE_ID.MENU2 + 0.05},
    }
end

add_page_entry(6, "MAP", SUB_PAGE_ID.MAP)
add_page_entry(7, "DL\nSET", SUB_PAGE_ID.DLSET, 3, 2)
add_page_entry(8, "DL\nMSG", SUB_PAGE_ID.DLMSG, 3, 2)
add_page_entry(9, "EFB", SUB_PAGE_ID.EFB)
add_page_entry_variant(10, "SURV", SUB_PAGE_ID.SURV, "CMFD_VARIANT_F5EM", 1)

-- Selecionado
for i=1, #(osb_txt) do
    if osb_txt[i].align == "LeftCenter" or osb_txt[i].align == "RightCenter" then
        mesh_poly                       = CreateElement "ceMeshPoly"
        mesh_poly.name                  = "OSBTITLE" .. i
        mesh_poly.parent_element        = "osb_txt_" .. i
        if osb_txt[i].align == "LeftCenter" then
            mesh_poly.init_pos          = { HW, 0}
        elseif osb_txt[i].align == "RightCenter" then
            mesh_poly.init_pos          = {-HW, 0}
        elseif osb_txt[i].align == "CenterTop" then
            mesh_poly.init_pos          = {0, -HW}
        else
            mesh_poly.init_pos          = {0, 0}
        end
        mesh_poly.material              = CMFD_MATERIAL_DEF
        mesh_poly.primitivetype         = "triangles"
        mesh_poly.vertices              = { {HW, HH}, {HW,-HH}, {-HW,-HH}, {-HW, HH }}
        mesh_poly.indices               = default_box_indices
        mesh_poly.isvisible             = true
        mesh_poly.element_params        = osb_txt[i].params
        if osb_txt[i].controller and osb_txt[i].controller[1] then 
            mesh_poly.controllers       = {{"parameter_in_range", 0, osb_txt[i].controller[1][3] - 0.05, osb_txt[i].controller[1][3] + 0.05}}
        else 
            mesh_poly.isvisible         = false
        end

        AddElementObject(mesh_poly)
        mesh_poly = nil
    end
end

-- -- Sublinhado
-- for i=1, #(osb_txt) do
--         mesh_poly                = CreateElement "ceMeshPoly"
--         mesh_poly.name             = "OSBUNDER" .. i
--         mesh_poly.parent_element= "osb_txt_" .. i
--         if osb_txt[i].align == "LeftCenter" then
--             mesh_poly.init_pos = { HW, 0}
--         else
--             if osb_txt[i].align == "RightCenter" then
--                 mesh_poly.init_pos = {-HW, 0}
--             end
--         end
--         mesh_poly.material        = CMFD_MATERIAL_DEF
--         mesh_poly.primitivetype    = "lines"
--         mesh_poly.vertices        = { { HW, -1.2*HH},    {-HW, -1.2*HH},}
--         mesh_poly.indices        = {0,1}
--         mesh_poly.isvisible        = false
--         AddElementObject(mesh_poly)
--         mesh_poly = nil
-- end

-- -- Indisponível
-- for i=1, #(osb_txt) do
--     mesh_poly                = CreateElement "ceMeshPoly"
--     mesh_poly.name             = "OSBNA" .. i
--     mesh_poly.parent_element= "osb_txt_" .. i
--     if osb_txt[i].align == "LeftCenter" then
--         mesh_poly.init_pos = { HW, 0, 0}
--     elseif osb_txt[i].align == "RightCenter" then
--         mesh_poly.init_pos = {-HW, 0, 0}
--     elseif osb_txt[i].align == "CenterTop" then
--         mesh_poly.init_pos = {0, -HW, 0}
--     else
--         mesh_poly.init_pos = {0, 0, 0}
--     end
--     mesh_poly.material        =  CMFD_IND_MATERIAL
--     mesh_poly.primitivetype    = "lines"
--     mesh_poly.vertices        = { { HW, HH},{-HW, -HH}, }
--     mesh_poly.indices        = {0,1}
--     mesh_poly.isvisible        = false
--     AddElementObject(mesh_poly)
--     mesh_poly = nil
-- end
