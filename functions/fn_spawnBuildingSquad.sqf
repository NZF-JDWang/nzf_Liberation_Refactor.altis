/*
    File: fn_spawnBuildingSquad.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-12-03
    Last Update: 2025-08-10
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Spawns given amount of infantry in buildings of given sector at given building positions.
        Revised to create garrison clusters that can mutually support each other. Units are divided
        into multiple clusters (2–4 when possible) and each cluster is anchored to a local position.
        The cluster anchor is stored on the group as "KPLIB_garrisonAnchorPos" and used by
        building_defence_ai to constrain LAMBS garrison task radius to ~50 m.

    Parameter(s):
        _type       - Type of infantry. Either "militia" or "army"  [STRING, defaults to "army"]
        _amount     - Amount of infantry units to spawn             [NUMBER, defaults to 0]
        _positions  - Array of building positions                   [ARRAY, defaults to []]
        _sector     - Sector where to spawn the units               [STRING, defaults to ""]

    Returns:
        Spawned units [ARRAY]
*/

params [
    ["_type", "army", [""]],
    ["_amount", 0, [0]],
    ["_positions", [], [[]]],
    ["_sector", "", [""]]
];

if (_sector isEqualTo "") exitWith {["Empty string given"] call BIS_fnc_error; []};

// Get classnames array
private _classnames = [[] call KPLIB_fnc_getSquadComp, militia_squad] select (_type == "militia");

// Adjust amount, if needed
if (_amount > floor ((count _positions) * GRLIB_defended_buildingpos_part)) then {
    _amount = floor ((count _positions) * GRLIB_defended_buildingpos_part)
};

// Helper: choose two anchors from available building positions with spacing
private _chooseAnchors = {
    params ["_posList", ["_minSpacing", 60], ["_max", 4], ["_seed", []]];
    private _anchors = [];
    if ((count _posList) == 0) exitWith { [] };
    // Start with provided seed (e.g., central), or a random one
    private _start = if ((_seed isEqualType []) && {(count _seed) >= 2}) then { _seed } else { selectRandom _posList };
    _anchors pushBack _start;
    // Farthest-point sampling to get well-spaced anchors
    for "_i" from 2 to _max do {
        private _bestP = objNull; private _bestScore = -1;
        {
            private _p = _x;
            private _nearest = 1e9;
            { private _d = _p distance2D _x; if (_d < _nearest) then { _nearest = _d; }; } forEach _anchors;
            if (_nearest > _bestScore) then { _bestScore = _nearest; _bestP = _p; };
        } forEach _posList;
        if (_bestScore >= _minSpacing) then {
            _anchors pushBack _bestP;
        } else {
            break;
        };
    };
    _anchors
};

// If we have enough building positions, split into clusters; otherwise fall back to legacy spawn
private _units = [];
private _pos = markerPos _sector;
if ((count _positions) >= 6 && {_amount >= 4}) then {
    // Determine up to two anchors and cluster positions around them
    // Determine 2–4 anchors depending on density and amount
    private _targetAnchors = 2 min (4 min (1 + floor ((_amount - 1) / 4)));

    // Force first anchor to be central (closest building pos to sector center)
    private _center = _pos;
    private _centralAnchor = objNull;
    private _bestD = 1e9;
    {
        private _d = _x distance2D _center;
        if (_d < _bestD) then { _bestD = _d; _centralAnchor = _x; };
    } forEach _positions;

    // Choose remaining anchors with larger spacing to spread across town
    private _anchors = [_positions, 90, _targetAnchors, _centralAnchor] call _chooseAnchors;
    if ((count _anchors) == 0) then {
        _anchors = [_pos];
    };

    private _clusters = [];
    {
        private _a = _x;
        private _clusterPos = _positions select { (_x distance2D _a) <= (if (_forEachIndex == 0) then { 90 } else { 70 }) };
        // Remove clustered positions from the pool so clusters don't overlap too much
        _positions = _positions - _clusterPos;
        _clusters pushBack [ _a, _clusterPos ];
    } forEach _anchors;

    // If there are leftover positions, distribute them to nearest anchor
    {
        private _p = _x;
        private _idx = 0; private _best = 1e9;
        for "_i" from 0 to ((count _clusters) - 1) do {
            private _d = (_p distance2D ((_clusters select _i) select 0));
            if (_d < _best) then { _best = _d; _idx = _i; };
        };
        ((_clusters select _idx) select 1) pushBack _p;
    } forEach _positions;

    // Determine per-cluster counts (split as evenly as possible)
    private _numClusters = count _clusters;
    private _remaining = _amount;

    // Allocate a larger share to the central (index 0) cluster
    private _centralShare = (_amount max 1);
    _centralShare = ceil (_amount * 0.5);
    if (_centralShare > (_amount - (_numClusters - 1))) then { _centralShare = _amount - (_numClusters - 1) max 1; };

    // Append target counts to each cluster
    for "_i" from 0 to (_numClusters - 1) do {
        private _alloc = 0;
        if (_i == 0) then {
            _alloc = _centralShare;
        } else {
            _alloc = floor ((_amount - _centralShare) / (_numClusters - 1));
            if (_i <= ((_amount - _centralShare) mod (_numClusters - 1))) then { _alloc = _alloc + 1; };
        };
        (_clusters select _i) pushBack _alloc;
    };

    // Spawn per cluster, splitting groups at 10 units as before
    {
        _x params ["_anchor", "_cpos", "_targetCount"];
        private _grp = createGroup [GRLIB_side_enemy, true];
        _grp setVariable ["KPLIB_garrisonAnchorPos", _anchor, false];
        private _spawnedHere = 0;
        while { _spawnedHere < _targetCount } do {
            if (count (units _grp) >= 10) then {
                _grp = createGroup [GRLIB_side_enemy, true];
                _grp setVariable ["KPLIB_garrisonAnchorPos", _anchor, false];
            };
            private _class = selectRandom _classnames;
            private _unit = [_class, _pos, _grp] call KPLIB_fnc_createManagedUnit;
            _unit setDir (random 360);
            if ((count _cpos) > 0) then {
                _unit setPos (_cpos deleteAt (floor (random (count _cpos))));
            };
            [_unit, _sector] spawn building_defence_ai;
            _units pushBack _unit;
            _spawnedHere = _spawnedHere + 1;
        };
    } forEach _clusters;
} else {
    // Legacy behavior: single group, spread across available positions
    private _grp = createGroup [GRLIB_side_enemy, true];
    private _unit = objNull;
    for "_i" from 1 to _amount do {
        if (count (units _grp) >= 10) then {
            _grp = createGroup [GRLIB_side_enemy, true];
        };
// Enable LAMBS reinforcement behavior for the garrison group(s)
{
    if (!isNull _x) then { _x setVariable ["lambs_danger_enableGroupReinforce", true, true]; };
} forEach (allGroups select { side _x == GRLIB_side_enemy && { _x getVariable ["KPLIB_garrisonAnchorPos", objNull] isNotEqualTo objNull } });
        private _class = selectRandom _classnames;
        _unit = [_class, _pos, _grp] call KPLIB_fnc_createManagedUnit;
        _unit setDir (random 360);
        if ((count _positions) > 0) then {
            _unit setPos (_positions deleteAt (random (floor (count _positions) - 1)));
        };
        // For legacy path, still constrain garrison to local position via group anchor
        _grp setVariable ["KPLIB_garrisonAnchorPos", getPos _unit, false];
        [_unit, _sector] spawn building_defence_ai;
        _units pushBack _unit;
    };
};

_units
