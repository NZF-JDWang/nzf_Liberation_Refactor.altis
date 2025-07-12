/*
    File: fn_updateCaptureEligibility.sqf
    Author: Liberation QoL extension

    Description:
        Calculates the list of enemy sectors that are currently eligible for capture
        (contiguous to the BLUFOR front or, before any sector is blue, the two closest
        sectors to the very first FOB).  Also chooses ONE BLUFOR source position for
        each eligible sector so the client can draw a single connector line.

        Result is stored in the public variable
            KPLIB_captureEligiblePairs = [ [enemyMarkerName, sourceMarkerOrPos], ... ]
        where sourceMarkerOrPos is either a marker name (STRING) or a POSITION array.
*/

if (!isServer) exitWith {};

// Bail out until at least one FOB exists
if (isNil "KPLIB_firstFOBPos") then {
    if (!isNil "GRLIB_all_fobs" && {GRLIB_all_fobs isNotEqualTo []}) then {
        KPLIB_firstFOBPos = GRLIB_all_fobs select 0;
    };
};
if (isNil "KPLIB_firstFOBPos") exitWith {};

private _eligiblePairs = [];
private _enemySectors  = sectors_allSectors - blufor_sectors;

// 1.  No sector captured yet  → take TWO closest sectors to the first FOB
if (blufor_sectors isEqualTo []) then {
    private _sorted = _enemySectors apply {
        [ (markerPos _x) distance2d KPLIB_firstFOBPos, _x ]
    };
    _sorted sort true;
    private _count = [2, count _sorted] select ((count _sorted) < 2);
    for "_i" from 0 to (_count - 1) do {
        private _enemyMarker = (_sorted select _i) select 1;
        _eligiblePairs pushBack [ _enemyMarker, KPLIB_firstFOBPos ];
    };
} else {
    // 2. Front already exists → take the TWO enemy sectors with the smallest distance
    //    to ANY blufor-sector (contiguous front, max two capture slots)

    private _candidates = [];

    {
        private _enemy = _x;
        private _nearestBlu = "";
        private _dist = 1e9;
        {
            private _d = (markerPos _enemy) distance2d (markerPos _x);
            if (_d < _dist) then {
                _dist = _d;
                _nearestBlu = _x;
            };
        } forEach blufor_sectors;
        _candidates pushBack [_dist, _enemy, _nearestBlu];
    } forEach _enemySectors;

    _candidates sort true;   // sort by distance ascending

    private _limit = [2, count _candidates] select ((count _candidates) < 2);
    for "_i" from 0 to (_limit - 1) do {
        private _c = _candidates select _i;
        _eligiblePairs pushBack [ _c select 1, _c select 2 ];
    };
};

// Publish the result so every client can refresh markers
KPLIB_captureEligiblePairs = _eligiblePairs;
publicVariable "KPLIB_captureEligiblePairs";
