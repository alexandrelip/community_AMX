dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.HMD}}

local object

object = addOSSBinaryOption(2, "ON", "OFF", "HMD_ON")
object = addOSSBinaryBoxOption(6, "DOI", "HMD_DOI")
object = addOSSText(7, "HEAD\nSCL") -- object = addOSSBinaryBoxOption(7, "HEAD\nSCL", "HMD_HEAD_SCL")
object = addOSSText(8, "MSL\nSCL") -- object = addOSSBinaryBoxOption(8, "MSL\nSCL", "HMD_MSL_SCL")
object = addOSSBinaryBoxOption(9, "STEER\nCUE", "HMD_STEER_CUE")
object = addOSSBinaryBoxOption(10, "FYT\nIAP", "HMD_FYT_IAP")
object = addOSSBinaryBoxOption(24, "FWD\nDCLT\nCNTL", "HMD_FWD_DCLT_CNTL")
object = addOSSBinaryBoxOption(25, "A/A\nA/G\nTDBOX", "HMD_AA_AG_TDBOX")
object = addOSSBinaryBoxOption(26, "TLL", "HMD_TLL")
object = addOSSBinaryBoxOption(27, "HDG\nVEL\nALT", "HMD_HDG_VEL_ALT")
object = addOSSBinaryBoxOption(28, "WNDWS", "HMD_WNDWS")

