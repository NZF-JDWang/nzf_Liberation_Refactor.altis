params ["_unit", ["_sector", ""]];

[(group _unit), _sector, 400, [], true, false, -1, false] call lambs_wp_fnc_taskGarrison;


private _ratio = 0.2;


while { local _unit && alive _unit && !(captive _unit)} do {

    _ratio = [_sector] call KPLIB_fnc_getBluforRatio;
    

    if (_ratio > .5) then {

        [(group _unit)] call lambs_wp_fnc_taskReset;

        if (random 100 > 75) then {
           [(group _unit), _sector, 150, [], false, false, -2, true] call lambs_wp_fnc_taskGarrison; 
        }
        else {
            if (random 100 > 50) then {
                [(group _unit), _sector, 100] spawn lambs_wp_fnc_taskCQB;
            }
            else {
                [(group _unit), 500] spawn lambs_wp_fnc_taskRush;
            };
        };
    };
    sleep 120;
};