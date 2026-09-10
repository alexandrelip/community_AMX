livery = {
	{"glassAMX",	DIFFUSE			,	"amx_glass", true};
	{"glassAMX",	NORMAL_MAP			,	"amx_glass_nm", true};
	{"glassAMX", ROUGHNESS_METALLIC ,	"amx_glass_RoughMet",true};

	{"CAP01",	DIFFUSE			,	"cappilot01", true};
	{"CAP01",	NORMAL_MAP			,	"cappilot01_nm", true};
	{"CAP01", ROUGHNESS_METALLIC ,	"capPilot01_RoughMet",true};

	{"MascM",	DIFFUSE			,	"capmasks", true};
	{"MascM",	NORMAL_MAP			,	"capmasks_nm", true};
	{"MascM", ROUGHNESS_METALLIC ,	"capmasks_RoughMet",true};

	{"AMX_FUSE02",	DIFFUSE			,	"amx_fuse_02", true};
	{"AMX_FUSE02",	NORMAL_MAP			,	"amx_fuse_02_nm", true};
	{"AMX_FUSE02", ROUGHNESS_METALLIC ,	"amx_fuse_02_RoughMet",true};

	{"AMX_FUSE01",	DIFFUSE			,	"amx_fuse_01", true};
	{"AMX_FUSE01",	NORMAL_MAP			,	"amx_fuse_01_nm", true};
	{"AMX_FUSE01", ROUGHNESS_METALLIC ,	"amx_fuse_01_RoughMet",true};

	{"13 - Default",	DIFFUSE			,	"amx_04", true};

	{"AT27_PILOT",	DIFFUSE			,	"pilot_al", true};
	{"AT27_PILOT",	NORMAL_MAP			,	"pilot_al_nm", true};
	{"AT27_PILOT",	ROUGHNESS_METALLIC			,	"pilot_al_RoughMet", true};

	{"07 - Default",	DIFFUSE			,	"amx_parts", true};

	{"Helmet_glass",	DIFFUSE			,	"cap_viseira", true};
	{"Helmet_glass",	ROUGHNESS_METALLIC			,	"cap_viseira_RoughMet", true};

	{"AT27SEAT",	DIFFUSE			,	"at-27_seat", true};
	{"AT27SEAT",	NORMAL_MAP			,	"at-27_seat_nm", true};
	{"AT27SEAT",	ROUGHNESS_METALLIC			,	"at-27_seat_RoughMet", true};

	{"02 - Default",	DIFFUSE			,	"amx_02", true};

	{"AMX_COCKPIT",	DIFFUSE			,	"amx_cockpit", true};
	{"AMX_COCKPIT",	NORMAL_MAP			,	"amx_cockpit_nm", true};
	{"AMX_COCKPIT",	ROUGHNESS_METALLIC			,	"amx_cockpit_RoughMet", true};

	{"08 - Default",	DIFFUSE			,	"amx_01", true};

	{"AMX_parts",	DIFFUSE			,	"amx_parts", true};
	{"AMX_parts",	NORMAL_MAP			,	"amx_parts_nm", true};
	{"AMX_parts",	ROUGHNESS_METALLIC			,	"amx_parts_RoughMet", true};
	

	{"CAP02",	DIFFUSE			,	"cappilot02", true};
	{"CAP02",	NORMAL_MAP			,	"cappilot02_nm", true};
	{"CAP02",	ROUGHNESS_METALLIC			,	"cappilot02_RoughMet", true};

	{"WingAMX",	DIFFUSE			,	"amx_wings", true};
	{"WingAMX",	NORMAL_MAP			,	"amx_wings_nm", true};
	{"WingAMX",	ROUGHNESS_METALLIC			,	"amx_wings_RoughMet", true};

	{"AT27_PILOT",	DIFFUSE			,	"pilot_al", true};
	{"AT27_PILOT",	NORMAL_MAP			,	"pilot_al_nm", true};
	{"AT27_PILOT",	ROUGHNESS_METALLIC			,	"pilot_al_RoughMet", true};
}

name = "A-1A 5540, 1°/10° Grupo de Aviação, 2005"
countries = {}
custom_args =
{
	[810] = 0, -- Pilot helmet
	[811] = 0, -- Helmet visor 0-close, 1-open
	[812] = 0, -- 0: colete, 1: no colete

	[814] = 0, -- Pilot helmet
	[815] = 1, -- Helmet visor 0-close, 1-open
	[816] = 0, -- 0: colete, 1: no colete
	
	[998] = 0, -- Flares: 1, close flares: 0
	[999] = 0, -- AMX-T: 1, AMX-A: 0
	[1000] = 0.5, -- noze02: 0.9, noze01: 0.5, MIKE: 0
}
