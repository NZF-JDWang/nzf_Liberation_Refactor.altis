/*
    File: synchronise_vars_delta.sqf
    Purpose: Efficient versioned delta synchronization of global mission variables from server to clients.
    Author: Refactor by AI assistant (based on KP Liberation original sync script)
*/

scriptName "KPLIB_syncVarsDeltaServer";

// Ensure this runs only on server
if (!isServer) exitWith {};

// ---------- Wait until essential globals available ----------
waitUntil { !isNil "save_is_loaded" };
waitUntil { !isNil "KP_liberation_fob_resources" };
waitUntil { !isNil "KP_liberation_supplies_global" };
waitUntil { !isNil "KP_liberation_ammo_global" };
waitUntil { !isNil "KP_liberation_fuel_global" };
waitUntil { !isNil "combat_readiness" };
waitUntil { !isNil "unitcap" };
waitUntil { !isNil "KP_liberation_heli_count" };
waitUntil { !isNil "KP_liberation_plane_count" };
waitUntil { !isNil "KP_liberation_heli_slots" };
waitUntil { !isNil "KP_liberation_plane_slots" };
waitUntil { !isNil "resources_intel" };
waitUntil { !isNil "infantry_cap" };
waitUntil { !isNil "KP_liberation_civ_rep" };
waitUntil { !isNil "KP_liberation_guerilla_strength" };
waitUntil { !isNil "infantry_weight" };
waitUntil { !isNil "armor_weight" };
waitUntil { !isNil "air_weight" };
waitUntil { save_is_loaded };

// ---------- Helper to gather current state ----------
private _collectState = {
    [
        KP_liberation_fob_resources,   // 0
        KP_liberation_supplies_global, // 1
        KP_liberation_ammo_global,     // 2
        KP_liberation_fuel_global,     // 3
        unitcap,                       // 4
        KP_liberation_heli_count,      // 5
        KP_liberation_plane_count,     // 6
        KP_liberation_heli_slots,      // 7
        KP_liberation_plane_slots,     // 8
        combat_readiness,              // 9
        resources_intel,               // 10
        infantry_cap,                  // 11
        KP_liberation_civ_rep,         // 12
        KP_liberation_guerilla_strength,// 13
        infantry_weight,               // 14
        armor_weight,                  // 15
        air_weight                     // 16
    ]
};

// ---------- Initial full snapshot ----------
private _currentState = [] call _collectState;
private _oldState     = +_currentState;   // deep copy

sync_rev         = 0;
sync_vars_full   = [sync_rev, _currentState];
sync_vars_delta  = [];
publicVariable "sync_vars_full";
publicVariable "sync_vars_delta"; // ensure variable exists for EH on clients

private _lastFull   = diag_tickTime;
private _fullEvery  = 30;   // seconds

// ---------- Main loop ----------
while { true } do {
    sleep 1;   // poll interval (same as improved classic script)

    _currentState = [] call _collectState;
    private _changes = [];

    {
        if !(_x isEqualTo (_oldState select _forEachIndex)) then {
            _changes pushBack [_forEachIndex, _x];
        };
    } forEach _currentState;

    if !(_changes isEqualTo []) then {
        sync_rev = sync_rev + 1;
        sync_vars_delta = [sync_rev, _changes];
        publicVariable "sync_vars_delta";
        _oldState = +_currentState;
    };

    if ((diag_tickTime - _lastFull) > _fullEvery) then {
        sync_rev = sync_rev + 1;
        sync_vars_full = [sync_rev, _currentState];
        publicVariable "sync_vars_full";
        _lastFull = diag_tickTime;
        _oldState = +_currentState; // keep states aligned
    };
}; 