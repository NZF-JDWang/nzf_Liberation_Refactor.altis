/*
    File: fn_getSquadComp.sqf
    Author: KP Liberation Dev Team – modified by Liberation Refactor

    Description:
        Provides a (now randomized) infantry squad composition of classnames.
        For army units it uses KPLIB_fnc_buildSquad to produce a realistic
        Squad Leader + 2×Fire-team structure, with variant bias depending on
        players' weapon usage weights (armor / air / infantry).
        Militia logic is left untouched (lightweight 8–10 man squads).

    Parameter(s):
        _type – "army" or "militia" (String)

    Returns:
        Array of infantry classnames (Array)
*/

params [ ["_type", "army", [""]] ];

private _squadcomp = [];

if (_type == "army") then {
    private _variant = "std";         // default balanced squad
    private _randomchance = 0;

    // Bias towards AT-heavy squads when players field lots of armor
    if (armor_weight > 40) then {
        _randomchance = (armor_weight - 35) * 1.4;
        if ((random 100) < _randomchance) then { _variant = "tank"; };
    };

    // Bias towards AA-heavy squads when players use lots of air assets
    if (air_weight > 40 && {_variant == "std"}) then {
        _randomchance = (air_weight - 35) * 1.4;
        if ((random 100) < _randomchance) then { _variant = "air"; };
    };

    // Infantry-centric variant (more marksmen / snipers)
    if (infantry_weight > 40 && {_variant == "std"}) then {
        _randomchance = (infantry_weight - 35) * 1.4;
        if ((random 100) < _randomchance) then { _variant = "inf"; };
    };

    // Build the squad using the dedicated builder helper
    _squadcomp = [_variant] call KPLIB_fnc_buildSquad;

} else {
    // --- Militia fallback (unchanged) -----------------------------------
    private _multiplier = 1;
    if (GRLIB_unitcap < 1) then { _multiplier = GRLIB_unitcap; };
    while {count _squadcomp < (10 * _multiplier)} do {
        _squadcomp pushBack (selectRandom militia_squad);
    };
};

_squadcomp