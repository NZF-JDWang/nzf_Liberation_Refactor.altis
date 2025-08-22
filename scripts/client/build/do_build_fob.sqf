private [ "_minfobdist", "_minsectordist", "_distfob", "_clearedtobuildfob", "_distsector", "_clearedtobuildsector", "_idx" ];

if ( count GRLIB_all_fobs >= GRLIB_maximum_fobs ) exitWith {
    hint format [ localize "STR_HINT_FOBS_EXCEEDED", GRLIB_maximum_fobs ];
};

_minfobdist = 1000;
_minsectordist = GRLIB_capture_size + GRLIB_fob_range;
_distfob = 1;
_clearedtobuildfob = true;
_distsector = 1;
_clearedtobuildsector = true;

FOB_build_in_progress = true;
publicVariable "FOB_build_in_progress";

_idx = 0;
while { (_idx < (count GRLIB_all_fobs)) && _clearedtobuildfob } do {
    if ( player distance (GRLIB_all_fobs select _idx) < _minfobdist ) then {
        _clearedtobuildfob = false;
        _distfob = player distance (GRLIB_all_fobs select _idx);
    };
    _idx = _idx + 1;
};

// Check proximity to friendly sectors for subsequent FOBs (not the first one)
private _clearedtobuildfriendly = true;
private _friendlysectordist = 2000;
private _distfriendlysector = 0;

_idx = 0;
if(_clearedtobuildfob && (count GRLIB_all_fobs > 0)) then {
    // Only enforce friendly sector proximity after the first FOB
    if (isNil "blufor_sectors") then { blufor_sectors = [] };
    
    if (count blufor_sectors > 0) then {
        _clearedtobuildfriendly = false;
        while { (_idx < (count blufor_sectors)) && !_clearedtobuildfriendly } do {
            _distfriendlysector = player distance (markerPos (blufor_sectors select _idx));
            if ( _distfriendlysector <= _friendlysectordist ) then {
                _clearedtobuildfriendly = true;
            };
            _idx = _idx + 1;
        };
    } else {
        // No friendly sectors captured yet, can't build additional FOBs
        _clearedtobuildfriendly = false;
        _distfriendlysector = 99999; // Set to large value for error message
    };
};

_idx = 0;
if(_clearedtobuildfob) then {
    while { (_idx < (count sectors_allSectors)) && _clearedtobuildsector } do {
        if ( player distance (markerPos (sectors_allSectors select _idx)) < _minsectordist ) then {
            _clearedtobuildsector = false;
            _distsector = player distance (markerPos (sectors_allSectors select _idx));
        };
        _idx = _idx + 1;
    };
};

if (!_clearedtobuildfob) then {
    hint format [localize "STR_FOB_BUILDING_IMPOSSIBLE",floor _minfobdist,floor _distfob];
    FOB_build_in_progress = false;
    publicVariable "FOB_build_in_progress";
} else {
    if ( !_clearedtobuildsector ) then {
        hint format [localize "STR_FOB_BUILDING_IMPOSSIBLE_SECTOR",floor _minsectordist,floor _distsector];
        FOB_build_in_progress = false;
        publicVariable "FOB_build_in_progress";
    } else {
        if ( !_clearedtobuildfriendly ) then {
            if (count blufor_sectors > 0) then {
                hint format ["FOB must be deployed within %1m of a friendly sector. Nearest friendly sector is %2m away.", floor _friendlysectordist, floor _distfriendlysector];
            } else {
                hint "FOB must be deployed within 2km of a friendly sector. Capture some sectors first!";
            };
            FOB_build_in_progress = false;
            publicVariable "FOB_build_in_progress";
        } else {
            buildtype = 99;
            dobuild = 1;
            deleteVehicle (_this select 0);
        };
    };
};
