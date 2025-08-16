[
    "KPLIB_DebugLogging",                           // Unique variable name
    "CHECKBOX",                                     // Setting type
    ["KP Liberation Debug", "Enable debug logging"],     // Display name [label, tooltip]
    "KP Liberation",                                // Category (appears in UI)
    false                                            // Default value (disabled)
] call CBA_fnc_addSetting; 

// --- Fire For Effect (VCOM) artillery class registration ---------------------
// Ensure FFE add-arrays exist so we can register any custom mortars/artillery
if (isNil "RydFFE_Add_Mortar") then { RydFFE_Add_Mortar = [] };
if (isNil "RydFFE_Add_SPMortar") then { RydFFE_Add_SPMortar = [] };
if (isNil "RydFFE_Add_Rocket") then { RydFFE_Add_Rocket = [] };

// After presets initialize, copy our spawn lists into FFE so non-vanilla classes
// are recognized immediately (FFE also auto-detects later as a fallback)
[] spawn {
    waitUntil { (!isNil "opfor_mortars") || (!isNil "opfor_artillery") || time > 2 };

    if (!isNil "opfor_mortars") then {
        private _mort = opfor_mortars apply { toLower _x };
        { if !(_x in RydFFE_Add_Mortar) then { RydFFE_Add_Mortar pushBack _x; }; } forEach _mort;
    };

    if (!isNil "opfor_artillery") then {
        private _arty = opfor_artillery apply { toLower _x };
        { if !(_x in RydFFE_Add_SPMortar) then { RydFFE_Add_SPMortar pushBack _x; }; } forEach _arty;
        // If you include MLRS in opfor_artillery, consider moving those classes to RydFFE_Add_Rocket
    };
};