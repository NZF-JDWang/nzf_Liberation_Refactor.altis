/*
    Author: Genesis

    Description:
        Monitors all placed VCOM mines. More efficient than having each mine with its own spawn.

    Parameter(s):
        NONE

    Returns:
        NOTHING
*/

// This list is all local.
while {true} do 
{
    // Use a single loop for cleanup and checking, reduces overhead
    {
        private _mineInfo = _x;
        if (alive (_mineInfo select 0)) then 
        {
            private _mine = _mineInfo select 0;
            private _side = _mineInfo select 1;
            
            // Find closest enemy of a different side
            private _closestEnemy = allUnits findIf 
            {
                [_side, side _x] call BIS_fnc_sideIsEnemy && 
                _x distance _mine < 2.5
            };
            
            // If an enemy is near, activate the mine
            if (_closestEnemy != -1) then 
            {
                [_mine, true] remoteExecCall ["enableSimulationGlobal", 2];
                sleep 0.25;
                _mine setDamage 1;
            };
        } 
        else 
        {
            // Remove this mine from the list if it's dead or destroyed
            VCOM_MINEARRAY deleteAt (_forEachIndex);
        };
    } forEach VCOM_MINEARRAY;

    // Sleep to reduce CPU usage
    sleep 1.25;
};