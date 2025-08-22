/*
    File: ui/fn_updateSectorEligibilityMarkers.sqf
    Runs on every client (postInit) to keep the sector markers up-to-date.

    Listens to the public variable  KPLIB_captureEligiblePairs  and whenever that
    variable changes it:
      • greys all enemy sectors
      • re-colours the eligible ones bright red
      • draws ONE plain line marker from the closest BLUFOR source (or first FOB)
        to each eligible enemy sector.
*/

if (!hasInterface) exitWith {};

// Wait until the sector arrays are broadcast to the client (fixes startup race-condition)
waitUntil { !isNil "sectors_allSectors" && !isNil "blufor_sectors" };

// Storage for the transient line markers and overlay markers we create
KPLIB_sectorEligibleLines = [];
KPLIB_sectorEligibleOverlays = [];

// Helper that (re)builds the visual state
KPLIB_fnc_handleEligibilityUpdate = {
    // Debug: Log when this function is called
    if (KP_liberation_debug) then {
        systemChat format ["ELIGIBILITY UPDATE CALLED - pairs count: %1", count (missionNamespace getVariable ["KPLIB_captureEligiblePairs", []])];
    };
    
    private _pairs = if (isNil "KPLIB_captureEligiblePairs") then { [] } else { +KPLIB_captureEligiblePairs };

    // 1.  Colour all enemy sectors with OPFOR colour at 50% alpha
    {
        _x setMarkerColorLocal GRLIB_color_enemy;
        _x setMarkerAlphaLocal 0.5;
    } forEach (sectors_allSectors - blufor_sectors);

    // Make sure friendly sectors are fully opaque with friendly color
    {
        _x setMarkerColorLocal GRLIB_color_friendly;
        _x setMarkerAlphaLocal 1;
    } forEach blufor_sectors;

    // 2.  Remove previous overlay markers but KEEP historical connector lines
    // Lines show the path of advance, so we leave them untouched to visualise progress.

    {
        deleteMarkerLocal _x;
    } forEach KPLIB_sectorEligibleOverlays;
    KPLIB_sectorEligibleOverlays = [];
    
    // AGGRESSIVE cleanup: Delete ALL KPLIB_cap_ markers before recreating them
    // Use the same approach that worked in manual testing
    private _allCapMarkers = allMapMarkers select { (_x find "KPLIB_cap_") == 0 };
    {
        deleteMarkerLocal _x;
    } forEach _allCapMarkers;
    
    // Force a small delay to ensure deletions are processed before recreation
    uiSleep 0.01;

    // 3.  For each capturable enemy sector draw connector line and overlay ring
    //    We also ensure the history lines (previously captured sectors) remain visible.

    private _allPairs = _pairs;
    if (!isNil "KPLIB_captureLineHistory") then {
        {
            private _enemy = _x select 0;
            if (!(_enemy in (_pairs apply { _x select 0 }))) then {
                _allPairs pushBack _x;
            };
        } forEach KPLIB_captureLineHistory;
    };

    {
        _x params ["_enemyMarker", "_source"];

        // If line already drawn we will recreate to ensure consistency
        // Build polyline ... (duplicate of original code)
        private _srcPos = if (_source isEqualType "") then { markerPos _source } else { _source };
        private _lineName = format ["KPLIB_line_%1", _enemyMarker];
        deleteMarkerLocal _lineName;
        private _line = createMarkerLocal [_lineName, _srcPos];
        _line setMarkerShapeLocal "polyline";
        private _poly = [
            _srcPos select 0,
            _srcPos select 1,
            (markerPos _enemyMarker) select 0,
            (markerPos _enemyMarker) select 1
        ];
        _line setMarkerPolylineLocal _poly;
        _line setMarkerColorLocal "ColorCIV";
        _line setMarkerAlphaLocal 0.8;
        _line setMarkerTypeLocal "mil_line";

        KPLIB_sectorEligibleLines pushBack _line;

    } forEach _allPairs;

    // Add overlay only for currently capturable sectors
    {
        _x params ["_enemyMarker", "_source"];
        if !(_enemyMarker in blufor_sectors) then {
            // Make the base sector marker fully opaque with OPFOR colour
            _enemyMarker setMarkerColorLocal GRLIB_color_enemy;
            _enemyMarker setMarkerAlphaLocal 1;

            // Add overlay ring to highlight capturable sector
            private _ovName = format ["KPLIB_cap_%1", _enemyMarker];
            deleteMarkerLocal _ovName;
            private _ov = createMarkerLocal [_ovName, markerPos _enemyMarker];
            _ov setMarkerTypeLocal "selector_selectedFriendly";
            _ov setMarkerColorLocal "ColorRed"; // force standard red
            _ov setMarkerAlphaLocal 0.8;
            _ov setMarkerSizeLocal [2,2];

            KPLIB_sectorEligibleOverlays pushBack _ov;
        };
    } forEach _pairs;
};

// Register PV event so every update from the server triggers a refresh
"KPLIB_captureEligiblePairs" addPublicVariableEventHandler {
    [] call KPLIB_fnc_handleEligibilityUpdate;
};

// Run once on JIP / mission start in case the variable already exists
[] call KPLIB_fnc_handleEligibilityUpdate; 