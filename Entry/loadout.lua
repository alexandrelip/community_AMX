declare_loadout({
	category		 = CAT_FUEL_TANKS,
	CLSID			 = "{AMX_TANK}",
	attribute		 =  {wsType_Air,wsType_Free_Fall,wsType_FuelTank,WSTYPE_PLACEHOLDER},

	Picture			 = "ptb2.png",
	displayName		 = _("70 Imp gal (320 lit) external tank"),
	Weight_Empty	 = 40.8,
	Weight			 = 40.8 +  230.3,
	Cx_pil			 = 0.002,
	shape_table_data = 
	{
		{
			name 	= "AMX_TANK",
			file	= "AMX_TANK",
			life	= 1;
			fire	= { 0, 1};
			username	= "AMX_TANK";
			index	= WSTYPE_PLACEHOLDER;
		},
	},
	Elements	= 
	{
		{
			ShapeName	= "AMX_TANK",
		}, 
	}, 
})



