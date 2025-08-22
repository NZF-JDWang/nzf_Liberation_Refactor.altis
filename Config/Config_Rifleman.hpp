/*
	Faction: CTRG
	Author: Dom
*/
class rifleman {
	name = $STR_DN_RIFLEMAN;
	rank = "Private";
	description = $STR_DT_Rifleman_Description;
	traits[] = {

	};
	customVariables[] = {
		{"commandant","false",true};
		{"PJ", "false", true};
		{"ACE_isEngineer", 0, true};
		{"Ace_medical_medicClass", 0, true};

	};
	icon = "a3\ui_f\data\map\vehicleicons\iconMan_ca.paa";

	defaultLoadout[] = {
		{"arifle_Katiba_ACO_pointer_F","","ACE_DBAL_A3_Red","optic_ACO_grn",{"30Rnd_65x39_caseless_green",30},{},""},
		{"launch_RPG32_F","","","",{"RPG32_F",1},{},""},
		{},
		{"U_O_CombatUniform_ocamo",{{"ACRE_PRC343",1},{"ACE_EHP",1},{"ACE_IR_Strobe_Item",1}}},
		{"V_HarnessO_brn",{{"ACE_microDAGR",1},{"ACE_EntrenchingTool",1},{"30Rnd_65x39_caseless_green",7,30},{"30Rnd_65x39_caseless_green_mag_Tracer",3,30},{"SmokeShell",2,1},{"HandGrenade",2,1}}},
		{"B_FieldPack_ocamo",{{"FirstAidKit",2},{"ACE_salineIV_250",2},{"ACE_splint",4},{"ACE_tourniquet",4},{"ACE_quikclot",10},{"ACE_elasticBandage",10},{"ACE_bodyBag",1},{"ACE_painkillers",1,10},{"RPG32_F",1,1},{"RPG32_HE_F",1,1}}},
		"H_HelmetO_ocamo","",{"ACE_Vector","","","",{},{},""},
		{"ItemMap","","ItemRadio","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {

	};
	arsenalMagazines[] = {

	};
	arsenalItems[] = {

	};
	arsenalBackpacks[] = {

	};
};