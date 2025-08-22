/*
    File: fn_updateCaptureEligibility.sqf
    Author: Liberation QoL extension

    Description:
        Calculates the list of enemy sectors that are currently eligible for capture
        by selecting the 2 enemy sectors that are closest to ANY existing FOB. Each
        selected sector is paired with its nearest FOB position for connector lines.

        Result is stored in the public variable
            KPLIB_captureEligiblePairs = [ [enemyMarkerName, sourceMarkerOrPos], ... ]
        where sourceMarkerOrPos is either a marker name (STRING) or a POSITION array.
*/

if (!isServer) exitWith {};

// Gather all FOB positions; fallback to first if map didn't initialize yet
private _fobs = [];
if (!isNil "GRLIB_all_fobs" && {GRLIB_all_fobs isNotEqualTo []}) then {
    _fobs = +GRLIB_all_fobs;
};
if (isNil "KPLIB_firstFOBPos") then {
    if (_fobs isNotEqualTo []) then { KPLIB_firstFOBPos = _fobs select 0; publicVariable "KPLIB_firstFOBPos"; };
};
if (_fobs isEqualTo [] && {!isNil "KPLIB_firstFOBPos"}) then { _fobs = [KPLIB_firstFOBPos]; };
if (_fobs isEqualTo []) exitWith {};

private _eligiblePairs = [];
private _enemySectors = sectors_allSectors - blufor_sectors;

// Compute distance from each enemy sector to its nearest FOB
private _scored = [];
{
    private _enemy = _x;
    private _bestDist = 1e9;
    private _bestFOB = objNull;
    {
        private _d = (markerPos _enemy) distance2d _x;
        if (_d < _bestDist) then { _bestDist = _d; _bestFOB = _x; };
    } forEach _fobs;
    _scored pushBack [_bestDist, _enemy, _bestFOB];
} forEach _enemySectors;

// Sort globally by distance to nearest FOB
_scored sort true;

// Take up to 2 closest sectors
private _count = [2, count _scored] select ((count _scored) < 2);
for "_i" from 0 to (_count - 1) do {
    private _e = _scored select _i;
    private _enemyMarker = _e select 1;
    private _nearestFOB = _e select 2;
    _eligiblePairs pushBack [_enemyMarker, _nearestFOB];
};

// Publish the result so every client can refresh markers
KPLIB_captureEligiblePairs = _eligiblePairs;
publicVariable "KPLIB_captureEligiblePairs";

// ---------------------------------------------------------
// Maintain persistent history of pairs for progress lines
if (isNil "KPLIB_captureLineHistory") then { KPLIB_captureLineHistory = [] };
{
    private _enemy = _x select 0;
    // Add only once
    if (!(_enemy in (KPLIB_captureLineHistory apply { _x select 0 }))) then {
        KPLIB_captureLineHistory pushBack _x;
    };
} forEach _eligiblePairs;
publicVariable "KPLIB_captureLineHistory";
// ---------------------------------------------------------
