/*
    Author: Genesis

    Description:
        Plants a mine

    Parameter(s):
        0: OBJECT - Unit to plant a mine
        1: ARRAY - Array containing mine type and magazine name

    Returns:
        NOTHING
*/

params [
    ["_unit", objNull, [objNull]],  // Ensure _unit is an object
    ["_mineArray", [], [[]]]  // Ensure _mineArray is an array
];

if (lifeState _unit != "HEALTHY" || {isPlayer _unit}) exitWith {};

if (VCM_Debug) then {systemchat format ["VCOM: %1 PLACING MINE", _unit];};

private _mineType = _mineArray select 0;

// Let's see if we can place a scripted version of the item.
private _testName = _mineType + "_scripted";
private _testMine = _testName createVehiclelocal [0,0,0];
if !(isNull _testMine) then {
    _mineType = _testName;
    deleteVehicle _testMine;  // Clean up test mine to prevent clutter
};

private _magazineName = _mineArray select 1;

if (_mineArray isEqualTo []) exitWith {};

_unit removeMagazine _magazineName;

private _nearestEnemy = [_unit] call VCM_fnc_ClstEmy;
if (_nearestEnemy isEqualTo [] || {isNil "_nearestEnemy"}) exitWith {};

private _mine = objNull;

if (_nearestEnemy distance2D _unit < 100) then {
    // Position in front of the unit
    private _mPos = _unit modelToWorld [0,1,0.05];
    _mine = createVehicle [_mineType, _mPos, [], 0, "CAN_COLLIDE"];
    _mine setDir (_unit getDir _nearestEnemy);
    _mine setPosATL _mPos;
    [_unit,"AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"] remoteExec ["Vcm_PMN",0];
} else {
    private _nearRoads = _unit nearRoads 50;
    if (count _nearRoads > 0) then {
        private _closestRoad = [_nearRoads, _unit, true, "2"] call VCM_fnc_ClstObj;
        doStop _unit;
        _unit doMove (getPos _closestRoad);
        waitUntil {!(alive _unit) || _unit distance2D _closestRoad < 7};
        
        private _mPos = _unit modelToWorld [0,1,0.05];
        _mine = createVehicle [_mineType, _mPos, [], 0, "CAN_COLLIDE"];
        _mine setDir (_unit getDir _nearestEnemy);
        _mine setPosATL _mPos;
        [_unit,"AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"] remoteExec ["Vcm_PMN",0];
    } else {
        private _mPos = _unit modelToWorld [0,1,0.05];
        _mine = createVehicle [_mineType, _mPos, [], 0, "CAN_COLLIDE"];
        _mine setDir (_unit getDir _nearestEnemy);
        _mine setPosATL _mPos;
        [_unit,"AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"] remoteExec ["Vcm_PMN",0];
    };
};

if (!isNull _mine) then {
    private _unitSide = side _unit;
    VCOM_mineArray pushBack [_mine, _unitSide];
    [_mine, false] remoteExecCall ["enableSimulationGlobal", 2];

    // Your existing spawn block for mine simulation (I've kept it commented out)
    /*
    [_mine, _unitSide] spawn {
        // Implementation here
    };
    */
};