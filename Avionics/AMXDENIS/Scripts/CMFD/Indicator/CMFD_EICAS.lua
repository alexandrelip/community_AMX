dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
local side = get_param_handle("CMFDNumber"):get()
local indication = dofile(LockOn_Options.script_path .. "Indicator/host_eicas_indication.lua")
local layout = dofile(LockOn_Options.script_path .. "Indicator/host_eicas_layout.lua")(indication)
local top, bottom = GetAspect() - 0.12, -GetAspect() + 0.15
for _, full in ipairs({0, 1}) do
    local main = create_page_root()
    main.element_params = {"CMFD" .. side .. "Format", "CMFD" .. side .. "FULL", "CMFD" .. side .. "On"}
    main.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.EICAS},
        {"parameter_compare_with_number", 1, full}, {"parameter_compare_with_number", 2, 1}}
    layout.draw(main.name, -0.90, top, 1.80, full == 1 and top - bottom or top + 0.26)
end
local auxiliary = create_page_root()
auxiliary.element_params = {"CMFD" .. side .. "FULL", "CMFD" .. side .. "Format", "CMFD" .. side .. "On"}
auxiliary.controllers = {{"parameter_compare_with_number", 0, 0},
    {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}, {"parameter_compare_with_number", 2, 1}}
for _, selection in ipairs({{"Left", -0.90}, {"Right", 0.03}}) do
    local root = addPlaceholder(nil, {0, 0}, auxiliary.name)
    root.element_params = {"CMFD" .. side .. "Sel" .. selection[1]}
    root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.EICAS}}
    layout.draw(root.name, selection[2], -0.34, 0.87, -0.34 - bottom)
end