/*
	Faction: CTRG
	Author: Dom
*/
class officer {
	name = $STR_B_OFFICER_F0;
	rank = "Captain";
	description = $STR_DT_Officer_Description;
	traits[] = {

	};
	customVariables[] = {
		{"commandant","true",true};
		{"PJ", "false", true};
		{"ACE_isEngineer", 0, true};
		{"Ace_medical_medicClass", 0, true};
	};
	icon = "a3\ui_f\data\map\vehicleicons\iconManCommander_ca.paa";

	defaultLoadout[] = {
		{"arifle_CTAR_blk_F","","ACE_DBAL_A3_Green","optic_VRCO_RF",{"30Rnd_580x42_Mag_F",30},{},""},
		{},
		{},
		{"U_O_OfficerUniform_ocamo",{{"ACRE_PRC343",1},{"ACRE_PRC152",1},{"ACE_IR_Strobe_Item",1},{"ACE_EHP",1},{"Chemlight_red",2,1}}},
		{"V_BandollierB_khk",{{"30Rnd_580x42_Mag_F",7,30},{"30Rnd_580x42_Mag_Tracer_F",3,30}}},
		{"B_RadioBag_01_hex_F",{{"ACE_salineIV_250",2},{"ACE_splint",2},{"ACE_tourniquet",3},{"ACE_bodyBag",1},{"ACE_fieldDressing",1},{"ACE_packingBandage",1},{"ACE_morphine",1},{"ACE_HandFlare_Green",2,1},{"SmokeShellGreen",2,1},{"SmokeShellRed",3,1},{"ACE_Chemlight_HiGreen",2,1},{"ACE_Chemlight_IR",2,1},{"ACE_painkillers",1,10},{"SmokeShell",1,1},{"HandGrenade",1,1}}},
		"H_HelmetO_ocamo","",{"Laserdesignator_02","","","",{"Laserbatteries",1},{},""},
		{"ItemMap","ItemMotionSensor_lxWS","","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {

	};
	arsenalMagazines[] = {

	};
	arsenalItems[] = {
		"H_Beret_Colonel", "ItemMotionSensor_lxWS", "ACRE_PRC152"
	};
	arsenalBackpacks[] = {
		"B_RadioBag_01_hex_F"
	};
};