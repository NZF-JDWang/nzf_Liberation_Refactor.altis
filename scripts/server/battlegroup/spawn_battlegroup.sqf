// TODO Refactor and create function
params [
    ["_spawn_marker", "", [""]],
    ["_infOnly", false, [false]]
];

if (KPLIB_endgame == 1) exitWith {};

_spawn_marker = [[2000, 1000] select _infOnly, 3000, false, markerPos _spawn_marker] call KPLIB_fnc_getOpforSpawnPoint;

if !(_spawn_marker isEqualTo "") then {
    KPLIB_last_battlegroup_time = diag_tickTime;

    private _bg_groups = [];
    private _selected_opfor_battlegroup = [];
    private _target_size = (round (KPLIB_battlegroup_size * ([] call KPLIB_fnc_getOpforFactor) * (sqrt KPLIB_param_aggressivity))) min 16;
    if (KPLIB_enemyReadiness < 60) then {_target_size = round (_target_size * 0.65);};

    [_spawn_marker] remoteExec ["remote_call_battlegroup"];

    if (worldName in KPLIB_battlegroup_clearance) then {
        [markerPos _spawn_marker, 15] call KPLIB_fnc_createClearance;
    };

    if (_infOnly) then {
        // Infantry units to choose from
        private _infClasses = [KPLIB_o_inf_classes, KPLIB_o_militiaInfantry] select (KPLIB_enemyReadiness < 50);

        // Adjust target size for infantry
        _target_size = 12 max (_target_size * 4);

        // Create infantry groups with up to 8 units per squad
        private _grp = createGroup [KPLIB_side_enemy, true];
        for "_i" from 0 to (_target_size - 1) do {
            if (_i > 0 && {(_i % 8) isEqualTo 0}) then {
                _bg_groups pushBack _grp;
                _grp = createGroup [KPLIB_side_enemy, true];
            };
            [selectRandom _infClasses, markerPos _spawn_marker, _grp] call KPLIB_fnc_createManagedUnit;
        };
        _bg_groups pushBack _grp;
        {
            [_x] spawn battlegroup_ai;
        } forEach _bg_groups;
    } else {
        private _vehicle_pool = [KPLIB_o_battleGrpVehicles, KPLIB_o_battleGrpVehiclesLight] select (KPLIB_enemyReadiness < 50);

        while {count _selected_opfor_battlegroup < _target_size/2} do {
            _selected_opfor_battlegroup pushback (selectRandom _vehicle_pool);
        };

        private ["_nextgrp", "_vehicle"];
        {
            _nextgrp = createGroup [KPLIB_side_enemy, true];
            _vehicle = [markerpos _spawn_marker, _x] call KPLIB_fnc_spawnVehicle;

            sleep 0.5;

            (crew _vehicle) joinSilent _nextgrp;
            [_nextgrp] spawn battlegroup_ai;
            _bg_groups pushback _nextgrp;

            if ((_x in KPLIB_o_troopTransports) && ([] call KPLIB_fnc_getOpforCap < KPLIB_cap_battlegroup)) then {
                if (_vehicle isKindOf "Air") then {
                    [[markerPos _spawn_marker] call KPLIB_fnc_getNearestBluforObjective, _vehicle] spawn send_paratroopers;
                } else {
                    [_vehicle] spawn troup_transport;
                };
            };
        } forEach _selected_opfor_battlegroup;

        if (KPLIB_param_aggressivity > 0.9) then {
            [[markerPos _spawn_marker] call KPLIB_fnc_getNearestBluforObjective] spawn spawn_air;
        };
    };

    sleep 3;

    KPLIB_enemyReadiness = (KPLIB_enemyReadiness - (round ((count _bg_groups) + (random (count _bg_groups))))) max 0;
    stats_hostile_battlegroups = stats_hostile_battlegroups + 1;

    {
        if (local _x) then {
            _headless_client = [] call KPLIB_fnc_getLessLoadedHC;
            if (!isNull _headless_client) then {
                _x setGroupOwner (owner _headless_client);
            };
        };
        sleep 1;
    } forEach _bg_groups;
};
