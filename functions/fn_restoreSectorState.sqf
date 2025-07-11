/*
    File: fn_restoreSectorState.sqf
    Author: KP Liberation Mod - Extended by AI
    Description:
        Restores previously saved enemy units/vehicles for a sector (if available).
        Returns an array with all recreated objects so that the caller can continue to manage them.

    Parameter(s):
        _sector - Marker name of the sector [STRING]

    Returns:
        Array with recreated objects [ARRAY]
*/

params [["_sector", "", [""]]];

if (_sector isEqualTo "") exitWith {[]};

if (isNil "KPLIB_sectorStates") exitWith {[]};
private _saved = [];
if (!isNil "KPLIB_sectorStates") then {
    if (KPLIB_sectorStates isEqualType createHashMap) then {
        if (KPLIB_sectorStates in [objNull]) then {
            _saved = [];
        } else {
            _saved = KPLIB_sectorStates get _sector;
            if (isNil "_saved") then {_saved = []};
        };
    };
};
if (_saved isEqualTo []) exitWith {[]};

// Remove from hashmap immediately so it will not be spawned twice later
KPLIB_sectorStates deleteAt _sector;
publicVariable "KPLIB_sectorStates";

private _sectorPos = markerPos _sector;
private _managedUnits = [];
private _groupsCache = [];

// Determine headless client once for later assignment
private _hc = [] call KPLIB_fnc_getLessLoadedHC;

{
    private _isMan  = _x select 0;
    private _type   = _x select 1;
    private _pos    = _x select 2;
    private _dir    = _x select 3;
    private _damage = _x select 4;

    if (_isMan) then {
        private _loadout = _x select 5;
        private _grpIdx = if ((count _x) > 6) then {_x select 6} else {0};  // backward compatibility

        // Ensure array size
        if (_grpIdx >= count _groupsCache) then {
            _groupsCache resize (_grpIdx + 1);
        };

        private _grp = _groupsCache select _grpIdx;
        if (isNil "_grp" || {isNull _grp}) then {
            _grp = createGroup [GRLIB_side_enemy, true];
            _groupsCache set [_grpIdx, _grp];
        };

        private _unit = [_type, _pos, _grp] call KPLIB_fnc_createManagedUnit;
        _unit setDir _dir;
        _unit setUnitLoadout _loadout;
        _unit setDamage _damage;
        _managedUnits pushBack _unit;
    } else {
        private _fuel   = _x select 5;
        private _vecDir = _x select 6;
        private _vecUp  = _x select 7;

        // Keep precise placement & orientation
        private _vehicle = [_pos, _type, true, false] call KPLIB_fnc_spawnVehicle;
        if (isNull _vehicle) then {continue;};
        _vehicle setDir _dir;
        _vehicle setVectorDirAndUp [_vecDir, _vecUp];
        _vehicle setFuel _fuel;
        _vehicle setDamage _damage;
        if (!isNull _hc) then { (group ((crew _vehicle) select 0)) setGroupOwner (owner _hc); };
        // Add defence waypoints for vehicle crew
        [group ((crew _vehicle) select 0), _sectorPos] spawn add_defense_waypoints;
        _managedUnits pushBack _vehicle;
        { _managedUnits pushBack _x } forEach (crew _vehicle);
    };
} forEach _saved;

// Assign all recreated infantry groups to HC (if available) and add defence waypoints
{
    private _g = _x;
    if (!isNull _g) then {
        if (!isNull _hc) then {
            _g setGroupOwner (owner _hc);
        };
        [_g, _sectorPos] spawn add_defense_waypoints;
    };
} forEach _groupsCache;

_managedUnits 