waitUntil {!isNil "save_is_loaded"};
waitUntil {save_is_loaded};

KP_liberation_fob_resources = [];
KP_liberation_supplies_global = 0;
KP_liberation_ammo_global = 0;
KP_liberation_fuel_global = 0;
KP_liberation_heli_slots = 0;
KP_liberation_plane_slots = 0;
infantry_cap = 50 * GRLIB_resources_multiplier;

please_recalculate = true;

waitUntil {time > 1};

while {true} do {
    waitUntil {sleep 1; please_recalculate};
    please_recalculate = false;

    private _local_fob_resources = [];
    private _local_supplies_global = 0;
    private _local_ammo_global = 0;
    private _local_fuel_global = 0;
    private _local_heli_slots = 0;
    private _local_plane_slots = 0;
    private _local_infantry_cap = 50 * GRLIB_resources_multiplier;

    {
        private _fob_position = _x;
        private _fob_object = (nearestObjects [_fob_position, [FOB_typename], 100, true]) param [0, objNull];
        
        if (isNull _fob_object) then {
            [format["Recalculate Resources: Could not find FOB object for position %1. Skipping.", _fob_position], "ERROR"] call KPLIB_fnc_log;
        } else {
            private _fob_buildings = _fob_object nearObjects GRLIB_fob_range;
            private _storage_areas = _fob_buildings select {(_x getVariable ["KP_liberation_storage_type",-1]) == 0};
            private _heliSlots = {(typeOf _x) == KP_liberation_heli_slot_building;} count _fob_buildings;
            private _planeSlots = {(typeOf _x) == KP_liberation_plane_slot_building;} count _fob_buildings;
            private _hasAirBuilding = {(typeOf _x) == KP_liberation_air_vehicle_building;} count _fob_buildings > 0;
            private _hasRecBuilding = {(typeOf _x) == KP_liberation_recycle_building;} count _fob_buildings > 0;

            private _supplyValue = 0;
            private _ammoValue = 0;
            private _fuelValue = 0;

            {
                {
                    private _crateValue = _x getVariable ["KP_liberation_crate_value",0];
                    switch (true) do {
                        case (typeOf _x == KP_liberation_supply_crate): {_supplyValue = _supplyValue + _crateValue;};
                        case (typeOf _x == KP_liberation_ammo_crate): {_ammoValue = _ammoValue + _crateValue;};
                        case (typeOf _x == KP_liberation_fuel_crate): {_fuelValue = _fuelValue + _crateValue;};
                        default {
                            // Only log if it's not an empty object
                            if !(isNull _x) then {
                                [format ["Invalid object (%1) at storage area", (typeOf _x)], "ERROR"] call KPLIB_fnc_log;
                            };
                        };
                    };
                } forEach (attachedObjects _x);
            } forEach _storage_areas;

            // Store FOB position as reference for consistency across clients and serialization
            _local_fob_resources pushBack [_fob_position, _supplyValue, _ammoValue, _fuelValue, _hasAirBuilding, _hasRecBuilding];
            _local_supplies_global = _local_supplies_global + _supplyValue;
            _local_ammo_global = _local_ammo_global + _ammoValue;
            _local_fuel_global = _local_fuel_global + _fuelValue;
            _local_heli_slots = _local_heli_slots + _heliSlots;
            _local_plane_slots = _local_plane_slots + _planeSlots;
            
            [format ["FOB %1 processed: S=%2 A=%3 F=%4", mapGridPosition _fob_position, _supplyValue, _ammoValue, _fuelValue], "RESOURCE"] call KPLIB_fnc_log;
        };
    } forEach GRLIB_all_fobs;
    
    [format ["Resource loop completed. Processing %1 FOBs, created %2 resource entries", 
        count GRLIB_all_fobs, count _local_fob_resources], "RESOURCE"] call KPLIB_fnc_log;

    {
        if ( _x in sectors_capture ) then {
            _local_infantry_cap = _local_infantry_cap + (10 * GRLIB_resources_multiplier);
        };
    } foreach blufor_sectors;

    KP_liberation_fob_resources = _local_fob_resources;
    KP_liberation_supplies_global = _local_supplies_global;
    KP_liberation_ammo_global = _local_ammo_global;
    KP_liberation_fuel_global = _local_fuel_global;
    KP_liberation_heli_slots = _local_heli_slots;
    KP_liberation_plane_slots = _local_plane_slots;
    infantry_cap = _local_infantry_cap;
    
    // Broadcast authoritative resource state (legacy PV model for reliability)
    { publicVariable _x } forEach [
        "KP_liberation_fob_resources",
        "KP_liberation_supplies_global",
        "KP_liberation_ammo_global",
        "KP_liberation_fuel_global",
        "KP_liberation_heli_slots",
        "KP_liberation_plane_slots",
        "infantry_cap"
    ];
    
    // Debug logging to track resource updates
    [format ["Resource recalculation complete: %1 FOBs, %2 supplies, %3 ammo, %4 fuel", 
        count KP_liberation_fob_resources, 
        KP_liberation_supplies_global, 
        KP_liberation_ammo_global, 
        KP_liberation_fuel_global
    ], "RESOURCE"] call KPLIB_fnc_log;

};
