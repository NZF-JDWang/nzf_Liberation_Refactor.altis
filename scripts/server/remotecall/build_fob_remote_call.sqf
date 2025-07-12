if (!isServer) exitWith {};

params [ "_new_fob", "_create_fob_building" ];
private [ "_fob_building", "_fob_pos" ];

GRLIB_all_fobs pushback _new_fob;
publicVariable "GRLIB_all_fobs";

// Capture the very first FOB position for eligibility calculations
if (isNil "KPLIB_firstFOBPos") then {
    KPLIB_firstFOBPos = _new_fob;
    publicVariable "KPLIB_firstFOBPos";
};

// Recompute capture eligibility
[] call KPLIB_fnc_updateCaptureEligibility;

// Tell all clients to refresh their markers immediately
[] call KPLIB_fnc_handleEligibilityUpdate;

if ( _create_fob_building ) then {
    _fob_pos = [ (_new_fob select 0) + 15, (_new_fob select 1) + 2, 0 ];
    [_fob_pos, 20, true] call KPLIB_fnc_createClearance;
    _fob_building = FOB_typename createVehicle _fob_pos;
    _fob_building setpos _fob_pos;
    _fob_building setVectorUp [0,0,1];
    [_fob_building] call KPLIB_fnc_addObjectInit;
    sleep 1;
};

[] spawn KPLIB_fnc_doSave;

sleep 3;
[_new_fob, 0] remoteExec ["remote_call_fob"];

stats_fobs_built = stats_fobs_built + 1;

FOB_build_in_progress = false;
publicVariable "FOB_build_in_progress";
