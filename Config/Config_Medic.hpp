/*
	Faction: CTRG
	Author: Dom
*/
class medic {
	name = $STR_B_MEDIC_F0;
	rank = "Corporal";
	description = $STR_DT_Medic_Description;
	traits[] = {
		{"Medic",true};
	};
	customVariables[] = {
		{"commandant","false",true};
		{"PJ", "false", true};
		{"ACE_isEngineer", 0, true};
		{"Ace_medical_medicClass", 2, true};
	};
	icon = "a3\ui_f\data\map\vehicleicons\iconManMedic_ca.paa";

	defaultLoadout[] = {
		{"arifle_Katiba_F","","ACE_DBAL_A3_Red","optic_ACO_grn",{"30Rnd_65x39_caseless_green",30},{},""},
		{},
		{},
		{"U_O_CombatUniform_ocamo",{{"ACRE_PRC343",1},{"ACE_EHP",1},{"ACE_IR_Strobe_Item",1}}},
		{"V_HarnessO_brn",{{"ACE_microDAGR",1},{"ACE_EntrenchingTool",1},{"30Rnd_65x39_caseless_green",7,30},{"30Rnd_65x39_caseless_green_mag_Tracer",3,30},{"SmokeShell",2,1},{"HandGrenade",2,1}}},
		{"B_Carryall_ocamo",{{"ACE_splint",6},{"ACE_tourniquet",4},{"ACE_quikclot",50},{"ACE_elasticBandage",25},{"ACE_bodyBag",1},{"ACE_bloodIV",5},{"Medikit",2},{"ACE_surgicalKit",1},{"ACE_suture",25},{"ACE_morphine",10},{"ACE_epinephrine",10},{"ACE_bloodIV_500",5},{"ACE_packingBandage",25},{"ACE_painkillers",2,10}}},
		"H_HelmetO_ocamo","",{"ACE_Vector","","","",{},{},""},
		{"ItemMap","","","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {

	};
	arsenalMagazines[] = {

	};
	arsenalItems[] = {
		"Medikit",
		"ACE_bloodIV",
		"ACE_bloodIV_500",
		"ACE_epinephrine",
		"ACE_morphine",
		"ACE_surgicalKit",
		"ACE_suture"
	};
	arsenalBackpacks[] = {

	};
};