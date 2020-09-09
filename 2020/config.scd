
~test = (

	performanceLength: 300, // in seconds
	numChannels: 8, // number of output channels or speakers
	// spatMode: "VBAP", eventually include SynthDefs w/ different modes???

	orientation: 0.5, // 0 if center front, 0.5, if bisecting a  vertex
	waitBeforeStartTime: 30, // in seconds
	compThreshGlobal: 0.5, // compressor threshold between 0.0 and 1.0 for ouput

	playersProfiles: [1,2,3],



);

~numPlayers = ~test[\playersProfiles].size // this can be better!!
