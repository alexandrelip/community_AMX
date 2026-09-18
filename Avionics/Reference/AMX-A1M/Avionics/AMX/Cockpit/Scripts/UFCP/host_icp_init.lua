dofile(LockOn_Options.common_script_path .. "devices_defs.lua")
indicator_type = indicator_types.COMMON
purposes = {render_purpose.GENERAL}
page_subsets = {[1] = LockOn_Options.script_path .. "UFCP/host_icp_page.lua"}
pages = {[1] = {1}}
init_pageID = 1