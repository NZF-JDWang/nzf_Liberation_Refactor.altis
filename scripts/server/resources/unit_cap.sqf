unitcap = 0;
KP_liberation_heli_count = 0;
KP_liberation_plane_count = 0;

while {true} do {
    // --- Count friendly infantry (excluding units near base unless player) ---
    unitcap = {
        (side group _x == GRLIB_side_friendly) &&
        alive _x &&
        ((_x distance startbase) > 250 || isPlayer _x)
    } count allUnits;

    // --- Filter live, non-UAV air vehicles that belong to the playable faction ---
    private _airVehs = vehicles select {
        (toLower (typeOf _x)) in KPLIB_b_air_classes &&
        !([typeOf _x] call KPLIB_fnc_isClassUAV) &&
        alive _x &&
        !(_x getVariable ["KP_liberation_preplaced", false])
    };

    KP_liberation_heli_count  = {_x isKindOf "Helicopter"} count _airVehs;
    KP_liberation_plane_count = {_x isKindOf "Plane"}      count _airVehs;

    // Update cadence (was 1 s) – 10 s is sufficient and reduces server load by 90%
    sleep 10;
};
