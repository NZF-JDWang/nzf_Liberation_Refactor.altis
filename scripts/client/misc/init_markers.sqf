_marker = createMarkerLocal ["zone_capture", markers_reset];
_marker setMarkerColorLocal "ColorUNKNOWN";
_marker setMarkerShapeLocal "Ellipse";
_marker setMarkerBrushLocal "SolidBorder";
_marker setMarkerSizeLocal [ GRLIB_capture_size, GRLIB_capture_size ];
_marker setMarkerAlphaLocal 0;   // Hide the zone capture marker – keep it for scripting logic but invisible to players

_marker = createMarkerLocal ["spawn_marker", markers_reset];
_marker setMarkerColorLocal "ColorGreen";
_marker setMarkerTypeLocal "Select";