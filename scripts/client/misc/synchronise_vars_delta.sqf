/*
    File: synchronise_vars_delta.sqf
    Purpose: Client-side handler for versioned delta synchronization of mission state.
    Author: Refactor by AI assistant (based on KP Liberation original sync script)
*/

// Client delta sync enabled

// More robust wait with timeout
private _startTime = diag_tickTime;
private _timeout = 60; // 60 seconds timeout

waitUntil {
    if ((diag_tickTime - _startTime) > _timeout) then {
        true // exit waitUntil on timeout
    } else {
        if (!isNil "sync_vars_full") then {
            true
        } else {
            sleep 0.1;
            false
        }
    }
};

private _applyFull = {
    params ["_payload"];
    _payload params [["_rev", 0], ["_vals", []]]; // full snapshot has 2 elements
    // _vals is full 17-element array
    if ((_vals isEqualType []) && {(count _vals) == 17}) then {
        KP_liberation_fob_resources      = _vals select 0;
        KP_liberation_supplies_global    = _vals select 1;
        KP_liberation_ammo_global        = _vals select 2;
        KP_liberation_fuel_global        = _vals select 3;
        unitcap                          = _vals select 4;
        KP_liberation_heli_count         = _vals select 5;
        KP_liberation_plane_count        = _vals select 6;
        KP_liberation_heli_slots         = _vals select 7;
        KP_liberation_plane_slots        = _vals select 8;
        combat_readiness                 = _vals select 9;
        resources_intel                  = _vals select 10;
        infantry_cap                     = _vals select 11;
        KP_liberation_civ_rep            = _vals select 12;
        KP_liberation_guerilla_strength  = _vals select 13;
        infantry_weight                  = _vals select 14;
        armor_weight                     = _vals select 15;
        air_weight                       = _vals select 16;

        // Keep local UI variables in sync with globals on every sync
        KP_liberation_supplies = KP_liberation_supplies_global;
        KP_liberation_ammo     = KP_liberation_ammo_global;
        KP_liberation_fuel     = KP_liberation_fuel_global;

        // Standardize FOB references to positions (avoid object/array mix)
        if !(KP_liberation_fob_resources isEqualTo []) then {
            KP_liberation_fob_resources = KP_liberation_fob_resources apply {
                private _ref = _x select 0;
                if (typeName _ref == "OBJECT") then {
                    _x set [0, getPos _ref];
                };
                _x
            };
        };

        missionNamespace setVariable ["sync_last_rev", _rev];
        
        systemChat format ["[SYNC] Full sync applied - rev %1, resources: S=%2 A=%3 F=%4", _rev, KP_liberation_supplies_global, KP_liberation_ammo_global, KP_liberation_fuel_global];
        // Debug logging (silent)
        // Signal UI refresh
        synchro_done = true;
    } else {
        // Error handling for malformed data (silent)
    };
};
missionNamespace setVariable ["KPLIB_applyFullSync", _applyFull];

// Apply the snapshot we already have (ensures baseline before deltas)
[] spawn {
    // Give server time to publish initial state
    sleep 2;
    
    private _payload = missionNamespace getVariable ["sync_vars_full", []];
    private _attempts = 0;
    
    // Try multiple times to get sync data
    while {(_payload isEqualTo []) && (_attempts < 10)} do {
        sleep 1;
        _payload = missionNamespace getVariable ["sync_vars_full", []];
        _attempts = _attempts + 1;
    };
    
    if !(_payload isEqualTo []) then { 
        _payload call (missionNamespace getVariable "KPLIB_applyFullSync");
    } else {
        // Initialize with safe defaults immediately
        [] call {
            if (isNil "KP_liberation_fob_resources") then {KP_liberation_fob_resources = [];};
            if (isNil "KP_liberation_supplies_global") then {KP_liberation_supplies_global = 0;};
            if (isNil "KP_liberation_ammo_global") then {KP_liberation_ammo_global = 0;};
            if (isNil "KP_liberation_fuel_global") then {KP_liberation_fuel_global = 0;};
            if (isNil "unitcap") then {unitcap = 1;};
            if (isNil "KP_liberation_heli_count") then {KP_liberation_heli_count = 0;};
            if (isNil "KP_liberation_plane_count") then {KP_liberation_plane_count = 0;};
            if (isNil "KP_liberation_heli_slots") then {KP_liberation_heli_slots = 0;};
            if (isNil "KP_liberation_plane_slots") then {KP_liberation_plane_slots = 0;};
            if (isNil "combat_readiness") then {combat_readiness = 0;};
            if (isNil "resources_intel") then {resources_intel = 0;};
            if (isNil "infantry_cap") then {infantry_cap = 50;};
            if (isNil "KP_liberation_civ_rep") then {KP_liberation_civ_rep = 0;};
            if (isNil "KP_liberation_guerilla_strength") then {KP_liberation_guerilla_strength = 0;};
            if (isNil "infantry_weight") then {infantry_weight = 33;};
            if (isNil "armor_weight") then {armor_weight = 33;};
            if (isNil "air_weight") then {air_weight = 33;};
        };
    };
};

private _applyDelta = {
    params ["_payload"];
    _payload params [["_rev", 0], ["_changes", []]]; // delta snapshot

    private _last = missionNamespace getVariable ["sync_last_rev", -1];

    // Ignore if we haven't processed a full snapshot yet
    if (_last == -1) exitWith {
        // No baseline available, ignoring delta
    };

    // More resilient delta processing - allow catching up if we're not too far behind
    private _revDiff = _rev - _last;
    if (_revDiff <= 0) exitWith {
        // Old revision, ignoring delta
    };
    
    if (_revDiff > 20) exitWith {
        // Gap too large, waiting for full sync
        // Reset last_rev to trigger full sync
        missionNamespace setVariable ["sync_last_rev", -1];
    };

    // Apply changes
    {
        private _idx = _x select 0;
        private _val = _x select 1;
        switch (_idx) do {
            case 0:  {KP_liberation_fob_resources     = _val;};
            case 1:  {KP_liberation_supplies_global   = _val; KP_liberation_supplies = KP_liberation_supplies_global;};
            case 2:  {KP_liberation_ammo_global       = _val; KP_liberation_ammo     = KP_liberation_ammo_global;};
            case 3:  {KP_liberation_fuel_global       = _val; KP_liberation_fuel     = KP_liberation_fuel_global;};
            case 4:  {unitcap                         = _val;};
            case 5:  {KP_liberation_heli_count        = _val;};
            case 6:  {KP_liberation_plane_count       = _val;};
            case 7:  {KP_liberation_heli_slots        = _val;};
            case 8:  {KP_liberation_plane_slots       = _val;};
            case 9:  {combat_readiness                = _val;};
            case 10: {resources_intel                 = _val;};
            case 11: {infantry_cap                    = _val;};
            case 12: {KP_liberation_civ_rep           = _val;};
            case 13: {KP_liberation_guerilla_strength = _val;};
            case 14: {infantry_weight                 = _val;};
            case 15: {armor_weight                    = _val;};
            case 16: {air_weight                      = _val;};
        };
    } forEach _changes;

    missionNamespace setVariable ["sync_last_rev", _rev];
    
    systemChat format ["[SYNC] Delta sync applied - rev %1, changes: %2", _rev, count _changes];
    // Delta applied (silent)
    // Signal UI refresh
    synchro_done = true;
};
missionNamespace setVariable ["KPLIB_applyDeltaSync", _applyDelta];

// ---------------- Event Handlers -----------------

"sync_vars_full" addPublicVariableEventHandler {
    params ["_name", "_value"];
    _value call (missionNamespace getVariable "KPLIB_applyFullSync");
};

"sync_vars_delta" addPublicVariableEventHandler {
    params ["_name", "_value"];
    _value call (missionNamespace getVariable "KPLIB_applyDeltaSync");
};

// Signal done for scripts that wait on it
one_synchro_done = true;
synchro_done = true;

// Mark sync system as initialized
missionNamespace setVariable ["sync_last_rev", 0]; // Initialize with 0 instead of leaving as nil

// Emergency sync recovery function (for debug console use)
KPLIB_emergencySync = {
    private _fullState = missionNamespace getVariable ["sync_vars_full", []];
    if !(_fullState isEqualTo []) then {
        _fullState call (missionNamespace getVariable "KPLIB_applyFullSync");
        true
    } else {
        false
    }
};

// Sync status check function (for debug console use)
KPLIB_syncStatus = {
    private _lastRev = missionNamespace getVariable ["sync_last_rev", "NONE"];
    private _fullExists = !isNil "sync_vars_full";
    private _deltaExists = !isNil "sync_vars_delta";
    private _handlersExist = (!isNil {missionNamespace getVariable "KPLIB_applyFullSync"}) && (!isNil {missionNamespace getVariable "KPLIB_applyDeltaSync"});
    
    // Return status instead of displaying
    private _varsOk = !isNil "KP_liberation_supplies_global" && !isNil "combat_readiness" && !isNil "unitcap";
    [_lastRev, _fullExists, _deltaExists, _handlersExist, _varsOk]
}; 