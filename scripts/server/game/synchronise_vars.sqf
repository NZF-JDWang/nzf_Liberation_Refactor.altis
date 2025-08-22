/*
    File: synchronise_vars.sqf
    Legacy-style publisher: periodically publicVariables all HUD/global state
    to ensure clients always have defined values (no nil/any/NaN in UI).
*/

waitUntil { !isNil "save_is_loaded" };
waitUntil { save_is_loaded };

// Ensure sane defaults exist server-side
if (isNil "combat_readiness") then { combat_readiness = 0; };
if (isNil "KP_liberation_civ_rep") then { KP_liberation_civ_rep = 0; };
if (isNil "unitcap") then { unitcap = 0; };

private _vars = [
    "KP_liberation_fob_resources",
    "KP_liberation_supplies_global",
    "KP_liberation_ammo_global",
    "KP_liberation_fuel_global",
    "KP_liberation_heli_slots",
    "KP_liberation_plane_slots",
    "unitcap",
    "KP_liberation_heli_count",
    "KP_liberation_plane_count",
    "combat_readiness",
    "resources_intel",
    "infantry_cap",
    "KP_liberation_civ_rep",
    "KP_liberation_guerilla_strength",
    "infantry_weight",
    "armor_weight",
    "air_weight"
];

// Initial broadcast
{ publicVariable _x } forEach _vars;

// Periodic refresh
while { true } do {
    { publicVariable _x } forEach _vars;
    sleep 2;
};


