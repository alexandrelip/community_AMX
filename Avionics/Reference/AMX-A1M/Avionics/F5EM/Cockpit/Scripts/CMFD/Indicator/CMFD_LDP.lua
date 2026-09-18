-- =====================================================================
-- CMFD FLIR (LDP) page  --  versao simples (normal, como era antes)
-- =====================================================================
-- Pagina principal do FLIR (SUB_PAGE_ID.LDP). Acessivel via botao "FLIR" no
-- menu do CMFD (CMFD_Menu1.lua OSS6, sem gate de variante -- funciona em
-- F-5EM e F-5TH). Layout simples:
--   * Texto de status POD/PWR/L ARM/LASE/CODE/TGT/RANGE/FOV (LDP_STATUS_TEXT
--     do backend ldp.lua) no canto superior esquerdo.
--   * OSS labels padrao (PWR/MODE/SNSR/TRK/BSGT/FOV/Z-/CD+/CD-/L ARM/LASE).
--   * OSS1 = "FLIR" (rotulo da pagina).
--   * OSS6 = "LT" -- submenu que abre a moldura completa A-29 (CMFD_LT.lua).
--     Dispatch OSS6 -> CMFDxFormat = SUB_PAGE_ID.LT em Cockpit/Scripts/CMFD/
--     Device/ldp.lua (SetCommandLDP).
-- =====================================================================
dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber = get_param_handle("CMFDNumber")
local CMFDNu     = CMFDNumber:get()
local CMFD_BR    = "CMFD" .. tostring(CMFDNu) .. "_BRIGHT"

local page_root = create_page_root()
page_root.element_params = {"CMFD" .. CMFDNu .. "Format"}
page_root.controllers    = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.LDP}}

-- OSS labels. FULL_BASE owns the page title at OSS1; OSS6 opens LT.
addOSSText(2,  "PWR")
addOSSText(3,  "MODE")
addOSSText(4,  "SNSR")
addOSSText(5,  "TRK")
addOSSText(6,  "LT")     -- [SUBMENU] abre CMFD_LT.lua (moldura A-29 completa)
addOSSText(7,  "BSGT")
addOSSText(10, "FOV")
addOSSText(11, "Z-")
addOSSText(13, "CD+")
addOSSText(14, "CD-")
addOSSText(25, "L ARM")
addOSSText(26, "LASE")

-- Status text: centralizado (pedido do usuario).
local ldp_status = CreateElement "ceStringPoly"
ldp_status.material       = CMFD_FONT_DEF
ldp_status.stringdefs     = CMFD_STRINGDEFS_DEF_X08
ldp_status.init_pos       = {0.0, 0.08}
ldp_status.alignment      = "CenterCenter"
ldp_status.value          = ""
ldp_status.formats        = {"%s"}
ldp_status.element_params = {CMFD_BR, "LDP_STATUS_TEXT"}
ldp_status.controllers    = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
ldp_status.parent_element = page_root.name
AddElementObject(ldp_status)
ldp_status = nil
