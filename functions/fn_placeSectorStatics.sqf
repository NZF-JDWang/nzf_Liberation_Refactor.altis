/*
    File: fn_placeSectorStatics.sqf
    Author: Liberation QoL extension

    Description:
        Sprinkles low static weapons (from opfor_static_low) at tactical locations
        around a sector, oriented toward the BLUFOR approach. Excludes areas near
        provided objects (e.g., bunkers) and scales count with aggression/readiness.

    Parameters:
        _sector      - Sector marker name [STRING]
        _exclusions  - Optional array of objects to avoid when placing [ARRAY]

    Returns:
        [createdObjectsAndUnits] [ARRAY]
*/

params [ ["_sector", "", [""]], ["_exclusions", [], [[]]] ];
if (_sector isEqualTo "") exitWith { [] };

private _created = [];
private _sectorPos = markerPos _sector;

// Sector type
private _isMilitary = (_sector in sectors_military);
private _isTown     = (_sector in sectors_bigtown) || (_sector in sectors_capture);
private _isFactory  = (_sector in sectors_factory);
private _isTower    = (_sector in sectors_tower);

// Readiness and scaling
private _readiness = if (!isNil "KPLIB_enemyReadiness") then { KPLIB_enemyReadiness } else { combat_readiness };
private _opforFactor = [] call KPLIB_fnc_getOpforFactor;

private _base = 0;
if (_isMilitary) then { _base = 2; };
if (_isFactory)  then { _base = 1 max _base; };
if (_isTown)     then { _base = 1 max _base; };
if (_readiness >= 40) then { _base = _base + 1; };
if (_readiness >= 60) then { _base = _base + 1; };
if (_readiness >= 80) then { _base = _base + 1; };
private _target = round ((_base * _opforFactor) min 4);
if (_target <= 0) exitWith { [] };

// Approach direction
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
private _fnc_angDelta = { params ["_a","_b"]; private _d = abs(_a-_b) % 360; if (_d>180) then {360-_d} else {_d} };

// Candidate ring by type (towers much closer)
private _ringMin = if (_isTower) then { 15 } else { [150, 100] select _isTown };
private _ringMax = if (_isTower) then { 75 } else { [400, 320] select _isTown };

// Tactical siting expression: edges, mild hills, some buildings
private _expr = "0.6*(forest) + 0.5*(hills) + 0.2*(houses) - 0.8*(waterDepth) - 0.3*(meadow)";
private _raw = selectBestPlaces [_sectorPos, (_ringMax + 60), _expr, 35, 40];

// Build exclusion positions (bunkers/statics) if given
private _exclPos = _exclusions apply { getPosWorld _x };

private _cands = [];
{
    private _pos = _x select 0; private _score = _x select 1;
    if (!surfaceIsWater _pos) then {
        private _d = _sectorPos distance2D _pos;
        if (_d >= _ringMin && { _d <= _ringMax }) then {
            // Avoid steep slopes and close to exclusions
            private _slope = acos ((surfaceNormal _pos) select 2) * 57.2958;
            if (_slope <= 12) then {
                private _nearExcl = false;
                { if ((_pos distance2D _x) < 40) exitWith { _nearExcl = true; }; } forEach _exclPos;
                if (!_nearExcl) then {
                    private _dir = [_sectorPos, _pos] call BIS_fnc_dirTo;
                    private _delta = [_dir, _dirToSrc] call _fnc_angDelta;
                    private _arcBonus = 0; if (_delta <= 70) then { _arcBonus = 0.25 };
                    _cands pushBack [_pos, _score + _arcBonus];
                };
            };
        };
    };
} forEach _raw;

_cands = [_cands, [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;

private _placed = 0;
private _spacing = if (_isTower) then { 30 } else { [80, 60] select _isTown };
private _sites = [];
{
    private _p = _x select 0; private _ok = true;
    { if ((_p distance2D _x) < _spacing) exitWith { _ok = false }; } forEach _sites;
    if (_ok) then { _sites pushBack _p; };
    if ((count _sites) >= _target) exitWith {};
} forEach _cands;

while { (count _sites) < _target } do { _sites pushBack (_sectorPos getPos [(_ringMin + random (_ringMax - _ringMin)), random 360]); };

// Place low statics (not in bunkers)
if (isNil "opfor_static_low" || { (count opfor_static_low) == 0 }) exitWith { [] };

{
    private _site = _x;
    private _sClass = selectRandom opfor_static_low;
    private _dir = [_site, _approachSource] call BIS_fnc_dirTo;
    private _stat = createVehicle [_sClass, _site, [], 0, "CAN_COLLIDE"];
    _stat setDir _dir;
    _stat setVectorUp surfaceNormal _site;
    _created pushBack _stat;
    // Crew it
    private _grp = createGroup [GRLIB_side_enemy, true];
    private _crew = units (createVehicleCrew _stat);
    _crew joinSilent _grp;
    { _created pushBack _x } forEach _crew;
} forEach _sites;

_created


