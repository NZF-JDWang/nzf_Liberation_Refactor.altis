/*
	Faction: CTRG
	Author: Dom
*/
class machinegunner {
	name = "Machinegunner";
	rank = "Private";
	description = "Responsible for fire support and suppression of the enemy. Get those rounds down range";
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
		{"MMG_01_hex_F","","ACE_DBAL_A3_Red","optic_Arco_hex_lxWS",{"150Rnd_93x64_Mag",150},{},"bipod_02_F_hex"},
		{},
		{},
		{"U_O_CombatUniform_ocamo",{{"ACE_EHP",1},{"ACE_IR_Strobe_Item",1},{"ACRE_PRC343",1},{"ACE_microDAGR",1},{"HandGrenade",2,1}}},
		{"V_HarnessO_brn",{{"150Rnd_93x64_Mag",2,150}}},
		{"B_Carryall_ocamo",{{"ACE_salineIV_250",2},{"ACE_splint",4},{"ACE_tourniquet",6},{"ACE_quikclot",10},{"ACE_elasticBandage",10},{"ACE_bodyBag",1},{"ACE_fieldDressing",2},{"ACE_packingBandage",2},{"ACE_morphine",2},{"ACE_EntrenchingTool",1},{"ACE_painkillers",1,10},{"150Rnd_93x64_Mag",3,150},{"SmokeShell",2,1}}},
		"H_HelmetO_ocamo","",{"ACE_Vector","","","",{},{},""},
		{"ItemMap","","","ItemCompass","ACE_Altimeter","ACE_NVG_Gen4_Black_WP"}
	};

	arsenalWeapons[] = {
		"LMG_Zafir_F",
		"LMG_S77_Hex_lxWS",
		"MMG_01_hex_F"
	};
	arsenalMagazines[] = {
		"150Rnd_762x54_Box",
		"150Rnd_762x54_Box_Tracer",
		"150Rnd_762x51_Box",
		"150Rnd_762x51_Box_Tracer",
		"150Rnd_93x64_Mag"

	};
	arsenalItems[] = {

	};
	arsenalBackpacks[] = {

	};
};