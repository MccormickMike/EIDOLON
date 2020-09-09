///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

(
var server = Server.default;
var options = server.options;

options.numInputBusChannels = 10;
options.numOutputBusChannels = 10;
options.memSize = 2**20;
options.sampleRate = 48000;

// Choose Device
// options.device = "Scarlett 2i2 USB"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//this entire interface needs to go into a separate file, with "user" data store in a dictionary

Ndef.all.clear;
OSCdef.freeAll;
server.freeAll;

server.waitForBoot({

	~onsetThreshold = [0.18]; //value between 0.0 and 1.0, depends on instrument, microphone, etc.

	// in new  version of EIDOLON, frequency of the SendReply trigger can be an environment variable, and can be added to the OSC defs
	// to allow for the same amount of time to pass with different trigger rates.
	// example:
	// if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == 4,... BECOMES
	// if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == ~trigRate * 4 (or whatever)
	// so that it always equals the same amount of seconds, but the trigRate can be an argument modulatable in the startup screen
	//  YES!!!

	// also, waitBeforeStartTime should be an environment variable as well, so that buffer recording is not accidentally triggered before the player has started, etc.

	// then, need to add "++ index" to all the Ndef keys so that they are assigned to the right channel/player

	// normalize all synthdef args/inputs and bus outputs!


	//needs also to be an array
	~inBus = [4];
	~outBus = 0;
	~performanceLength = 300; //in seconds
	~numPlayers = ~inBus.size;
	~numChannels = 8;
	~orientation = 0.5; // 0 if center front, 0.5, if bisecting a  vertex
	~pan = [0]; // if using a center front speaker, must change the width to 3 speakers?
	~inVolume = [0.9]; //between 0.0 and 1.0; volume for clean thru signal
	//have to figure out a way to get output volume through Global output, but not to PA output...another argument!!


	~waitBeforeStartTime = 3; //in seconds

	// make this into an event, as in profiles for each of the players

	~compThresh = [0.5]; //compressor threshold between 0.0 and 1.0 for inputs
	~compThreshGlobal = 0.5; //compressor threshold between 0.0 and 1.0 for ouput

	server.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "DictionariesNew.scd").load;

	server.sync;

	if(~numChannels < 3,{
	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "StereoSynthsNew.scd").load;
	},{
		(PathName(thisProcess.nowExecutingPath).parentPath +/+ "MultiChannelSynthsNew.scd").load;

	});

	server.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "SynthKeysNew.scd").load; // when/if busses are passed as arguments to the synths, this dictionaries can go into the Dictionaries File

	server.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "OSCdefsNew.scd").load;

	server.sync;

	~eidolon = Routine({ //inPlayer modules need pan argument - especially for multiple inputs! Check with engineer about live panning?

		~numPlayers.do({
			arg playerIndex;

			Ndef("input%".format(playerIndex).asSymbol,\inPlayer).play(group:~inGroup);
			Ndef("input%".format(playerIndex).asSymbol).set(\amp,~inVolume[playerIndex],\compThresh,~compThresh[playerIndex],\pan,~pan[playerIndex],\inBus,~inBus[playerIndex],\analyserOut,~analyserIn[playerIndex],\outBus,~switcherBus);
			Ndef("analyser%".format(playerIndex).asSymbol,\analyser).play(group:~inGroup);
			Ndef("analyser%".format(playerIndex).asSymbol).set(\inBus,~analyserIn[playerIndex],\thresh,~onsetThreshold[playerIndex]);
		});

		Ndef(\switcher,\switcher).play;
		Ndef(\switcher,\switcher).set(\inBus,~switcherBus,\outBus,~globalInBus);
		Ndef(\globalOut,\globalOut).play;
		Ndef(\globalOut).set(\inBus,~globalInBus,\thresh,~onsetThreshold,\outBus,~outBus,\compThresh,~compThreshGlobal)
	});

	"EIDOLON Ready!".postln;

});
)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STEP 6. EVALUATE THIS LINE TO START THE EIDOLON...
~eidolon.play;
//RECORD
Server.default.record(numChannels: ~numChannels)

