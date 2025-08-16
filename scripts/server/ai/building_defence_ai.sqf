params ["_unit", ["_sector", ""]];

// Determine local anchor for this garrison group, if present
private _anchor = (group _unit) getVariable ["KPLIB_garrisonAnchorPos", []];
private _hasAnchor = (_anchor isEqualType []) && {(count _anchor) >= 2};
private _garrisonPos = if (_hasAnchor) then { _anchor } else { _sector };
// Initial garrison radius: tight if anchored, else legacy wider radius
private _initialRadius = if (_hasAnchor) then { 50 } else { 200 };
[(group _unit), _garrisonPos, _initialRadius, [], true, false, -1, false] call lambs_wp_fnc_taskGarrison;


private _ratio = 0.2;


while { local _unit && alive _unit && !(captive _unit)} do {

    _ratio = [_sector] call KPLIB_fnc_getBluforRatio;
    

    if (_ratio > .5) then {

        [(group _unit)] call lambs_wp_fnc_taskReset;

        if (random 100 > 75) then {
           private _reAnchor = (group _unit) getVariable ["KPLIB_garrisonAnchorPos", []];
           private _reHas = (_reAnchor isEqualType []) && {(count _reAnchor) >= 2};
           private _pos = if (_reHas) then { _reAnchor } else { _sector };
           [(group _unit), _pos, (if (_reHas) then {50} else {150}), [], false, false, -2, true] call lambs_wp_fnc_taskGarrison; 
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