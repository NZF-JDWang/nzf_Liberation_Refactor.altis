/*
    Revised: Terrain-aware, approach-biased patrol waypoint generation
    - Always SAFE behaviour, LIMITED speed
    - Short pauses (10–15 s)
    - Foot patrols: 5 points loop; Vehicle patrols: 3–4 points or idle sentry
    - Bias toward BLUFOR approach direction using capture eligibility pairs when available
*/

params ["_grp", "_flagpos"]; // _flagpos is the sector center position

private _basepos = getPos (leader _grp);
private _is_infantry = (vehicle (leader _grp) == (leader _grp));

// Enable LAMBS reinforce network so patrols react to nearby contacts
_grp setVariable ["lambs_danger_enableGroupReinforce", true, true];
_grp setVariable ["lambs_danger_dangerRadio", true, true];

// Small helper: compute direction from A to B (degrees)
private _fnc_dirTo = {
    params ["_from", "_to"];
    [_from, _to] call BIS_fnc_dirTo
};

// Try to find the sector marker for this position (best effort)
private _sectorMarker = "";
if (!isNil "sectors_allSectors") then {
    private _best = 1e9;
    {
        private _d = (markerPos _x) distance2D _flagpos;
        if (_d < _best) then { _best = _d; _sectorMarker = _x; };
    } forEach sectors_allSectors;
};

// Compute approach source position and direction (from BLUFOR to sector)
private _approachSourcePos = objNull;
if (!isNil "KPLIB_captureEligiblePairs" && {_sectorMarker != ""}) then {
    private _idx = KPLIB_captureEligiblePairs findIf { (_x select 0) isEqualTo _sectorMarker };
    if (_idx >= 0) then {
        private _src = (KPLIB_captureEligiblePairs select _idx) select 1;
        _approachSourcePos = if (_src isEqualType "") then { markerPos _src } else { _src };
    };
};
if (isNil "_approachSourcePos" || { _approachSourcePos isEqualTo objNull }) then {
    _approachSourcePos = [_flagpos] call KPLIB_fnc_getNearestBluforObjective;
};
// Compute approach direction with robust fallbacks
private _approachDir = 0;
if (_approachSourcePos isEqualType []) then {
    if (_approachSourcePos isEqualTo []) then { _approachDir = random 360; } else { _approachDir = [_approachSourcePos, _flagpos] call _fnc_dirTo; };
} else {
    if (!isNull _approachSourcePos) then { _approachDir = [_approachSourcePos, _flagpos] call _fnc_dirTo; } else { _approachDir = random 360; };
};

// Helper: angle difference in degrees (0..180)
private _fnc_angleDelta = {
    params ["_a", "_b"]; private _d = abs (_a - _b) % 360; if (_d > 180) then { 360 - _d } else { _d };
};

// Helper: slope in degrees at position
private _fnc_slopeDeg = {
    params ["_p"]; private _n = surfaceNormal _p; private _dot = (_n select 2) min 1 max -1; acos _dot * 57.2958
};

// Generate candidates using selectBestPlaces for a given ring and expression
private _fnc_candidatesForRing = {
    params ["_center", "_rMin", "_rMax", "_expr", "_count"];
    private _radius = _rMax + 50; // search a bit wider; we'll filter by ring later
    // selectBestPlaces [center, radius, expression, precision(step), maxResults]
    private _raw = selectBestPlaces [_center, _radius, _expr, 50, _count];
    private _out = [];
    {
        private _pos = _x select 0; private _val = _x select 1;
        if (!surfaceIsWater _pos) then {
            private _d = _center distance2D _pos;
            if (_d >= _rMin && {_d <= _rMax}) then {
                private _dir = [_center, _pos] call _fnc_dirTo;
                private _delta = [_dir, _approachDir] call _fnc_angleDelta;
                private _arcBonus = 0;
                if (_delta <= 60) then { _arcBonus = 0.35 } else { if (_delta <= 100) then { _arcBonus = 0.15 } else { _arcBonus = 0 } };
                private _slope = [_pos] call _fnc_slopeDeg;
                private _okSlope = _slope <= ([15,10] select !_is_infantry);
                if (_okSlope) then {
                    _out pushBack [_pos, _val + _arcBonus];
                };
            };
        };
    } forEach _raw;
    _out
};

// Expressions tuned for cover/urban/overwatch
private _exprInner = "0.8*(houses) + 0.5*(forest) - 0.8*(waterDepth) - 0.4*(meadow)";
private _exprMid   = "0.7*(forest) + 0.3*(houses) - 0.8*(waterDepth) - 0.3*(meadow)";
private _exprOuter = "0.7*(hills) + 0.4*(forest) - 0.8*(waterDepth) - 0.3*(meadow)";

private _cands = [];
if (_is_infantry) then {
    _cands append ([_flagpos, 200, 350, _exprInner, 24] call _fnc_candidatesForRing);
    _cands append ([_flagpos, 350, 500, _exprMid,   24] call _fnc_candidatesForRing);
    _cands append ([_flagpos, 500, 650, _exprOuter, 24] call _fnc_candidatesForRing);
} else {
    _cands append ([_flagpos, 300, 500, _exprMid,   20] call _fnc_candidatesForRing);
    _cands append ([_flagpos, 500, 800, _exprOuter, 20] call _fnc_candidatesForRing);
    _cands append ([_flagpos, 800, 1000,_exprOuter, 16] call _fnc_candidatesForRing);
};

// Foot-specific bonus: prefer near buildings for inner ring
if (_is_infantry) then {
    {
        private _pos = _x select 0;
        private _bonus = 0;
        if ((_flagpos distance2D _pos) < 400) then {
            private _houses = nearestObjects [_pos, ["House"], 60];
            if ((count _houses) >= 2) then { _bonus = 0.2 } else { if ((count _houses) == 1) then { _bonus = 0.1 } };
        };
        _x set [1, (_x select 1) + _bonus];
    } forEach _cands;
};

// Sort by score descending using BIS_fnc_sortBy
_cands = [_cands, [], { _x select 1 }, "DESCEND"] call BIS_fnc_sortBy;

// Greedy selection with spacing constraint
private _desired = if (_is_infantry) then {5} else {3};
private _spacing = if (_is_infantry) then {80} else {120};
private _selected = [];
{
    private _pos = _x select 0; private _ok = true;
    {
        if ((_pos distance2D _x) < _spacing) exitWith { _ok = false };
    } forEach _selected;
    if (_ok) then { _selected pushBack _pos; };
    if ((count _selected) >= _desired) exitWith {};
} forEach _cands;

// Fallback if not enough: sprinkle random around flag
while { (count _selected) < _desired } do {
    _selected pushBack (_flagpos getPos [150 + random 300, random 360]);
};

// Vehicle: 50–60% chance to be idle sentry depending on sector type
private _vehicleIdle = false;
if (!_is_infantry) then {
    private _idleChance = 0.5;
    if (_sectorMarker != "") then {
        if (_sectorMarker in sectors_military) then { _idleChance = 0.6 };
    };
    _vehicleIdle = (random 1) < _idleChance;
};

// Reset WPs
sleep 1;
while {(count (waypoints _grp)) != 0} do { deleteWaypoint ((waypoints _grp) select 0); };
sleep 0.5;
{ _x doFollow (leader _grp) } forEach units _grp;
sleep 0.5;

// Group-level defaults
_grp setBehaviour "SAFE";
_grp setSpeedMode "LIMITED";

private _wp = objNull;

if (!_is_infantry && _vehicleIdle) then {
    // Pick the best single sentry node facing the approach
    private _sentry = _selected select 0;
    _wp = _grp addWaypoint [_sentry, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "SAFE";
    _wp setWaypointCombatMode "YELLOW";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointCompletionRadius 25;
    _wp setWaypointTimeout [10,12,15];
    // Loop on itself
    _wp = _grp addWaypoint [_sentry, 0];
    _wp setWaypointType "CYCLE";
} else {
    // Build an ordered loop starting near current position
    private _ordered = [];
    private _cursor = _basepos;
    private _pool = +_selected;
    while {(count _pool) > 0} do {
        private _idx = 0; private _best = 1e9;
        {
            private _d = _cursor distance2D _x;
            if (_d < _best) then { _best = _d; _idx = _forEachIndex; };
        } forEach _pool;
        private _p = _pool deleteAt _idx; _ordered pushBack _p; _cursor = _p;
    };

    // Create waypoints with short pauses, SAFE/LIMITED
    {
        _wp = _grp addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointCombatMode "YELLOW";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointCompletionRadius (if (_is_infantry) then {15} else {25});
        _wp setWaypointTimeout [10,12,15];
    } forEach _ordered;

    // Close the loop
    _wp = _grp addWaypoint [_ordered select 0, 0];
    _wp setWaypointType "CYCLE";
};

_grp setCurrentWaypoint [_grp, 0];
