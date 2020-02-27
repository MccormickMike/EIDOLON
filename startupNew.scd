///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

(
s = Server.default;
o = s.options;

o.numInputBusChannels = 10;
o.numOutputBusChannels = 10;
o.memSize = 2**20;
o.sampleRate = 48000;

// Choose Device
// o.device = "Scarlett 2i2 USB"
o.device = "OCTA-CAPTURE";
)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//this entire interface needs to go into a separate file, with "user" data store in a dic

(
Ndef.all.clear;
OSCdef.freeAll;
s.freeAll;

s.waitForBoot({

	~onsetThreshold = [0.13]; //value between 0.0 and 1.0, depends on instrument, microphone, etc.

	// in new  version of EIDOLON, frequency of the SendReply trigger can be an environment variable, and can be added to the OSC defs
	// to allow for the same amount of time to pass with different trigger rates.
	// example:
	// if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == 4,... BECOMES
	// if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == ~trigRate * 4 (or whatever)
	// so that it always equals the same amount of seconds, but the trigRate can be an argument modulatable in the startup screen
	//  YES!!!

	// also, waitBeforeStartTime should be an environment variable as well, so that buffer recording is not accidentally triggered before the player has started, etc.

	// then, need to add "++ index" to all the Ndef keys so that they are assigned to the right channel/player


	//needs also to be an array
	~inBus = [0];
	~outBus = 0;
	~performanceLength = 600; //in seconds
	~numPlayers = ~inBus.size;
	~numChannels = 2;
	~orientation = 0.5; // 0 if center front, 0.5, if bisecting a  vertex
	~pan = [0]; // if using a center front speaker, must change the width to 3 speakers?
	~inVolume = [0.5]; //between 0.0 and 1.0; volume for clean thru signal
	//have to figure out a way to get output volume through Global output, but not to PA output...another argument!!


	~waitBeforeStartTime = 1; //in seconds

	// make this into an event, as in profiles for each of the players

	//can gain high and then compress hard (lower threshold)
	~compThresh = [0.5]; //compressor threshold between 0.0 and 1.0 for inputs
	~compThreshGlobal = 0.5;//compressor threshold between 0.0 and 1.0 for ouput


	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "EIDOLONNew" +/+ "DictionariesNew.scd").load;

	s.sync;

	if(~numChannels < 3,{
	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files"+/+ "EIDOLONNew" +/+ "StereoSynthsNew.scd").load;
	},{
		(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files"+/+ "EIDOLONNew" +/+ "MultiChannelSynthsNew.scd").load;

	});

	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "EIDOLONNew" +/+ "SynthKeysNew.scd").load; // when/if busses are passed as arguments to the synths, this dictionaries can go into the Dictionaries File

	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "EIDOLONNew" +/+ "OSCdefsNew.scd").load;

	s.sync;

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
s.record(numChannels: ~numChannels)

//remove the new!!!

// ...AND THIS ONE TO STOP IT
~eidolon.stop;


