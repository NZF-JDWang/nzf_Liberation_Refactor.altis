/*
	Faction: CTRG
	Author: Dom
*/
class teamlead {
	name = $STR_B_SOLDIER_TL_F0;
	rank = "Sergeant";
	description = $STR_DT_TeLe_Description;
	traits[] = {

	};
	customVariables[] = {
		{"commandant","false",true};
		{"PJ", "false", true};
		{"ACE_isEngineer", 0, true};
		{"Ace_medical_medicClass", 0, true};
	};
	icon = "a3\ui_f\data\map\vehicleicons\iconManLeader_ca.paa";

	defaultLoadout[] = {
		{"arifle_Katiba_GL_F","","ACE_DBAL_A3_Red","optic_ACO_grn",{"30Rnd_65x39_caseless_green",30},{"1Rnd_HE_Grenade_shell",1},""},
		{"launch_PSRL1_PWS_sand_RF","","","",{"PSRL1_FRAG_RF",1},{},""},
		{},
		{"U_O_CombatUniform_ocamo",{{"ACRE_PRC343",1},{"ACE_EHP",1},{"ACE_IR_Strobe_Item",1},{"ACRE_PRC152",1}}},
		{"V_HarnessO_brn",{{"ACE_microDAGR",1},{"ACE_EntrenchingTool",1},{"SmokeShell",2,1},{"HandGrenade",2,1},{"30Rnd_65x39_caseless_green",7,30},{"30Rnd_65x39_caseless_green_mag_Tracer",3,30}}},
		{"B_Carryall_ocamo",{{"FirstAidKit",2},{"ACE_salineIV_250",2},{"ACE_splint",4},{"ACE_tourniquet",4},{"ACE_quikclot",10},{"ACE_elasticBandage",10},{"ACE_bodyBag",1},{"ACE_painkillers",1,10},{"1Rnd_HE_Grenade_shell",9,1},{"PSRL1_HEAT_RF",2,1},{"PSRL1_FRAG_RF",2,1}}},
		"H_HelmetO_ocamo","",{"ACE_Vector","","","",{},{},""},
		{"ItemMap","","","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {
		"arifle_Katiba_GL_F",
		"arifle_CTAR_GL_blk_F",
		"arifle_CTAR_GL_hex_F"
	};
	arsenalMagazines[] = {

	};
	arsenalItems[] = {

	};
	arsenalBackpacks[] = {

	};
};