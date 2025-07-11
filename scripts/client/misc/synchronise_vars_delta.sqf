/*
    File: synchronise_vars_delta.sqf
    Purpose: Client-side handler for versioned delta synchronization of mission state.
    Author: Refactor by AI assistant (based on KP Liberation original sync script)
*/

scriptName "KPLIB_syncVarsDeltaClient";

if (!hasInterface) exitWith {};

// Wait until the first full snapshot is available
waitUntil {!isNil "sync_vars_full"};

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

        missionNamespace setVariable ["sync_last_rev", _rev];
    };
};
missionNamespace setVariable ["KPLIB_applyFullSync", _applyFull];

// Apply the snapshot we already have (ensures baseline before deltas)
[] call {
    private _payload = missionNamespace getVariable ["sync_vars_full", []];
    if !(_payload isEqualTo []) then { _payload call (missionNamespace getVariable "KPLIB_applyFullSync"); };
};

private _applyDelta = {
    params ["_payload"];
    _payload params [["_rev", 0], ["_changes", []]]; // delta snapshot

    private _last = missionNamespace getVariable ["sync_last_rev", -1];

    // Ignore if we haven't processed a full snapshot yet
    if (_last == -1) exitWith {};

    // Handle ordering; if we missed one, wait for next full snapshot
    if (_rev != _last + 1) exitWith {};

    {
        private _idx = _x select 0;
        private _val = _x select 1;
        switch (_idx) do {
            case 0:  {KP_liberation_fob_resources     = _val;};
            case 1:  {KP_liberation_supplies_global   = _val;};
            case 2:  {KP_liberation_ammo_global       = _val;};
            case 3:  {KP_liberation_fuel_global       = _val;};
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