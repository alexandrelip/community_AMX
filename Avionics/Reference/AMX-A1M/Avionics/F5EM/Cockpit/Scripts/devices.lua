local count = 0
local function counter()
	count = count + 1
	return count
end
-------DEVICE ID-------
devices = {}
-- do not changed following sequence for sim
devices["FM_PROXY"]					= counter()--1
devices["CONTROL_INTERFACE"]		= counter()--2
devices["ELEC_INTERFACE"]			= counter()--3
devices["FUEL_INTERFACE"]			= counter()--4
devices["HYDRO_INTERFACE"]			= counter()--5
devices["ENGINE_INTERFACE"]			= counter()--6
devices["GEAR_INTERFACE"]			= counter()--7
devices["OXYGEN_INTERFACE"]			= counter()--8
devices["ECS_INTERFACE"]			= counter()--9
devices["CPT_MECH"]					= counter()--10
devices["EXTLIGHTS_SYSTEM"]			= counter()--11
devices["INTLIGHTS_SYSTEM"]			= counter()--12
-- devices["CMDS"]						= counter()--13		-- Counter Measures Dispensing System
devices["JETTISON_SYSTEM"]			= counter()--14
devices["AHRS"]						= counter()--16		-- Attitude and Heading Reference System
-- devices["AN_APQ159"]				= counter()--17		-- AN/APQ-159 Radar
-- devices["RWR_IC"]					= counter()--19		-- RWR Indicator Control (IC)
devices["SIGHT_CAMERA"]				= counter()--21
-- Radio --------------------------------
devices["IFF"]						= counter()--22
devices["UHF_RADIO"]				= counter()--23
devices["INTERCOM"]					= counter()--24
devices["TACAN"]					= counter()--25
-- Instruments --------------------------
devices["AOA_INDICATOR"]			= counter()--26
devices["ACCELEROMETER"]			= counter()--27
devices["IAS_MACH_INDICATOR"]		= counter()--28
devices["VARIOMETER"]				= counter()--29
devices["AOA_INDEXER"]				= counter()--30
devices["AAU34"]     				= counter()--31		-- Altimeter AAU-34/A
devices["AI_ARU20"]    				= counter()--32		-- Attitude Indicator ARU-20/A
devices["HSI"]     					= counter()--33		-- Horizontal Situation Indicator
devices["SAI"]						= counter()--34
devices["CLOCK"]					= counter()--35
devices["STANDBY_COMPASS"]			= counter()--36
--
devices["MACROS"]					= counter()--37
devices["AIHelper"]					= counter()--38
devices["KNEEBOARD"] 				= counter()--39
devices["ARCADE"]					= counter()--40
--
devices["TACAN_CTRL_PANEL"]			= counter()--41
--
devices["HEARING_SENS"]				= counter()--42

--
devices["CMFD"]          			= counter()
devices["EFI"]          			= counter()
devices["UFCP"]          			= counter()
devices["HUD"]           			= counter()
devices["HMD"]           			= counter()
devices["AVIONICS"]           		= counter()
devices["ELECTRIC_SYSTEM"]        	= counter()
devices["ALARM"]        			= counter()
devices["RWR"]        				= counter()
devices["RDR"]        				= counter()
devices["SES"]        				= counter()
devices["UHF_RADIO1"]				= counter()

devices["WEAPON_SYSTEM"]           	= counter()
devices["STORMSCOPE"]				= counter()
devices["OBOGS_SIM"]				= counter()	-- [Fase R3.8] OBOGS Lua supplement
devices["COMSEC"]					= counter()	-- [Fase R3.9] KIV-77 equivalent
devices["EW_CONSUMER"]				= counter()	-- [Fase EW-1] EW bridge cockpit consumer
devices["FLIR"]						= counter()	-- [FLIR] AN/AAQ-28 LITENING targeting pod (LR::avSimplestFLIR, real designator)
devices["LINK_BR2_RX_CONSUMER"]		= counter()	-- Export-to-cockpit Link-BR2 relay consumer

devices["CMDS"] 					= devices["WEAPON_SYSTEM"]
devices["WEAPONS_CONTROL"]			= devices["WEAPON_SYSTEM"]
devices["AN_APQ159"]				= devices["RDR"]
devices["RWR_IC"]					= devices["RDR"]