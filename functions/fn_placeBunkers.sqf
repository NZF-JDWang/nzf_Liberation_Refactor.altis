/*
    File: fn_placeBunkers.sqf
    Author: Liberation QoL extension

    Description:
        Places a small number of bunker structures and static weapons around a sector,
        oriented toward the BLUFOR approach. Returns an array of all created objects
        (bunker objects, statics, and any crew) so the caller can manage and despawn them.

    Parameters:
        _sector  - Sector marker name [STRING]

    Returns:
        [createdObjectsAndUnits] [ARRAY]
*/

params [ ["_sector", "", [""]] ];
if (_sector isEqualTo "") exitWith { [] };

private _created = [];
private _sectorPos = markerPos _sector;

// Determine desired counts by sector type and readiness
private _isMilitary = (_sector in sectors_military);
private _isTown     = (_sector in sectors_bigtown) || (_sector in sectors_capture);
private _isFactory  = (_sector in sectors_factory);
private _isTower    = (_sector in sectors_tower);

private _readiness = if (!isNil "KPLIB_enemyReadiness") then { KPLIB_enemyReadiness } else { combat_readiness };
private _opforFactor = [] call KPLIB_fnc_getOpforFactor;

private _baseBunkers = 1 + ([_isMilitary, _isTown, _isFactory] find true);
if (_isMilitary) then { _baseBunkers = 2; };
if (_readiness >= 60) then { _baseBunkers = _baseBunkers + 1; };
_baseBunkers = (_baseBunkers * _opforFactor) min 4; // cap 4 bunkers
private _numBunkers = round _baseBunkers;
if (_numBunkers < 1) then { _numBunkers = 1; };

// Determine approach source using captureEligiblePairs, fallback to nearest BLUFOR objective
private _approachSource = objNull;
if (!isNil "KPLIB_captureEligiblePairs") then {
    private _idx = KPLIB_captureEligiblePairs findIf { (_x select 0) isEqualTo _sector };
    if (_idx >= 0) then {
        private _src = (KPLIB_captureEligiblePairs select _idx) select 1;
        _approachSource = if (_src isEqualType "") then { markerPos _src } else { _src };
    };
};
if (isNil "_approachSource" || { _approachSource isEqualTo objNull }) then {
    _approachSource = [_sectorPos] call KPLIB_fnc_getNearestBluforObjective;
};

private _dirToSrc = [_sectorPos, _approachSource] call BIS_fnc_dirTo;

// Helper: angle delta
private _fnc_angDelta = { params ["_a","_b"]; private _d = abs(_a-_b) % 360; if (_d>180) then {360-_d} else {_d} };

// Find candidate sites using selectBestPlaces in a ring based on sector type
private _expr = "0.6*(hills) + 0.4*(forest) - 0.8*(waterDepth) - 0.3*(meadow)";
private _ringMin = if (_isTower) then { 15 } else { 120 };
private _ringMax = if (_isTower) then { 75 } else { 350 };
private _raw = selectBestPlaces [_sectorPos, (_ringMax + 40), _expr, 40, 32];
private _candidates = [];
{
    private _pos = _x select 0; private _score = _x select 1;
    if (!surfaceIsWater _pos) then {
        private _d = _sectorPos distance2D _pos;
        if (_d >= _ringMin && { _d <= _ringMax }) then {
            private _dir = [_sectorPos, _pos] call BIS_fnc_dirTo;
            private _delta = [_dir, _dirToSrc] call _fnc_angDelta;
            private _arcBonus = 0;
            // Prefer front arc, but also a small bonus for rear arc (to prevent spawning far ahead only)
            if (_delta <= 50) then { _arcBonus = 0.35 } else { if (_delta <= 100) then { _arcBonus = 0.15 } else { if (_delta >= 150) then { _arcBonus = 0.1 } } };
            private _slope = acos ((surfaceNormal _pos) select 2) * 57.2958;
            if (_slope <= 12) then { _candidates pushBack [_pos, _score + _arcBonus]; };
        };
    };
} forEach _raw;

// Sort by score desc and enforce spacing (tighter for towers)
_candidates = [_candidates, [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;
private _sites = [];
{
    private _p = _x select 0; private _ok = true;
    private _spacing = if (_isTower) then { 35 } else { 100 };
    { if ((_p distance2D _x) < _spacing) exitWith { _ok = false }; } forEach _sites;
    if (_ok) then { _sites pushBack _p; };
    if ((count _sites) >= _numBunkers) exitWith {};
} forEach _candidates;

// Fallback random sites if needed
while { (count _sites) < _numBunkers } do {
    private _r = if (_isTower) then { 20 + random 55 } else { 200 + random 300 };
    _sites pushBack (_sectorPos getPos [_r, random 360]);
};

// Determine static counts tied to readiness
private _maxStatics = [1,2] select _isMilitary;
if (_readiness >= 70) then { _maxStatics = _maxStatics + 1; };
private _staticCount = (_maxStatics min _numBunkers) max 0;

private _staticClassesHigh = if (!isNil "opfor_static_high") then { opfor_static_high } else { [] };
private _bunkerClasses     = if (!isNil "opfor_bunkers")     then { opfor_bunkers }     else { [] };

// Place bunkers and a subset with statics
private _staticsPlaced = 0;
{
    private _site = _x;
    // Snap to ground and align facing source
    private _bClass = if ((count _bunkerClasses) > 0) then { selectRandom _bunkerClasses } else { "Land_BagBunker_Small_F" };
    private _pos = _site;
    private _dir = [_site, _approachSource] call BIS_fnc_dirTo;
    private _bunker = createVehicle [_bClass, _pos, [], 0, "CAN_COLLIDE"];
    // Align bunker so its opening faces the approach (most A3 bag bunkers have front = model -Y)
    // Empirically, rotating 180° makes the opening point toward _dir
    _bunker setDir ((_dir + 180) % 360);
    _bunker setVectorUp surfaceNormal _site;
    _created pushBack _bunker;

    // Optionally add a static weapon aimed along approach
    if (_staticsPlaced < _staticCount) then {
        // Statics placed with bunkers should use only "high" statics
        private _sClass = if ((count _staticClassesHigh) > 0) then { selectRandom _staticClassesHigh } else { "" };
        if !(_sClass isEqualTo "") then {
            // Placement rules per bunker type using explicit offsets (do not use building positions)
            private _isSmall = (_bClass == "Land_BagBunker_Small_F");
            private _isTower = (_bClass == "Land_BagBunker_Tower_F");
            private _sPosATL = getPosATL _bunker;
            if (_isTower) then {
                // Place on the upper platform of the tower bunker
                _sPosATL = ASLToATL (AGLToASL (_bunker modelToWorld [0, -0.9, 2.4]));
            } else {
                if (_isSmall) then {
                    _sPosATL = ASLToATL (AGLToASL (_bunker modelToWorld [0, 0, 0]));
                    // Ensure static weapon spawns at same ATL as the small bunker (z = 0)
                    _sPosATL set [2, 0];
                } else {
                    _sPosATL = ASLToATL (AGLToASL (_bunker modelToWorld [0, -0.2, 0]));
                };
            };
            private _stat = createVehicle [_sClass, _sectorPos, [], 0, "CAN_COLLIDE"];
            // Face correct direction: towers follow bunker, small bag bunkers need +180°
            private _face = direction _bunker;
            if (_isSmall) then { _face = (_face + 180) % 360; };
            _stat setDir _face;
            // Match bunker platform inclination for stability
            _stat setPosATL _sPosATL;
            _stat setVectorUp (vectorUp _bunker);
            _created pushBack _stat;
            // Crew it using default crew to keep side/config correct
            private _grp = createGroup [GRLIB_side_enemy, true];
            private _crew = units (createVehicleCrew _stat);
            _crew joinSilent _grp;
            { _created pushBack _x } forEach _crew;
            _staticsPlaced = _staticsPlaced + 1;
        };
    };
} forEach _sites;

_created


