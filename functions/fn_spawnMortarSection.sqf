/*
    File: fn_spawnMortarSection.sqf
    Spawns a two-gun mortar section on the far side of the town relative to the BLUFOR approach,
    ensuring ~50 m of building-free space and reasonably flat terrain. Returns created vehicles and crew.

    Params:
      _sector - sector marker [STRING]

    Returns: [ARRAY] created objects (mortars and crew)
*/

params [["_sector","",[""]]];
if (_sector isEqualTo "") exitWith {[]};

private _created = [];
private _secPos = markerPos _sector;

// Determine approach source to place mortars opposite side
private _src = objNull;
if (!isNil "KPLIB_captureEligiblePairs") then {
    private _idx = KPLIB_captureEligiblePairs findIf { (_x select 0) isEqualTo _sector };
    if (_idx >= 0) then {
        private _s = (KPLIB_captureEligiblePairs select _idx) select 1;
        _src = if (_s isEqualType "") then { markerPos _s } else { _s };
    };
};
if (isNil "_src" || {_src isEqualTo objNull}) then { _src = [_secPos] call KPLIB_fnc_getNearestBluforObjective; };

private _dirToSrc = [_secPos, _src] call BIS_fnc_dirTo;      // BLUFOR→sector
private _oppDir = (_dirToSrc + 180) % 360;                   // opposite side
// Randomize the center direction around the opposite side so it's not always exact opposite
private _centerDir = (_oppDir + (random 120 - 60)) % 360;    // ±60° around opposite

// Determine whether to use heavy artillery instead of mortars at high aggression
private _readiness = if (!isNil "KPLIB_enemyReadiness") then { KPLIB_enemyReadiness } else { combat_readiness };
private _useArtillery = false;
private _artAvail = (!isNil "opfor_artillery") && { (typeName opfor_artillery) == "ARRAY" } && { (count opfor_artillery) > 0 };
private _morAvail = (!isNil "opfor_mortars") && { (typeName opfor_mortars) == "ARRAY" } && { (count opfor_mortars) > 0 };
if (_artAvail && (_readiness >= 80)) then { _useArtillery = true; };

// Scan a ring on the far side (closer: 150–225 m) for open, flat ground with 50 m building clearance
private _bestScore = -1;
private _bestPos = _secPos getPos [200, _centerDir]; // sensible opposite-side fallback, not sector center
for "_i" from 0 to 24 do {
    private _r = 150 + random 75;                // 150–225 m from center
    private _theta = _centerDir + (random 60 - 30); // ±30° around randomized opposite
    private _p = _secPos getPos [_r, _theta];
    if (!surfaceIsWater _p) then {
        // Enforce 50 m clearance from buildings
        private _nearBlds = nearestObjects [_p, ["House"], 50];
        if ((count _nearBlds) == 0) then {
            // Check flatness in a ~20 m ring
            private _flat = true; private _samples = 8; private _sum = 0;
            for "_k" from 0 to (_samples - 1) do {
                private _a = _k * (360/_samples);
                private _q = _p getPos [20, _a];
                private _slope = acos ((surfaceNormal _q) select 2) * 57.2958;
                _sum = _sum + _slope;
                if (_slope > 7) exitWith { _flat = false };
            };
            if (_flat) then {
                private _score = 100 - _sum; // flatter is better
                if (_score > _bestScore) then { _bestScore = _score; _bestPos = _p; };
            };
        };
    };
};

// If ring scan failed to find a candidate, probe along randomized opposite bearings until we hit land
if (_bestScore < 0) then {
    private _dirs = [_centerDir - 45, _centerDir, _centerDir + 45];
    private _found = false;
    {
        private _d = _x;
        private _probe = 150;
        for "_step" from 0 to 10 do {
            private _try = _secPos getPos [_probe, _d];
            if (!surfaceIsWater _try) then {
                if ((count (nearestObjects [_try, ["House"], 50])) == 0) then {
                    // quick center slope check
                    private _slope = acos ((surfaceNormal _try) select 2) * 57.2958;
                    if (_slope <= 7) exitWith { _bestPos = _try; _found = true; };
                };
            };
            _probe = _probe + 20;
        };
        if (_found) exitWith {};
    } forEach _dirs;
};

// Spawn 2 guns slightly offset and in the SAME group
if (!_morAvail && !_artAvail) exitWith { [] };
private _classes = if (_useArtillery) then { opfor_artillery } else { opfor_mortars };
private _cls = selectRandom _classes;

private _grpMortars = createGroup [GRLIB_side_enemy, true];
private _perp = (_oppDir + 90) % 360; // lay guns side-by-side relative to facing
private _spacing = if (_useArtillery) then { 12 } else { 8 };

for "_g" from 0 to 1 do {
    private _pos = _bestPos getPos [(_g * _spacing), _perp];
    private _veh = createVehicle [_cls, _pos, [], 0, "CAN_COLLIDE"];
    _veh setDir _oppDir;
    _veh setVectorUp surfaceNormal _pos;
    private _crewUnits = units (createVehicleCrew _veh);
    _crewUnits joinSilent _grpMortars;
    { _created pushBack _x } forEach (_crewUnits + [_veh]);
};

// Register mortar/artillery group with LAMBS WP so it can receive indirect fire tasks
if (!isNil "lambs_wp_fnc_taskArtilleryRegister") then {
    [_grpMortars] call lambs_wp_fnc_taskArtilleryRegister;
};

_created


