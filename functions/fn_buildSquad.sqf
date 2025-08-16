/*
    File: fn_buildSquad.sqf
    Author: Liberation Refactor - Squad overhaul
    Description:
        Builds a randomized infantry squad composition that still follows
        a realistic structure of Squad Leader + 2 fire-teams (4 men each).
        Each fire-team: Team Leader / Automatic Rifleman / Grenadier or Specialist / Rifleman-AT|AA|Rifleman|Medic.

    Parameter(s):
        _variant (String) – "std" | "inf" | "tank" | "air". Defaults to "std".

    Returns:
        Array of classname strings for the squad.
*/

params [ ["_variant", "std", [""]] ];

// Helper local function – returns one fire-team as array
private _makeFireteam = {
    /* Composition indices
        0 – Team Leader / Grenadier lead
        1 – Automatic Rifleman (AR / HeavyGunner)
        2 – Specialist / Rifleman / Medic
        3 – AT / AA / Rifleman
    */
    private _ft = [];

    // Slot 0 – Team leader / Grenadier
    _ft pushBack (selectRandom [opfor_grenadier,opfor_team_leader]);

    // Slot 1 – MG / Heavy MG
    _ft pushBack (selectRandom [opfor_machinegunner, opfor_heavygunner]);

    // Slot 2 – Rifleman / Medic 
    _ft pushBack (selectRandom [opfor_rifleman, opfor_rifleman, opfor_medic, opfor_marksman]);

    // Slot 3 – Anti-tank / Anti-air / Rifleman
    _ft pushBack (selectRandom [opfor_rpg, opfor_at, opfor_aa, opfor_rifleman]);

    _ft
};

// Base squad leader is always present
private _squad = [opfor_squad_leader];

switch (toLower _variant) do {
    case "tank": {
        // Two fire-teams but bias towards AT weapons
        {
            private _ft = call _makeFireteam;
            // Force extra AT on last slot
            _ft set [3, selectRandom [opfor_rpg, opfor_at]];
            _squad append _ft;
        } forEach [0,1];
        // Add an additional dedicated AT specialist to reach 9-10 men
        _squad pushBack opfor_at;
    };

    case "air": {
        // Bias towards AA
        {
            private _ft = call _makeFireteam;
            _ft set [3, selectRandom [opfor_aa, opfor_rpg]];
            _squad append _ft;
        } forEach [0,1];
        _squad pushBack opfor_aa;
    };

    case "inf": {
        // Infantry-centric – add marksman / sniper
        {
            private _ft = call _makeFireteam;
            _squad append _ft;
        } forEach [0,1];
        _squad pushBack (selectRandom [opfor_marksman, opfor_sharpshooter, opfor_sniper]);
    };

    default {   // "std"
        {
            private _ft = call _makeFireteam;
            _squad append _ft;
        } forEach [0,1];
        // Optional extra member (10-man squads 30% of the time)
        if ((random 100) < 30) then {
            _squad pushBack (selectRandom [opfor_medic, opfor_engineer, opfor_rifleman]);
        };
    };
};

_squad