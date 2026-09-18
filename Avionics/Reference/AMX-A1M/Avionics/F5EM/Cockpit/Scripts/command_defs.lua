-- Commands : not intended for end-user editing
Keys =
{
	iCommandPlaneWheelBrakeOn		= 74,
	iCommandPlaneWheelBrakeOff		= 75,
	
	iCommandPlaneThrustCommon		= 2004,

}

start_command   = 3000
local count = 0
local function counter()
	count = count + 1
	return count
end

count = start_command
device_commands = {}

count = start_command
control_commands =
{
	YawDamper			= counter();
	PitchDamper			= counter();
	RudderTrim			= counter();
	PitchDamperCutoff	= counter();
	FlapLever			= counter();
	FlapSwitch			= counter();
	SpdBrk				= counter();
	FingerliftLeft		= counter();
	FingerliftRight		= counter();
	TrimmerUp			= counter();
	TrimmerDown			= counter();
	TrimmerLeft			= counter();
	TrimmerRight		= counter();
	RudderPedalAdjust	= counter();
	-- input commands
	YawDamper_EXT			= counter();
	PitchDamper_EXT			= counter();
	RudderTrim_EXT			= counter();
	RudderTrim_AXIS			= counter();
	FlapSwitch_EXT			= counter();
	AileronLimitOff_EXT		= counter();
	ThrottleRange_EXT		= counter();
	RudderPedalAdjust_EXT	= counter();
}

count = start_command
fuel_commands =
{
	FuelShutoff_Left			= counter();
	FuelShutoff_Right			= counter();
	ExtFuelTransfer_Pylon		= counter();
	ExtFuelTransfer_Cl			= counter();
	FuelCrossfeed				= counter();
	FuelAutoLeft				= counter();
	FuelAutoRight				= counter();
	FuelBoostPump_Left			= counter();
	FuelBoostPump_Right			= counter();
	FuelShutoffCover_Left		= counter();
	FuelShutoffCover_Right		= counter();
	--input commands
	FuelShutoff_Left_EXT		= counter();
	FuelShutoff_Right_EXT		= counter();
	ExtFuelTransfer_Pylon_EXT	= counter();
	ExtFuelTransfer_Cl_EXT		= counter();
	FuelCrossfeed_EXT			= counter();
	FuelAutobalance_EXT			= counter();
	FuelBoostPump_Left_EXT		= counter();
	FuelBoostPump_Right_EXT		= counter();
	FuelShutoffCover_Left_EXT	= counter();
	FuelShutoffCover_Right_EXT	= counter();
}

count = start_command
engine_commands =
{
	EngineStartLeft		= counter();
	EngineStartRight	= counter();
	EngineAntiIce		= counter();
	-- input commands
	EngineAntiIce_EXT	= counter();
}

count = start_command
gear_commands =
{
	GearLever		= counter();
	AltRelease		= counter();
	DownOverride	= counter();
	NoseSteering	= counter();
	AltReset		= counter();
	NoseStrut		= counter();
	WarningSilence	= counter();
	LeftLGLampTest	= counter();
	NoseLGLampTest	= counter();
	RightLGLampTest	= counter();
	LeftLGLampDim	= counter();
	NoseLGLampDim	= counter();
	RightLGLampDim	= counter();
	Hook			= counter();
	-- input commands
	GearLever_EXT		= counter();
	AltReset_EXT		= counter();
	NoseStrut_EXT		= counter();
	LeftLGLampDim_EXT	= counter();
	NoseLGLampDim_EXT	= counter();
	RightLGLampDim_EXT	= counter();
	LeftLGLampDim_AXIS	= counter();
	NoseLGLampDim_AXIS	= counter();
	RightLGLampDim_AXIS	= counter();
	NoseSteering_EXT	= counter();
}

count = start_command
oxygen_commands =
{
	SupplyLever		= counter();
	DiluterLever	= counter();
	EmergLever		= counter();
	EmergLeverTest	= counter();
	-- input commands	
	SupplyLever_EXT		= counter();
	DiluterLever_EXT	= counter();
	EmergLever_EXT		= counter();
	EmergLeverTest_EXT	= counter();
}

count = start_command
ecs_commands =
{
	CabinPress				= counter();
	CabinPressCover			= counter();
	CabinTempSw				= counter();
	CabinTempKnob			= counter();
	CanopyDefog				= counter();
	CockpitAirInletHor		= counter();
	CockpitAirInletVer		= counter();
	CockpitAirInletL1Hor	= counter();
	CockpitAirInletL1Ver	= counter();
	CockpitAirInletL1Valve	= counter();
	CockpitAirInletL2Hor	= counter();
	CockpitAirInletL2Ver	= counter();
	CockpitAirInletL2Valve	= counter();
	-- input commands
	CabinPress_EXT				= counter();
	CabinPressCover_EXT			= counter();
	CabinTempSw_EXT				= counter();
	CabinTempKnob_EXT			= counter();
	CabinTempKnob_AXIS			= counter();
	CanopyDefog_EXT				= counter();
	CanopyDefog_AXIS			= counter();
	CockpitAirInletHor_EXT		= counter();
	CockpitAirInletVer_EXT		= counter();
	CockpitAirInletL1Hor_EXT	= counter();
	CockpitAirInletL1Ver_EXT	= counter();
	CockpitAirInletL1Valve_EXT	= counter();
	CockpitAirInletL2Hor_EXT	= counter();
	CockpitAirInletL2Ver_EXT	= counter();
	CockpitAirInletL2Valve_EXT	= counter();
}

count = start_command
cpt_commands =
{
	CanopyLever					= counter();
	DragChuteHandle				= counter();
	SeatAdjustment_Up			= counter();
	SeatAdjustment_Dn			= counter();
	CanopyJettisonTHandle		= counter();
	--
	CanopyJettisonTHandle_EXT	= counter();
}

count = start_command
extlights_commands =
{
	NavKnob			= counter();
	Formation		= counter();
	Beacon			= counter();
	LdgTaxi			= counter();
	-- input commands
	NavKnob_EXT		= counter();
	NavKnob_AXIS	= counter();
	Formation_EXT	= counter();
	Formation_AXIS	= counter();
	Beacon_EXT		= counter();
	LdgTaxi_EXT		= counter();
}

count = start_command
intlights_commands = 
{
	PnlLt_button		= counter();
	Compass_switch		= counter();
	Flood_knob			= counter();
	FltInstr_knob		= counter();
	EngInstr_knob		= counter();
	Console_knob		= counter();
	ArmtPanel_knob		= counter();
	-- Caution lights command
	WarningTest			= counter();
	Brt					= counter();
	Dim					= counter();
	MasterReset			= counter();
	--input commands
	PnlLt_button_EXT	= counter();
	Compass_switch_EXT	= counter();
	Flood_knob_EXT		= counter();
	Flood_knob_AXIS		= counter();
	FltInstr_knob_EXT	= counter();
	FltInstr_knob_AXIS	= counter();
	EngInstr_knob_EXT	= counter();
	EngInstr_knob_AXIS	= counter();
	Console_knob_EXT	= counter();
	Console_knob_AXIS	= counter();
	ArmtPanel_knob_EXT	= counter();
	ArmtPanel_knob_AXIS	= counter();
}

-- AN/ALE-40V
count = start_command
cmds_commands =
{
	ChaffMode				= counter();
	FlareMode				= counter();
	FlareJettison_Cover		= counter();
	FlareJettison			= counter();
	ChaffCounterReset		= counter();
	FlareCounterReset		= counter();
	FlChButton				= counter();
	-- input commands
	ChaffMode_EXT			= counter();
	FlareMode_EXT			= counter();
	FlareJettison_Cover_EXT	= counter();
	FlareJettison_EXT		= counter();
	-- CMDS adjustment
	ChangeChaffBurst		= counter();
	ChangeChaffSalvo		= counter();
	ChangeChaffBurstIntv	= counter();
	ChangeChaffSalvoIntv	= counter();
	ChangeFlareBurst		= counter();
	ChangeFlareBurstIntv	= counter();
}

count = start_command
jettison_commands = 
{
	EmerAllJettCap		= counter();
	EmerAllJett			= counter();
	SelectJettSw		= counter();
	SelectJettBtn		= counter();
	--input commands
--	EmerAllJettCap_EXT	= counter();
	SelectJettSw_EXT	= counter();
}

count = start_command
weapons_commands = 
{
	WingtipLeft_Select		= counter();
	OutbdLeft_Select		= counter();
	InbdLeft_Select			= counter();
	Center_Select			= counter();
	InbdRight_Select		= counter();
	OutbdRight_Select		= counter();
	WingtipRight_Select		= counter();
	--
	Interval				= counter();
	BombsArm				= counter();
	GunsMslCamrCover		= counter();
	GunsMslCamr				= counter();
	ExtStoresSelect			= counter();
	DogfightSearchResume	= counter();
	MslUncage				= counter();
	MissileVolume			= counter();
	TrgFirstDetent			= counter();
	TrgSecondDetent			= counter();
	WeaponReleaseBtn		= counter();
	--input commands
	WingtipLeft_Select_EXT	= counter();
	OutbdLeft_Select_EXT	= counter();
	InbdLeft_Select_EXT		= counter();
	Center_Select_EXT		= counter();
	InbdRight_Select_EXT	= counter();
	OutbdRight_Select_EXT	= counter();
	WingtipRight_Select_EXT	= counter();
	--
	Interval_EXT			= counter();
	BombsArm_EXT			= counter();
	GunsMslCamrCover_EXT	= counter();
	GunsMslCamr_EXT			= counter();
	ExtStoresSelect_EXT		= counter();
	MissileVolume_EXT		= counter();
	MissileVolume_AXIS		= counter();
	-- Weapon adjustment
	ChangeHighCapRate		= counter();
	ChangeLowCapRate		= counter();
	ChangeLaserCode100		= counter();
	ChangeLaserCode10		= counter();
	ChangeLaserCode1		= counter();
}

count = start_command
ahrs_commands =
{
	AHRS_CMD_FAST_ERECT				= counter();
	AHRS_CMD_COMPASS				= counter();
	AHRS_CMD_COMPASS_FAST_SLAVE		= counter();
	AHRS_NAV_MODE					= counter();
	-- input commands
	AHRS_CMD_COMPASS_EXT			= counter();
	AHRS_CMD_COMPASS_FAST_SLAVE_EXT	= counter();
	AHRS_NAV_MODE_EXT				= counter();
}

count = start_command
apq159_commands =
{
	ElevAntennaTilt			= counter();
	TDCAzimuth				= counter();
	TDCRange				= counter();
	RangeSelector			= counter();
	ModeSelector			= counter();
	AcqButton				= counter();
	ScaleKnob				= counter();
	BrightKnob				= counter();
	PerKnob					= counter();
	VideoKnob				= counter();
	CursorKnob				= counter();
	PitchKnob				= counter();
	-- input commands
	RangeSelector_EXT		= counter();
	ModeSelector_EXT		= counter();
	ScaleKnob_EXT			= counter();
	ScaleKnob_AXIS			= counter();
	BrightKnob_EXT			= counter();
	BrightKnob_AXIS			= counter();
	PerKnob_EXT				= counter();
	PerKnob_AXIS			= counter();
	VideoKnob_EXT			= counter();
	VideoKnob_AXIS			= counter();
	CursorKnob_EXT			= counter();
	CursorKnob_AXIS			= counter();
	PitchKnob_EXT			= counter();
	PitchKnob_AXIS			= counter();
}

count = start_command
asg31_commands =
{
	ModeSelector			= counter();
	RetDepression			= counter();
	RetIntensity			= counter();
	SightBit				= counter();
	DgMode					= counter();
	ResumeSearch			= counter();
	SightCage				= counter();
	-- input commands
	ModeSelector_EXT		= counter();
	RetDepression_EXT		= counter();
	RetDepression_AXIS		= counter();
	RetIntensity_EXT		= counter();
	RetIntensity_AXIS		= counter();
	SightBit_EXT			= counter();
}

count = start_command
ic_commands =
{
	Mode				= counter();
	Search				= counter();
	Handoff				= counter();
	Altitude			= counter();
	Btn_T				= counter();
	SysTest				= counter();
	UnknownShip			= counter();
	Power				= counter();
	Launch				= counter();	-- not used
	ActPwr				= counter();	-- not used
	Brightness			= counter();
	Volume				= counter();
	-- input commands
	Brightness_EXT		= counter();
	Brightness_AXIS		= counter();
	Volume_EXT			= counter();
	Volume_AXIS			= counter();
}

count = start_command
alr87_commands = 
{
	Brightness		= counter();
	-- input commands
	Brightness_AXIS	= counter();
	Brightness_EXT	= counter();
}

-- Instruments --------------------------
-- Altimeter AAU-34/A
count = start_command
aau34_commands =
{
	AAU34_ClkCmd_PNEU			= counter();
	AAU34_ClkCmd_ELECT			= counter();
	AAU34_ClkCmd_ZeroSetting	= counter();
}

-- Attitude Indicator ARU-20
count = start_command
aru20_commands =
{
	AI_PITCH_TRIM	= counter();
	-- input commands
	AI_PITCH_TRIM_AXIS	= counter();
}

-- Horizontal Situation Indicator
count = start_command
hsi_commands =
{
	HSI_heading		= counter();
	HSI_course		= counter();
}

-- Standby Attitude Indicator
count = start_command
sai_commands =
{
	CMD_SAI_CAGE				= counter();
	CMD_SAI_PITCH_ZERO_SHIFT	= counter();
	-- input commands
	CMD_SAI_PITCH_AXIS			= counter();
}

-- Clock
count = start_command
clock_commands =
{
	CLOCK_left_lev_up		= counter();
	CLOCK_left_lev_rotate	= counter();
	CLOCK_right_lev_down	= counter();
}

-- Sight Camera
count = start_command
camera_commands =
{
	SelectFPS		= counter();
	Lens_fStop		= counter();
	Overrun			= counter();
	CameraRun		= counter();
	LoadLock		= counter();
	--
	SelectFPS_EXT	= counter();
	Lens_fStop_EXT	= counter();
	Overrun_EXT		= counter();
	CameraRun_EXT	= counter();
}

-- Electric Interface
count = start_command
electric_commands =
{
	BatterySw				= counter();
	LeftGeneratorSw			= counter();
	LeftGenResetSw			= counter();
	RightGeneratorSw		= counter();
	RightGenResetSw			= counter();
	PitotHeater				= counter();
	GageTest				= counter();
	QtyCheck				= counter();
	-- input commands
	BatterySw_EXT			= counter();
	LeftGeneratorSw_EXT		= counter();
	LeftGenResetSw_EXT		= counter();
	RightGeneratorSw_EXT	= counter();
	RightGenResetSw_EXT		= counter();
	PitotHeater_EXT			= counter();
	ES_Switch_MAX			= counter();
	-- circuit-breakers begin
	-- CB Front Panel
	CB_WPN_PWR_LEFT_OUTBD	= counter();
	CB_WPN_PWR_LEFT_INBD	= counter();
	CB_WPN_PWR_CENTER_LINE	= counter();
	CB_WPN_PWR_RIGHT_INBD	= counter();
	CB_WPN_PWR_RIGHT_OUTBD	= counter();
	CB_WPN_ARMING			= counter();
	CB_WPN_RELEASE			= counter();
	CB_WPN_MODE_SEL			= counter();
	CB_LEFT_AIM9_CONT		= counter();
	CB_RIGHT_AIM9_CONT		= counter();

	CB_JETTISON_CONTROL		= counter();
	CB_EMERG_ALL_JETTISON	= counter();
	
	-- Right CB panel
	CB_PITOT_HEATER					= counter();
	CB_R_OIL_HYD_IND_FUEL_QTY_SEC	= counter();
	CB_CABIN_AIR_VALVES				= counter();
	CB_INST_LIGHTS					= counter();
	CB_R_ENG_AUX_DOOR				= counter();
	CB_BLANKING_ELEC_UNIT			= counter();
	CB_CAUTION_WARN_DIM				= counter();
	CB_OXY_QTY_CANOPY_SEAL			= counter();
	CB_LDG_TAXI_LAMP_PWR			= counter();

	-- Left CB panel - Armament
	CB_LEFT_AIM9_POWER		= counter();
	CB_RIGHT_AIM9_POWER		= counter();
	CB_LEFT_GUN_FIRING		= counter();
	CB_RIGHT_GUN_FIRING		= counter();

	-- Left CB panel
	CB_26_AC_POWER			= counter();
	CB_ATTD_HDG_REF_SYS_A	= counter();
	CB_CADC					= counter();
	CB_ENG_IGN_INST_HYD_IND	= counter();
	CB_TRIM_CONTROL			= counter();
	CB_ATTD_HDG_REF_SYS_B	= counter();
	CB_TOTAL_TEMP_PROBE_HTR	= counter();
	CB_L_ENG_AUX_DOOR		= counter();
	CB_CABIN_COND			= counter();
	CB_FUEL_QTY_PRIMARY		= counter();
	CB_ATTD_HDG_REF_SYS_C	= counter();
	CB_TACAN				= counter();

	-- Left CB panel - 28 Volt DC
	CB_PYLON_TANK_FUEL_CONT			= counter();
	CB_L_BOOST_CL_TANK_FUEL_CONT	= counter();
	CB_IGN_INVERTER_POWER			= counter();
	CB_L_ENG_START_AB_CONT			= counter();
	CB_R_ENG_START_AB_CONT			= counter();
	CB_UHF_COMMAND_RADIO			= counter();
	CB_LEFT_LE_FLAP_CONT			= counter();
	CB_RIGHT_LE_FLAP_CONT			= counter();
	CB_LEFT_TE_FLAP_CONT			= counter();
	CB_RIGHT_TE_FLAP_CONT			= counter();

	-- Behind seat - Left
	CB_CONSOLE_LIGHTS		= counter();
	CB_FLOOD_LT_PRI_TS_LT	= counter();
	CB_AOA					= counter();
	CB_MODE_4_COMPUTER		= counter();
	CB_NAV_FORM_LIGHTS		= counter();
	CB_UHF_DF				= counter();
	CB_STABILITY_AUGMENTER	= counter();
	CB_OUTBD_SPARE_A		= counter();
	CB_OUTBD_SPARE_B		= counter();
	CB_OUTBD_SPARE_C		= counter();
	CB_INBD_SPARE_A			= counter();
	CB_INBD_SPARE_B			= counter();
	CB_INBD_SPARE_C			= counter();
	CB_LEAD_CMPTR_OPTICAL_SIGHT_A	= counter();
	CB_LEAD_CMPTR_OPTICAL_SIGHT_B	= counter();
	CB_LEAD_CMPTR_OPTICAL_SIGHT_C	= counter();
	CB_RADAR_A						= counter();
	CB_RADAR_B						= counter();
	CB_RADAR_C						= counter();
	CB_L_FUEL_BOOST_PUMP_A			= counter();
	CB_L_FUEL_BOOST_PUMP_B			= counter();
	CB_L_FUEL_BOOST_PUMP_C			= counter();
	CB_XMFR_RECT_NO1_TEST_RECP_A	= counter();
	CB_XMFR_RECT_NO1_TEST_RECP_B	= counter();
	CB_XMFR_RECT_NO1_TEST_RECP_C	= counter();
	CB_LEFT_LE_FLAP_ACTUATOR_A		= counter();
	CB_LEFT_LE_FLAP_ACTUATOR_B		= counter();
	CB_LEFT_LE_FLAP_ACTUATOR_C		= counter();
	CB_RIGHT_LE_FLAP_ACTUATOR_A		= counter();
	CB_RIGHT_LE_FLAP_ACTUATOR_B		= counter();
	CB_RIGHT_LE_FLAP_ACTUATOR_C		= counter();

	-- Behind seat - Right
	CB_LEFT_TE_FLAP_ACTUATOR_A		= counter();
	CB_LEFT_TE_FLAP_ACTUATOR_B		= counter();
	CB_LEFT_TE_FLAP_ACTUATOR_C		= counter();
	CB_RIGHT_TE_FLAP_ACTUATOR_A		= counter();
	CB_RIGHT_TE_FLAP_ACTUATOR_B		= counter();
	CB_RIGHT_TE_FLAP_ACTUATOR_C		= counter();
	CB_XMFR_RECT_NO2_TEST_RECP_A	= counter();
	CB_XMFR_RECT_NO2_TEST_RECP_B	= counter();
	CB_XMFR_RECT_NO2_TEST_RECP_C	= counter();
	CB_XMFR_RECT_NO3_A			= counter();
	CB_XMFR_RECT_NO3_B			= counter();
	CB_XMFR_RECT_NO3_C			= counter();
	CB_R_FUEL_BOOST_PUMP_A		= counter();
	CB_R_FUEL_BOOST_PUMP_B		= counter();
	CB_R_FUEL_BOOST_PUMP_C		= counter();
	CB_SIGHT_CAMERA_POWER_A		= counter();
	CB_SIGHT_CAMERA_POWER_B		= counter();
	CB_SIGHT_CAMERA_POWER_C		= counter();
	CB_RIGHT_EGT_IND			= counter();
	CB_RIGHT_FUEL_FLOW_IND		= counter();
	CB_SEAT_POS_ELEC_TEST		= counter();
	CB_BEACON_LIGHT				= counter();
	CB_RADAR_WARNING			= counter();

	-- Behind seat - Right, low
	CB_L_OIL_HYD_IND		= counter();
	CB_LEFT_EGT_IND			= counter();
	CB_LEFT_FUEL_FLOW_IND	= counter();
	CB_L_FUEL_QTY_ISOLATION	= counter();
	CB_R_FUEL_QTY_ISOLATION	= counter();

	-- Behind seat - Right, 26 Volt AC
	CB_AOA_26V				= counter();
	CB_TRIM_POS_IND			= counter();
	CB_AHRS_INS				= counter();
	CB_HSI					= counter();
	CB_ADF					= counter();

	-- Behind seat - Small
	CB_TAIL_LT_R			= counter();
	CB_TAIL_LT_L			= counter();
	CB_PRIM_LTS_R			= counter();
	CB_PRIM_LTS_L			= counter();
	CB_LWR_FUS_LTS_R		= counter();
	CB_LWR_FUS_LTS_L		= counter();
	-- circuit-breakers end
}

-- [Fase 8.2 -- migracao 2.9] traducao do TODO russo original ("сделать расчет"
-- = "fazer o calculo"): expressao abaixo calcula numero total de comandos de
-- disjuntor (CB_*) subtraindo a base ES_Switch_MAX do ultimo CB criado. Valor
-- atual = 117. Atualizar se novos CBs forem adicionados antes do bloco final.
CB_commands_num = electric_commands.CB_LWR_FUS_LTS_L - electric_commands.ES_Switch_MAX		-- 117



-- [REVERT 2026-07-15] O shift +200 QUEBROU os CMFDs: device_commands.AviMst
-- (Avionics Master, clickabledata PNT_1843) e ligado ao device NATIVO
-- devices.ELEC_INTERFACE (F5E::avElectricInterface_F5) que HARDCODA o id do
-- comando -- igual a DLL do FLIR. Mover a base moveu AviMst -> o master de
-- aviônicos nunca ligava -> CMFD1On/CMFD2On (gated por draw_arg 1843) ficavam
-- 0 -> telas pretas. A colisao CMFD<->FLIR sera resolvida de forma cirurgica
-- (mover SO os botoes CMFD OSS, nao os comandos de devices nativos).
-- [FLIR COLLISION FIX v2 2026-07-15] Move SO os botoes CMFD OSS (avLuaDevice,
-- simbolicos) para 3500+ via counter separado, FORA da faixa flir_commands
-- (3001-3039, HARDCODED na DLL FLIR). UFCP+ (incl. AviMst do device NATIVO
-- ELEC_INTERFACE que HARDCODA ids) mantem valores ORIGINAIS: count pre-setado
-- para +64 => UFCP_COM1 = 3065 como antes. Colisao CMFD<->FLIR some sem mover
-- comandos de devices nativos (foi o que quebrou os CMFDs no shift +200).
count = start_command + 64
local cmfd_count = start_command + 500
local function cmfd_counter() cmfd_count = cmfd_count + 1; return cmfd_count end

device_commands = {
	CMFD1OSS1                 = cmfd_counter(),
	CMFD1OSS2                 = cmfd_counter(),
	CMFD1OSS3                 = cmfd_counter(),
	CMFD1OSS4                = cmfd_counter(),
	CMFD1OSS5                 = cmfd_counter(),
	CMFD1OSS6                 = cmfd_counter(),
	CMFD1OSS7                 = cmfd_counter(),
	CMFD1OSS8                 = cmfd_counter(),
	CMFD1OSS9                 = cmfd_counter(),
	CMFD1OSS10                 = cmfd_counter(),
	CMFD1OSS11                 = cmfd_counter(),
	CMFD1OSS12                 = cmfd_counter(),
	CMFD1OSS13                 = cmfd_counter(),
	CMFD1OSS14                = cmfd_counter(),
	CMFD1OSS15                 = cmfd_counter(),
	CMFD1OSS16                 = cmfd_counter(),
	CMFD1OSS17                 = cmfd_counter(),
	CMFD1OSS18                 = cmfd_counter(),
	CMFD1OSS19                 = cmfd_counter(),
	CMFD1OSS20                 = cmfd_counter(),
	CMFD1OSS21                 = cmfd_counter(),
	CMFD1OSS22                 = cmfd_counter(),
	CMFD1OSS23                 = cmfd_counter(),
	CMFD1OSS24                = cmfd_counter(),
	CMFD1OSS25                 = cmfd_counter(),
	CMFD1OSS26                 = cmfd_counter(),
	CMFD1OSS27                 = cmfd_counter(),
	CMFD1OSS28                 = cmfd_counter(),
	CMFD1ButtonOn                 = cmfd_counter(),
	CMFD1ButtonGain                 = cmfd_counter(),
	CMFD1ButtonSymb                 = cmfd_counter(),
	CMFD1ButtonBright                 = cmfd_counter(),

	CMFD2OSS1                 = cmfd_counter(),
	CMFD2OSS2                 = cmfd_counter(),
	CMFD2OSS3                 = cmfd_counter(),
	CMFD2OSS4                = cmfd_counter(),
	CMFD2OSS5                 = cmfd_counter(),
	CMFD2OSS6                 = cmfd_counter(),
	CMFD2OSS7                 = cmfd_counter(),
	CMFD2OSS8                 = cmfd_counter(),
	CMFD2OSS9                 = cmfd_counter(),
	CMFD2OSS10                 = cmfd_counter(),
	CMFD2OSS11                 = cmfd_counter(),
	CMFD2OSS12                 = cmfd_counter(),
	CMFD2OSS13                 = cmfd_counter(),
	CMFD2OSS14                = cmfd_counter(),
	CMFD2OSS15                 = cmfd_counter(),
	CMFD2OSS16                 = cmfd_counter(),
	CMFD2OSS17                 = cmfd_counter(),
	CMFD2OSS18                 = cmfd_counter(),
	CMFD2OSS19                 = cmfd_counter(),
	CMFD2OSS20                 = cmfd_counter(),
	CMFD2OSS21                 = cmfd_counter(),
	CMFD2OSS22                 = cmfd_counter(),
	CMFD2OSS23                 = cmfd_counter(),
	CMFD2OSS24                = cmfd_counter(),
	CMFD2OSS25                 = cmfd_counter(),
	CMFD2OSS26                 = cmfd_counter(),
	CMFD2OSS27                 = cmfd_counter(),
	CMFD2OSS28                 = cmfd_counter(),
	CMFD2ButtonOn                 = cmfd_counter(),
	CMFD2ButtonGain                 = cmfd_counter(),
	CMFD2ButtonSymb                 = cmfd_counter(),
	CMFD2ButtonBright                 = cmfd_counter(),

	UFCP_COM1                      = counter(),
	UFCP_COM2                      = counter(),
	UFCP_COM3                      = counter(),
	UFCP_NAVAIDS                      = counter(),
	UFCP_A_G                      = counter(),
	UFCP_NAV                      = counter(),
	UFCP_A_A                      = counter(),
	UFCP_BARO_RALT                      = counter(),
	UFCP_IDNT                      = counter(),
	UFCP_1                      = counter(),
	UFCP_2                      = counter(),
	UFCP_3                      = counter(),
	UFCP_4                      = counter(),
	UFCP_5                      = counter(),
	UFCP_6                      = counter(),
	UFCP_7                      = counter(),
	UFCP_8                      = counter(),
	UFCP_9                      = counter(),
	UFCP_0                      = counter(),
	UFCP_UP                      = counter(),
	UFCP_DOWN                      = counter(),
	UFCP_CLR                      = counter(),
	UFCP_ENTR                      = counter(),
	UFCP_CZ                      = counter(),
	UFCP_AIRSPD                      = counter(),
	UFCP_WARNRST                      = counter(),
	UFCP_DAY_NIGHT                      = counter(),
	UFCP_RALT                      = counter(),
	UFCP_DVR                      = counter(),
	UFCP_EGI                      = counter(),
	UFCP_UFC                      = counter(),
	UFCP_HUD_TEST                      = counter(),
	UFCP_SBS_ON                      = counter(),
	UFCP_HUD_BRIGHT                      = counter(),
	UFCP_SBS_ADJUST                      = counter(),
	UFCP_JOY_RIGHT                      = counter(),
	UFCP_JOY_LEFT                      = counter(),
	UFCP_JOY_UP                      = counter(),
	UFCP_JOY_DOWN                      = counter(),
	UFCP_VV                      = counter(),
	UFCP_HMD_BRIGHT					= counter(),

	Mass               				= counter(),
    LateArm                   		= counter(),
    Salvo                   		= counter(),

	WPN_SELECT_STO                          = counter(),
    WPN_AA_STEP                          = counter(),
    WPN_AA_SIGHT_STEP                    = counter(),
    WPN_AA_RR_SRC_STEP                    = counter(),
    WPN_AA_SLV_SRC_STEP                    = counter(),
    WPN_AA_COOL_STEP                    = counter(),
    WPN_AA_SCAN_STEP                    = counter(),
    WPN_AA_LIMIT_STEP                    = counter(),
	WPN_CAGE_UNCAGE                    = counter(),

    WPN_AG_STEP                          = counter(),

    STICK_WEAPON_RELEASE                    = counter(),
    STICK_TRIGGER_2ND_DETENT                    = counter(),
    STICK_PADDLE                    = counter(),
    NAV_INC_FYT                    = counter(),
    NAV_DEC_FYT                    = counter(),
    NAV_SET_FYT                    = counter(),
	
	STICK_WEAPON_RELEASE_OFF                = counter(),
    WPN_AG_LAUNCH_OP_STEP                    = counter(),

    AviMdp1                     = counter(),
    AviMdp2                     = counter(),
    AviMst                     = counter(),
    AviSms                     = counter(),
    AviVuhf                     = counter(),
    ALERTS_SET_WARNING                      = counter(),
    ALERTS_RESET_WARNING                      = counter(),
    ALERTS_ACK_WARNING                      = counter(),
    ALERTS_ACK_WARNINGS                      = counter(),
    
    ALERTS_SET_CAUTION                      = counter(),
    ALERTS_RESET_CAUTION                      = counter(),
    ALERTS_ACK_CAUTION                      = counter(),
    ALERTS_ACK_CAUTIONS                      = counter(),

    ALERTS_SET_ADVICE                      = counter(),
    ALERTS_RESET_ADVICE                      = counter(),
    
    WARNING_PRESS                      = counter(),
    CAUTION_PRESS                      = counter(),
    L_THROTTLE                      = counter(),
    R_THROTTLE                      = counter(),
	RWR								= counter(),
	AIR_REFUEL								= counter(),
	MSL_VOLUME								= counter(),
	RWR_VOLUME								= counter(),
	MARKER_VOLUME								= counter(),
	COM2_VOLUME								= counter(),
	COM3_VOLUME								= counter(),
	RDR_POWER								= counter(),
	FLIR_POWER_TOGGLE					= counter(),
	RDR_ACQ									= counter(),
	-- [Probe IFR] sonda de reabastecimento: +1 estende, -1 recolhe, 0 alterna.
	-- SEMPRE adicionar novos comandos NO FIM da tabela: os IDs sao sequenciais
	-- e inserir no meio invalidaria os binds ja salvos pelos usuarios.
	IFR_PROBE								= counter(),
	IFF_INTERROGATE							= counter(),
	RDR_TARGET_CYCLE						= counter(),
	RDR_SOFT_DESIGNATE						= counter(),
	RDR_EXT_TOGGLE						= counter(),
	WPN_SJ_RELEASE							= counter(),
	UFCP_XPDR_POWER						= counter(),
	ATDL_POWER							= counter(),

}
count = start_command
for cmd_num = 1,70 do
	device_commands["Button_"..cmd_num] = counter()
end

count = 10000

Keys =
{
	iCommandPlaneWheelBrakeOn		= 74,
	iCommandPlaneWheelBrakeOff		= 75,
	
	iCommandPlaneThrustCommon		= 2004,

    ---- A-29B
    EngineStart                     = counter(),
    EngineStartCenter               = counter(),
    EngineStartInterrupt            = counter(),

    Engine_Stop                     = counter(),

	PlaneFireOn		                = counter(), -- replaces iCommandPlaneFire
	PlaneFireOff	                = counter(), -- replaces iCommandPlaneFireOff
    PickleOn                        = counter(), -- replaces iCommandPlanePickleOn
    PickleOff                       = counter(), -- replaces iCommandPlanePickleOff


    -- Stick
    StickStep		    	 = counter(),
    StickDesignate        	     = counter(),
    StickUndesignate      	     = counter(),
    MasterModeSw      	     = counter(),
    APDisengage      	     = counter(),
    APOvrd      	     = counter(),
    Call      	     = counter(),
    Trigger      	     = counter(),
    WeaponRelease			    	 = counter(),
    DisplayMngt        	     = counter(),
    JettisonWeapons         =   counter(),

    -- Throttle
    GunSelDist        	     = counter(),
    GunRearm        	     = counter(),
    Cage        	     = counter(),
    TDCX        	     = counter(),
    TDCY        	     = counter(),
    AirBrake           = counter(),
    Cutoff            = counter(),


    ElecBatt                     = counter(),
    ElecGen                     = counter(),
    ElecAcftIntc                 = counter(),
    ElecExtPwr                     = counter(),
    ElecBkp                     = counter(),
    ElecEmer                     = counter(),

    COM1                     = counter(),
    COM2                     = counter(),
    COM3                     = counter(),

	-- Weapon panel selectors (A-29 STEP parity).
	MassSelectorStep         = counter(),
	LateArmSelectorStep      = counter(),

}
-- [Fase R3.9] COMSEC (KIV-77 equivalent) - Systems/comsec.lua
count = start_command
comsec_commands =
{
	Zeroize			= counter();	-- clear key, force PLAIN
	KeyLoadTest		= counter();	-- re-run self-test / re-load key
}

-- [Fase R3.10] HMD polish - cage/uncage toggle - HMD/device/hmd.lua
count = start_command
hmd_commands =
{
	CageToggle		= counter();	-- press to toggle boresight/HOBS
}

-- [FLIR/TGP] AN/AAQ-28 LITENING targeting pod -> FLIR/device.lua (devices.FLIR).
-- Full command order verified at runtime against the A-29 using the same
-- standalone avSimplest.dll. Keep these values explicit: inserting commands
-- into this range changes the meaning received by the native FLIR device.
flir_commands =
{
	WFOV		= 3001;
	MFOV		= 3002;
	NFOV		= 3003;
	FOVCycle	= 3004;
	BandIR		= 3005;
	BandTV		= 3006;
	BandCycle	= 3007;
	LSTOn		= 3008;
	LSTOff		= 3009;
	LSTToggle	= 3010;
	IRPtrToggle	= 3011;
	NUCTrigger	= 3012;
	TrackAuto	= 3013;
	TrackStore	= 3014;
	TrackDrop	= 3015;
	TrackNext	= 3016;
	TrackPrev	= 3017;
	Menu		= 3018;
	Hook		= 3019;
	Lock		= 3020;
	Freeze		= 3021;
	TrackBrk	= 3022;
	Power		= 3023;
	FocusOut	= 3024;
	FocusIn		= 3025;
	Cage		= 3026;
	IPHH		= 3027;
	Polarity	= 3028;
	SlewLeft	= 3029;
	SlewRight	= 3030;
	SlewUp		= 3031;
	SlewDown	= 3032;
	GainUp		= 3033;
	GainDown	= 3034;
	LevelDown	= 3035;
	LevelUp		= 3036;
	AutoGain	= 3037;
	LaserOn		= 3038;
	-- F-5EM-only safety gate; not consumed by the A-29 native device.
	LaserArm	= 3039;
	-- Pilot-facing toggle. The Lua state machine forwards 3038 only when safe.
	LaserToggle	= 3040;
}

iCommandPlaneUHFFunctionDialMAIN             = 1219
iCommandPlaneUHFFreqModeDialMNL	           = 1222
