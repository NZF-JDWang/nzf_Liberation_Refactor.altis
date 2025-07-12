/*
    File: fn_getUnitsCount.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-12-03
    Last Update: 2020-05-08
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets the amount of units of given side inside given radius of given position.

    Parameter(s):
        _pos - Description [POSITION, defaults to [0, 0, 0]
        _radius - Description [NUMBER, defaults to 100]
        _side - Description [SIDE, defaults to GRLIB_side_friendly]

    Returns:
        Amount of units [NUMBER]
*/

params [
    ["_pos", [0, 0, 0], [[]], [2, 3]],
    ["_radius", 100, [0]],
    ["_side", GRLIB_side_friendly, [sideEmpty]]
];

// Thresholds to determine if an AIR vehicle should count for sector activation
#define MAX_AIR_ALT 200        // metres AGL
#define MAX_AIR_SPEED 75       // km/h  (~21 m/s)

// Filter infantry / dismounts (altitude < 500 as before)
private _amount = _side countSide ((_pos nearEntities ["Man", _radius]) select {
    !(captive _x) && ((getPosATL _x) select 2 < 500)
});

// Filter vehicles with extra rules for aircraft
private _vehicles = (_pos nearEntities [["Car", "Tank", "Air", "Boat"], _radius]) select {
    count (crew _x) > 0 && {((getPosATL _x) select 2) < 500}
};

{
    private _veh = _x;
    if (_veh isKindOf "Air") then {
        // Require low height AND low speed → avoids high-speed fly-by spawning
        if ( ((getPosATL _veh) select 2) < MAX_AIR_ALT && {speed _veh < MAX_AIR_SPEED} ) then {
            _amount = _amount + (_side countSide (crew _veh));
        };
    } else {
        _amount = _amount + (_side countSide (crew _veh));
    };
} forEach _vehicles;

_amount
