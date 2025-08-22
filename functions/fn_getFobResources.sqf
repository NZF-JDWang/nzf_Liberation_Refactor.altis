/*
    File: fn_getFobResources.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-05-08
    Last Update: 2025-08-17 (refactor: support object/position references)
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets the FOB resource data in format [<FOB_REF>, <SUPPLIES>, <AMMO>, <FUEL>, <HAS_AIR_BUILD>, <HAS_REC_WORKSHOP>].
        FOB_REF can be either the FOB object or the FOB position.

    Parameter(s):
        _fob - FOB object or position to get resources for [OBJECT|POSITION, defaults to player FOB]

    Returns:
        FOB resource data [ARRAY]
*/

#define NO_RESULT [[0, 0, 0], 0, 0, 0, false, false]

params [
    ["_fob", [0, 0, 0], [objNull, []], [0, 2, 3]]
];

// Normalize input to a position for matching
private _queryPos = if (typeName _fob == "OBJECT") then { getPos _fob } else { _fob };

// Find the first entry whose reference (position) is within FOB range
private _idx = KP_liberation_fob_resources findIf {
    private _refPos = _x select 0;
    (_refPos distance2D _queryPos) < GRLIB_fob_range
};

if (_idx >= 0) then { KP_liberation_fob_resources select _idx } else { NO_RESULT } // return
