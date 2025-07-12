if ( isDedicated ) exitWith {};

if ( isNil "sector_timer" ) then { sector_timer = 0 };

params [ "_sector", "_status" ];

if ( _status == 0 ) then {
    [ "lib_sector_captured", [ markerText _sector ] ] call BIS_fnc_showNotification;

    // Ensure sector recorded as friendly on client immediately
    if (isNil "blufor_sectors") then { blufor_sectors = [] };
    if (!(_sector in blufor_sectors)) then { blufor_sectors pushBack _sector; };

    // Convert marker type from o_/n_ prefix to b_ (blue)
    private _origTypeC = markerType _sector;
    private _newTypeC = _origTypeC;
    if ((_origTypeC select [0,2]) in ["o_", "n_"]) then {
        private _suffixC = _origTypeC select [2, (count _origTypeC) - 2];
        _newTypeC = ("b_" + _suffixC);
        _sector setMarkerTypeLocal _newTypeC;
    };
    _sector setMarkerColorLocal GRLIB_color_friendly;

    // Remove any capture overlay ring still lingering
    private _ovName = format ["KPLIB_cap_%1", _sector];
    deleteMarkerLocal _ovName;
};

if ( _status == 1 ) then {
    [ "lib_sector_attacked", [ markerText _sector ] ] call BIS_fnc_showNotification;
    "opfor_capture_marker" setMarkerPosLocal ( markerpos _sector );
    sector_timer = GRLIB_vulnerability_timer;
};

if ( _status == 2 ) then {
    [ "lib_sector_lost", [ markerText _sector ] ] call BIS_fnc_showNotification;
    "opfor_capture_marker" setMarkerPosLocal markers_reset;
    sector_timer = 0;
};

if ( _status == 3 ) then {
    [ "lib_sector_safe", [ markerText _sector ] ] call BIS_fnc_showNotification;
    "opfor_capture_marker" setMarkerPosLocal markers_reset;
    sector_timer = 0;
};

{ _x setMarkerColorLocal GRLIB_color_enemy; } foreach (sectors_allSectors - blufor_sectors);
{ _x setMarkerColorLocal GRLIB_color_friendly; } foreach blufor_sectors;

// THIRD_EDIT - Ensure freshly captured sector is forced to friendly colour even if blufor_sectors lag behind
if (_status == 0) then {
    _sector setMarkerColorLocal GRLIB_color_friendly;
};

// Ensure capturable sectors remain highlighted
if (!isNil "KPLIB_fnc_handleEligibilityUpdate") then { [] call KPLIB_fnc_handleEligibilityUpdate; };
