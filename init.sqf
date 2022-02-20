
if(isClass(configfile >> "CfgPatches" >> "ace_interaction"))then{
    
    if((["PlayerMapTools", 1] call BIS_fnc_getParamValue) == 1) then {
		player addItem "ACE_MapTools";	
	};
};



if((["PlayerBinoculars", 1] call BIS_fnc_getParamValue) == 1) then {
	player addWeapon "Binocular";
	//player selectWeapon "Binocular";	
};

if((["PlayerBinoculars", 1] call BIS_fnc_getParamValue) == 2) then {
	player addWeapon "Rangefinder";
	//player selectWeapon "Rangefinder";
};


if((["PlayerCompass", 1] call BIS_fnc_getParamValue) == 1) then {
	player addItem "ItemCompass";
	player assignItem "ItemCompass";
};

AOSize = (["ShowAO", 2500] call BIS_fnc_getParamValue);


roundsPlayed = 0;

startPos = getpos player;
guessPos = getpos player;
lastPos = getpos player;

previousGuessDistances = [];
previousGuessTimes = [];
previousTravelDistances = [];

travelMarkers = [];
travelCount = 0;

FNC_resetGame = {

	hintSilent "";

	// Reset map markers
	deleteMarker "startMarker";
	deleteMarker "endMarker";
	deleteMarker "guessMarker";
	{
		deleteMarker _x;
	} forEach travelMarkers;
	travelCount = 0;


	// Setup player position
	startPos = [] call BIS_fnc_randomPos;
	player setpos startPos;
	lastPos = getpos player;



	// IF applicable, draw the AO
	if(AOSize != -1) then {
		deleteMarker "AOMarker";
		deleteMarker "AOBorderMarker";

		_AOPos = [[[position player, AOSize]],[]] call BIS_fnc_randomPos;

		AOMarker = createMarker ["AOMarker", _AOPos];
		AOMarker setMarkerType "mil_unknown";
		AOMarker setMarkerColor "ColorWEST";
		AOMarker setMarkerAlpha 0.4;
		AOMarker setMarkerShape "ELLIPSE";
		AOMarker setMarkerSize [AOSize, AOSize];

		AOBorderMarker = createMarker ["AOBorderMarker", _AOPos];
		AOBorderMarker setMarkerType "mil_unknown";
		AOBorderMarker setMarkerColor "ColorWEST";
		AOBorderMarker setMarkerShape "ELLIPSE";
		AOBorderMarker setMarkerSize [AOSize, AOSize];
		AOBorderMarker setMarkerBrush "Border";
	};


	call FNC_enableClick;

	["#DDDDDD"] spawn BIS_fnc_VRTimer;
};



FNC_enableClick = {
	onMapSingleClick {

		roundsPlayed = roundsPlayed + 1;

		onMapSingleClick "";
		
		BIS_stopTimer = true;
		_time = str RscFiringDrillTime_current splitString ":";
		_time = ((parseNumber (_time select 0)) * 60) + parseNumber (_time select 1);

		guessPos = _pos;

		_distance = player distance startPos;

		///////////////////////////////////
		// Update Average Scores         //
		///////////////////////////////////

		previousGuessDistances append [player distance guessPos];
		averageGuessDistance = 0;
		{
			averageGuessDistance = averageGuessDistance + _x;
		} forEach previousGuessDistances;
		averageGuessDistance = (round((averageGuessDistance / count previousGuessDistances) * 100)/100);


		previousGuessTimes append [_time];
		averageGuessTime = 0;
		{
			averageGuessTime = averageGuessTime + _x;
		} forEach previousGuessTimes;
		averageGuessTime = averageGuessTime / count previousGuessTimes;


		averageGuessTimeString = if(averageGuessTime%60 < 10) then{format ["%1:0%2", floor (averageGuessTime/60), (round((averageGuessTime%60)*100)/100)]} else {format ["%1:%2", floor (averageGuessTime/60), (round((averageGuessTime%60)*100)/100)]};


		previousTravelDistances append [_distance];
		averageDistances = 0;
		{
			averageDistances = averageDistances + _x;
		} forEach previousTravelDistances;
		averageDistances = (round((averageDistances / count previousTravelDistances) * 100)/100);

		///////////////////////////////////
		// Display hint                  //
		///////////////////////////////////

		hint format ["Approx %1m away\nTime taken:%2\nDistance travelled: %3m\n\nAverage guess distance: %4m\nAverage time: %5\nAverage distance travelled: %6m\nRounds played: %7\n\nResetting in 10 seconds...", player distance guessPos, str RscFiringDrillTime_current, (round((_distance) * 100)/100), averageGuessDistance, averageGuessTimeString, averageDistances, roundsPlayed];
		

		///////////////////////////////////
		// Display map markers           //
		///////////////////////////////////

		startMarker = createMarker ["startMarker", startPos];
		startMarker setMarkerColor "ColorBlue";
		startMarker setMarkerText "Your position";
		startMarker setMarkerType "hd_dot";

		{
			_x setMarkerType "hd_dot";
		} forEach travelMarkers;

		if(player distance startPos > 20) then {
			startMarker setMarkerText "Start position";

			endMarker = createMarker ["endMarker", player];
			endMarker setMarkerColor "ColorBlue";
			endMarker setMarkerText "Final position";
			endMarker setMarkerType "hd_dot";

		};

		if(AOSize == -1) then {
			markerAccuracy = 22000;
		}
		else{
			markerAccuracy = AOSize*2;	
		};

		guessMarker = createMarker ["guessMarker", guessPos];
		guessMarker setMarkerColor "ColorRed";
		if(guessPos distance player < markerAccuracy/2) then {
			guessMarker setMarkerColor "ColorOrange";
		};
		if(guessPos distance player < markerAccuracy/4) then {
			guessMarker setMarkerColor "ColorYellow";
		};
		if(guessPos distance player < markerAccuracy/10) then {
			guessMarker setMarkerColor "ColorGreen";
		};
		guessMarker setMarkerText "Your guess";
		guessMarker setMarkerType "hd_dot";


		///////////////////////////////////
		// Prepare Reset                 //
		///////////////////////////////////
		
		[] spawn {
			sleep 10;
			call FNC_resetGame;
		}
		
	};
};


// I don't know why, but spawn BIS_fnc_VRTimer won't work without this initial sleep. So...

hint "Get ready!\n\nYou will be transported to a random location. Observe your surroundings and click the map to make your guess.\n\nStarting in 5 seconds...";
[] spawn {
	sleep 5;
	call FNC_resetGame;
};


[] spawn {
	while{true} do{
		if(player distance lastPos > 4) then{			
			_marker = createMarker [format ["travelMarker_%1", travelCount], player];
			_marker setMarkerColor "ColorBlue";

			travelMarkers append [_marker];
			travelCount = travelCount + 1;
			lastPos = getpos player;

		};
		sleep 2;
	};
};
