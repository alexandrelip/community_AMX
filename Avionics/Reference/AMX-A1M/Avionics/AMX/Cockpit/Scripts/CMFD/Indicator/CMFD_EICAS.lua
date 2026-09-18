dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local side = get_param_handle("CMFDNumber"):get()
local indication = dofile(LockOn_Options.script_path .. "Indicator/host_eicas_indication.lua")
local main = create_page_root()
main.element_params = {"CMFD" .. side .. "Format"}
main.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.EICAS}}
indication.engine_panel(main.name)

local auxiliary = create_page_root()
auxiliary.element_params = {"CMFD" .. side .. "FULL", "CMFD" .. side .. "Format"}
auxiliary.controllers = {{"parameter_compare_with_number", 0, 0}, {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}}
for _, selection in ipairs({{"Left", -0.5}, {"Right", 0.5}}) do
    local origin = addPlaceholder(nil, {selection[2], -((GetAspect() - 0.45) / 2 + 0.3)}, auxiliary.name)
    origin.element_params = {"CMFD" .. side .. "Sel" .. selection[1]}
    origin.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.EICAS}}
    local background = addFillBox(nil, 0.96, GetAspect() - 0.42, "CenterCenter", {0, 0}, origin.name, nil, CMFD_MATERIAL_DARK)
    background.additive_alpha = false
    indication.engine_summary(origin.name)
end