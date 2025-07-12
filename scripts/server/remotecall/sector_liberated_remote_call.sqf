params ["_liberated_sector"];

private _combat_readiness_increase = 0;
switch (true) do {
    case (_liberated_sector in sectors_bigtown):    {_combat_readiness_increase = floor (random 10) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_capture):    {_combat_readiness_increase = floor (random 6) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_military):   {_combat_readiness_increase = 5 + (floor (random 11)) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_factory):    {_combat_readiness_increase = 3 + (floor (random 7)) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_tower):      {_combat_readiness_increase = floor (random 4);};
};

combat_readiness = combat_readiness + _combat_readiness_increase;
if (combat_readiness > 100.0 && GRLIB_difficulty_modifier <= 2.0) then {combat_readiness = 100.0};
stats_readiness_earned = stats_readiness_earned + _combat_readiness_increase;

blufor_sectors pushback _liberated_sector; publicVariable "blufor_sectors";

// FOURTH_EDIT - Change marker visuals to friendly variant globally
private _origType = markerType _liberated_sector;
private _newType = _origType;
if ((_origType select [0,2]) in ["o_", "n_"]) then {
    // Convert o_mytype -> b_mytype (take substring after first 2 chars)
    private _suffix = _origType select [2, (count _origType) - 2];
    _newType = ("b_" + _suffix);
};
_liberated_sector setMarkerType _newType;
_liberated_sector setMarkerColor GRLIB_color_friendly;

[_liberated_sector, 0] remoteExecCall ["remote_call_sector"];
stats_sectors_liberated = stats_sectors_liberated + 1;

// Recalculate capture eligibility so clients update their maps
[] call KPLIB_fnc_updateCaptureEligibility;

// Broadcast refresh to clients
[] remoteExec ["KPLIB_fnc_handleEligibilityUpdate", 0, true];

// Add captured sector connection to line history so it persists after reload
if (isNil "KPLIB_captureLineHistory") then { KPLIB_captureLineHistory = [] };
// Find the last pair that referenced this sector (if any)
private _prevPair = [];
if (!isNil "KPLIB_captureEligiblePairs") then {
    {
        if ((_x select 0) == _liberated_sector) exitWith { _prevPair = _x };
    } forEach KPLIB_captureEligiblePairs;
};
if (!(_prevPair isEqualTo [])) then {
    // Ensure uniqueness and store
    if (!((_prevPair select 0) in (KPLIB_captureLineHistory apply { _x select 0 }))) then {
        KPLIB_captureLineHistory pushBack _prevPair;
        publicVariable "KPLIB_captureLineHistory";
    };
};

// --- Escalation decay: capture progress reduces over-garrisoned rear sectors ---
if (isNil "KPLIB_sectorEscalation") then { KPLIB_sectorEscalation = createHashMap; };
{
    private _esc = KPLIB_sectorEscalation get _x;
    if (isNil "_esc") then {_esc = 1};
    if (_esc > 1) then {
        _esc = _esc - 0.2;              // -20 % per captured sector
        if (_esc < 1) then {_esc = 1};
        KPLIB_sectorEscalation set [_x, _esc];
    };
} forEach (sectors_allSectors - blufor_sectors - [_liberated_sector]);
publicVariable "KPLIB_sectorEscalation";
// -----------------------------------------------------------------------------

reset_battlegroups_ai = true; publicVariable "reset_battlegroups_ai";

if (_liberated_sector in sectors_factory) then {
    {
        if (_liberated_sector in _x) exitWith {KP_liberation_production = KP_liberation_production - [_x];};
    } forEach KP_liberation_production;

    private _sectorFacilities = (KP_liberation_production_markers select {_liberated_sector == (_x select 0)}) select 0;
    KP_liberation_production pushBack [
        markerText _liberated_sector,
        _liberated_sector,
        1,
        [],
        _sectorFacilities select 1,
        _sectorFacilities select 2,
        _sectorFacilities select 3,
        3,
        KP_liberation_production_interval,
        0,
        0,
        0
    ];
};

[_liberated_sector] spawn F_cr_liberatedSector;

if ((random 100) <= KP_liberation_cr_wounded_chance || (count blufor_sectors) == 1) then {
    [_liberated_sector] spawn civrep_wounded_civs;
};

asymm_blocked_sectors pushBack [_liberated_sector, time];
publicVariable "asymm_blocked_sectors";

[] spawn check_victory_conditions;

sleep 1;

[] spawn KPLIB_fnc_doSave;

sleep 45;

if (GRLIB_endgame == 0) then {
    if (
        !(_liberated_sector in sectors_tower)
        && {
            (random (150 / (GRLIB_difficulty_modifier * GRLIB_csat_aggressivity))) < (combat_readiness - 15)
            || _liberated_sector in sectors_bigtown
        }
        && {[] call KPLIB_fnc_getOpforCap < GRLIB_battlegroup_cap}
    ) then {
        [_liberated_sector, (random 100) < 45] spawn spawn_battlegroup;
    };
};
