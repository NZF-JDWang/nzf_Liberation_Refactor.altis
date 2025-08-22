/*
	Faction: CTRG
	Author: Dom
*/
class engineer {
	name = $STR_B_ENGINEER_F0;
	rank = "Corporal";
	description = $STR_DT_Engineer_Description;
	traits[] = {
		{"Engineer",true};
		{"explosiveSpecialist",true};
	};
	customVariables[] = {
		{"commandant","false",true};
		{"PJ", "false", true};
		{"ACE_isEngineer", 2, true};
		{"Ace_medical_medicClass", 0, true};
	};
	icon = "a3\ui_f\data\map\vehicleicons\iconManEngineer_ca.paa";

	defaultLoadout[] = {
		{"arifle_Katiba_F","","ACE_DBAL_A3_Red","optic_ACO_grn",{"30Rnd_65x39_caseless_green",30},{},""},
		{},
		{},
		{"U_O_CombatUniform_ocamo",{{"ACRE_PRC343",1},{"ACE_EHP",1},{"ACE_IR_Strobe_Item",1}}},
		{"V_HarnessO_brn",{{"ACE_microDAGR",1},{"ACE_EntrenchingTool",1},{"30Rnd_65x39_caseless_green",7,30},{"30Rnd_65x39_caseless_green_mag_Tracer",3,30},{"SmokeShell",2,1},{"HandGrenade",2,1}}},
		{"B_Carryall_ocamo",{{"FirstAidKit",2},{"ACE_salineIV_250",2},{"ACE_splint",4},{"ACE_tourniquet",4},{"ACE_quikclot",10},{"ACE_elasticBandage",10},{"ACE_bodyBag",1},{"ACE_EntrenchingTool",1},{"ACE_DefusalKit",1},{"ToolKit",1},{"ACE_painkillers",1,10},{"APERSMineDispenser_Mag",2,1}}},
		"H_HelmetO_ocamo","",{"ACE_Vector","","","",{},{},""},
		{"ItemMap","","","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {

	};
	arsenalMagazines[] = {

	};
	arsenalItems[] = {
		"ToolKit", "MineDetector"
	};
	arsenalBackpacks[] = {

	};
};