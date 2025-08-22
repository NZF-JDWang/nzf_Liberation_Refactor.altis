if (!isServer) exitWith {};

params [ "_new_fob", "_create_fob_building" ];
private [ "_fob_building", "_fob_pos" ];

// Capture the very first FOB position for eligibility calculations
if (isNil "KPLIB_firstFOBPos") then {
    KPLIB_firstFOBPos = _new_fob;
    publicVariable "KPLIB_firstFOBPos";
};

// Recompute capture eligibility
[] call KPLIB_fnc_updateCaptureEligibility;

// Tell all clients to refresh their markers immediately
[] remoteExec ["KPLIB_fnc_handleEligibilityUpdate", 0, true];

if ( _create_fob_building ) then {
    _fob_pos = [ (_new_fob select 0) + 15, (_new_fob select 1) + 2, 0 ];
    [_fob_pos, 20, true] call KPLIB_fnc_createClearance;
    _fob_building = FOB_typename createVehicle _fob_pos;
    _fob_building setpos _fob_pos;
    _fob_building setVectorUp [0,0,1];
    [_fob_building] call KPLIB_fnc_addObjectInit;
    sleep 1;
    
    // Always store positions in GRLIB_all_fobs for consistency
    GRLIB_all_fobs pushback _fob_pos;
    
    // Request a resource recalculation; authoritative loop will populate resource entries
    please_recalculate = true;
} else {
    // Store the position
    GRLIB_all_fobs pushback _new_fob;
    
    // Authoritative loop will create the resource entry for this FOB
    please_recalculate = true;
};

publicVariable "GRLIB_all_fobs";

// Force immediate resource recalculation after FOB deployment
please_recalculate = true;

// Wait for resource recalculation to complete
[] spawn {
    sleep 2; // Give time for resource calculation
    waitUntil {sleep 0.5; !please_recalculate}; // Wait until calculation is done
    
    // Log completion; resource loop will publish results
    [format ["FOB deployed successfully. Recalculation requested."], "BUILD"] call KPLIB_fnc_log;
};

[] spawn KPLIB_fnc_doSave;

sleep 3;
[_new_fob, 0] remoteExec ["remote_call_fob"];

stats_fobs_built = stats_fobs_built + 1;

FOB_build_in_progress = false;
publicVariable "FOB_build_in_progress";
