class Dynamic_Groups { //format: {"Group Name",{"Group","Roles","Matching","Role","Configs"},"Conditions for the group to be shown"}
	faction_name = "CSAT";
	group_setup[] = {
		{"Command",{"officer"},"true"},
		{"Alpha",{"teamlead","medic","machinegunner","rifleman","teamlead","engineer","rifleman","rifleman"},"true"},
		{"Bravo",{"teamlead","medic","machinegunner","rifleman","teamlead","engineer","rifleman","rifleman"},"count playableUnits > 8"}

	};
};

#include "Config_Roles.hpp"