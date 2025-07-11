/*
    File: fn_saveSectorState.sqf
    Author: KP Liberation Mod - Extended by AI
    Description:
        Stores position, damage and other relevant information of all currently managed enemy units/vehicles within a sector so that they can be restored if the sector is re-activated later.

    Parameters:
        _sector        - Marker name of the sector                         [STRING]
        _managedUnits  - Array with objects that are going to despawn      [ARRAY]

    Returns:
        Nothing
*/

params [
    ["_sector", "", [""]],
    ["_managedUnits", [], [[]]]
];

if (_sector isEqualTo "") exitWith { };

private _state = [];
private _groupMap = createHashMap;
private _nextGroupIdx = 0;

{
    if (!alive _x) then {continue;};
    // Skip units that are currently inside a vehicle. Their state will be handled via the parent vehicle to avoid duplicate crew spawning.
    if ((_x isKindOf "Man") && {(vehicle _x) != _x}) then {continue;};

    private _isMan = _x isKindOf "Man";
    private _type  = typeOf _x;
    private _pos   = getPosATL _x;            // Using ATL for restoration in buildings
    private _dir   = direction _x;
    private _damage = damage _x;

    if (_isMan) then {
        private _loadout = getUnitLoadout _x;
        private _grpKey = str (group _x);
        private _grpIdx = _groupMap get _grpKey;
        if (isNil "_grpIdx") then {
            _grpIdx = _nextGroupIdx;
            _nextGroupIdx = _nextGroupIdx + 1;
            _groupMap set [_grpKey, _grpIdx];
        };
        _state pushBack [true, _type, _pos, _dir, _damage, _loadout, _grpIdx];
    } else {
        private _fuel   = fuel _x;
        private _vecDir = vectorDir _x;
        private _vecUp  = vectorUp _x;
        _state pushBack [false, _type, _pos, _dir, _damage, _fuel, _vecDir, _vecUp];
    };
} forEach _managedUnits;

// Initialise container if not existing
if (isNil "KPLIB_sectorStates") then {
    KPLIB_sectorStates = createHashMap;
};

// Store and broadcast
KPLIB_sectorStates set [_sector, _state];
publicVariable "KPLIB_sectorStates"; 