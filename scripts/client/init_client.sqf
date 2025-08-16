[] call compileFinal preprocessFileLineNumbers "scripts\client\misc\init_markers.sqf";
// Removed arsenal switch, using default (empty arrays)
GRLIB_arsenal_weapons = [];
GRLIB_arsenal_magazines = [];
GRLIB_arsenal_items = [];
GRLIB_arsenal_backpacks = [];

[] call compileFinal preprocessFileLineNumbers "scripts\client\build\build_overlay.sqf";

if (typeOf player == "VirtualSpectator_F") exitWith {
    execVM "scripts\client\markers\empty_vehicles_marker.sqf";
    execVM "scripts\client\markers\fob_markers.sqf";
    execVM "scripts\client\markers\group_icons.sqf";
    execVM "scripts\client\markers\hostile_groups.sqf";
    execVM "scripts\client\markers\sector_manager.sqf";
    execVM "scripts\client\markers\spot_timer.sqf";
    execVM "scripts\client\misc\synchronise_vars_delta.sqf";
    execVM "scripts\client\ui\ui_manager.sqf";
};

// This causes the script error with not defined variable _display in File A3\functions_f_bootcamp\Inventory\fn_arsenal.sqf [BIS_fnc_arsenal], line 2122
// ["Preload"] call BIS_fnc_arsenal;
spawn_camera = compileFinal preprocessFileLineNumbers "scripts\client\spawn\spawn_camera.sqf";
cinematic_camera = compileFinal preprocessFileLineNumbers "scripts\client\ui\cinematic_camera.sqf";
write_credit_line = compileFinal preprocessFileLineNumbers "scripts\client\ui\write_credit_line.sqf";
do_load_box = compileFinal preprocessFileLineNumbers "scripts\client\ammoboxes\do_load_box.sqf";
kp_fuel_consumption = compileFinal preprocessFileLineNumbers "scripts\client\misc\kp_fuel_consumption.sqf";
kp_vehicle_permissions = compileFinal preprocessFileLineNumbers "scripts\client\misc\vehicle_permissions.sqf";

execVM "scripts\client\actions\intel_manager.sqf";
execVM "scripts\client\actions\recycle_manager.sqf";
execVM "scripts\client\actions\unflip_manager.sqf";
execVM "scripts\client\ammoboxes\ammobox_action_manager.sqf";
execVM "scripts\client\build\do_build.sqf";
execVM "scripts\client\commander\enforce_whitelist.sqf";
if (KP_liberation_mapmarkers) then {execVM "scripts\client\markers\empty_vehicles_marker.sqf";};
execVM "scripts\client\markers\fob_markers.sqf";
if (!KP_liberation_high_command && KP_liberation_mapmarkers) then {execVM "scripts\client\markers\group_icons.sqf";};
execVM "scripts\client\markers\hostile_groups.sqf";
if (KP_liberation_mapmarkers) then {execVM "scripts\client\markers\huron_marker.sqf";} else {deleteMarkerLocal "huronmarker"};
execVM "scripts\client\markers\sector_manager.sqf";
execVM "scripts\client\markers\spot_timer.sqf";
execVM "scripts\client\misc\broadcast_squad_colors.sqf";
//execVM "scripts\client\misc\init_arsenal.sqf";
execVM "scripts\client\misc\permissions_warning.sqf";
if (!KP_liberation_ace) then {execVM "scripts\client\misc\resupply_manager.sqf";};
execVM "scripts\client\misc\secondary_jip.sqf";
execVM "scripts\client\misc\synchronise_vars_delta.sqf";
execVM "scripts\client\misc\synchronise_eco.sqf";
execVM "scripts\client\misc\playerNamespace.sqf";
execVM "scripts\client\spawn\redeploy_manager.sqf";
execVM "scripts\client\ui\ui_manager.sqf";
execVM "scripts\client\ui\tutorial_manager.sqf";
execVM "scripts\client\markers\update_production_sites.sqf";

player addMPEventHandler ["MPKilled", {_this spawn kill_manager;}];
player addEventHandler ["GetInMan", {[_this select 2] spawn kp_fuel_consumption;}];
player addEventHandler ["GetInMan", {[_this select 2] call KPLIB_fnc_setVehiclesSeized;}];
player addEventHandler ["GetInMan", {[_this select 2] call KPLIB_fnc_setVehicleCaptured;}];
player addEventHandler ["GetInMan", {[_this select 2] call kp_vehicle_permissions;}];
player addEventHandler ["SeatSwitchedMan", {[_this select 2] call kp_vehicle_permissions;}];
player addEventHandler ["HandleRating", {if ((_this select 1) < 0) then {0};}];

// Disable stamina, if selected in parameter
if (!GRLIB_fatigue) then {
    player enableStamina false;
    player addEventHandler ["Respawn", {player enableStamina false;}];
};

// Reduce aim precision coefficient, if selected in parameter
if (!KPLIB_sway) then {
    player setCustomAimCoef 0.1;
    player addEventHandler ["Respawn", {player setCustomAimCoef 0.1;}];
};

execVM "scripts\client\ui\intro.sqf";

[player] joinSilent (createGroup [GRLIB_side_friendly, true]);
player setVariable ["Ace_medical_medicClass", 0];

// Commander init
if (player isEqualTo ([] call KPLIB_fnc_getCommander)) then {
    // Start tutorial
    if (KP_liberation_tutorial) then {
        [] call KPLIB_fnc_tutorial;
    };
    // Request Zeus if enabled
    if (KP_liberation_commander_zeus) then {
        [] spawn {
            sleep 5;
            [] call KPLIB_fnc_requestZeus;
        };
    };
};

//Only Allow PJ's to access blood crate
Fn_IsRestrictedBoxForPlayerAccess = { 
	params ["_unt", "_box"]; 
    player getvariable "Ace_medical_medicClass" < 2 && typeOf _box == "nzf_NZBloodbox";
    };

player addEventHandler ["InventoryOpened", Fn_IsRestrictedBoxForPlayerAccess];
//*****************************************************************************************************
// Killed
player addEventHandler ["Killed", {
	params ["_unit"];
	private _uid = getPlayerUID _unit;
	missionNamespace setVariable [format ["NZF_savedLoadout_%1", _uid], [getUnitLoadout _unit] call acre_api_fnc_filterUnitLoadout];
	missionNamespace setVariable [format ["NZF_savedTeam_%1", _uid], assignedTeam _unit];
}];

// Respawn
player addEventHandler ["Respawn", {
	params ["_unit"];
	private _uid = getPlayerUID _unit;

	private _ld = missionNamespace getVariable [format ["NZF_savedLoadout_%1", _uid], nil];
	if (!isNil "_ld") then {_unit setUnitLoadout _ld;};

	private _team = missionNamespace getVariable [format ["NZF_savedTeam_%1", _uid], nil];
	if (!isNil "_team") then {_unit assignTeam _team;};
}];
//*****************************************************************************************************
/*
	Faction: initPlayerLocal.sqf
	Author: Dom
	Requires: Start us up
*/

DT_isACEEnabled = isClass (configFile >> "CfgPatches" >> "ace_common");
//DT_arsenalBoxes = [arsenal_1];

//***************************************************************************************

player addEventHandler ["Respawn",DT_fnc_onRespawn];

if (DT_isACEEnabled) then {
	private _groupCategory = [
		"groupCategory",
		"Group Menu",
		"\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\meet_ca.paa",
		{[] call DT_fnc_initGroupMenu},
		{
			isNull objectParent player && {((player getVariable ["KPLIB_fobDist", 9999999]) < 50) || (player distance (getMarkerPos "startbase_marker") < 100)}
		}
	] call ace_interact_menu_fnc_createAction;
	[player,1,["ACE_SelfActions"],_groupCategory] call ace_interact_menu_fnc_addActionToObject;

	private _arsenalCategory = [
		"arsenalCategory",
		"Arsenal",
		"\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\armor_ca.paa",
		{			
			[player,player,false] call ace_arsenal_fnc_openBox},
		{
			isNull objectParent player &&
			{player getVariable ["ace_arsenal_virtualItems",[]] isNotEqualTo [] && 
			{((player getVariable ["KPLIB_fobDist", 9999999]) < 50) || (player distance (getMarkerPos "startbase_marker") < 100)}}
		}
	] call ace_interact_menu_fnc_createAction;
	[player,1,["ACE_SelfActions"],_arsenalCategory] call ace_interact_menu_fnc_addActionToObject;

	["ace_arsenal_displayClosed",{
		DT_savedLoadout = getUnitLoadout player;
		[player, ""] call BIS_fnc_setUnitInsignia;
       	}] call CBA_fnc_addEventHandler;
} else {
	{
		_x addAction ["Open Group Menu",DT_fnc_initGroupMenu];
	} forEach DT_arsenalBoxes;

	[missionNamespace,"arsenalClosed",{
		DT_savedLoadout = getUnitLoadout player;
		[player, ""] call BIS_fnc_setUnitInsignia;
	}] call BIS_fnc_addScriptedEventHandler;
};
[player, ""] call BIS_fnc_setUnitInsignia;
["InitializePlayer", [player, true]] call BIS_fnc_dynamicGroups; 
//***************************************************************************************