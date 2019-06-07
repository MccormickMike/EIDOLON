///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

//WELCOME!!!

// STEP 1. DOWNLOAD SUPERCOLLIDER HERE IF YOU'RE READING THIS IN A TEXT EDITOR...https://supercollider.github.io/download
// STEP 2. DOWNLOAD AND INSTALL SC3 PLUGINS HERE...https://github.com/supercollider/sc3-plugins/releases
// STEP 3. CHANGE THE FOLLOWING VALUES BELOW SO THEY MATCH YOUR PLAYING CONDITIONS, THEN EVALUATE THE CODE (cmd + return)

(
s = Server.default;
o = s.options;

o.numInputBusChannels = 10; //match the number of hardware inputs on your soundcard
o.numOutputBusChannels = 10; //this is a stereo version at the moment
o.memSize = 2**20; //don't worry about this too much...just making sure SC has enough memory to do fun things!
o.sampleRate = 48000; //likely 44100 or 48000

// Choose Device
// o.device = "Scarlett 2i2 USB"
// o.device = "OCTA-CAPTURE"; //the name of your soundcard goes inside the "" as the line above
)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STEP 4. THE FOLLOWING VALUES MAY NEED SOME TWEAKING
// STEP 5. PLACE YOUR CURSOR SOMEWHERE INSIDE THE PARENTHESES AND EVALUATE THE CODE (cmd + return)

(
Ndef.all.clear;
OSCdef.freeAll;
s.freeAll;

s.waitForBoot({

	~onsetThreshold = 0.12; //value between 0.0 and 1.0, depends on instrument, microphone, etc.
	~inBus = [0];//input channel -1
	~outBus = 0; // first output channel -1
	~numPlayers = ~inBus.size;
	~numChannels = 2; //this is a stereo version...for now
	~inVolume = 0.1; //between 0.0 and 1.0
	~compThresh = [0.5]; //compressor threshold between 0.0 and 1.0 for inputs
	~compThreshGlobal = 0.5;//compressor threshold between 0.0 and 1.0 for ouput

	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "Dictionaries.scd").load;

	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "Synths.scd").load;

	s.sync;

	(PathName(thisProcess.nowExecutingPath).parentPath +/+ "Program_Files" +/+ "OSCdefs.scd").load;

	s.sync;

	~eidolon = Routine({ //inPlayer modules need pan argument - especially for multiple inputs!
		Ndef(\input0,\inPlayer).play(group:~inGroup);
		Ndef(\input0).set(\amp,~inVolume,\compThresh,~compThresh[0],\inBus,~inBus[0],\analyserOut,~analyserIn[0],\outBus,~switcherBus);
		Ndef(\analyser0,\analyser).play(group:~inGroup);
		Ndef(\analyser0).set(\inBus,~analyserIn[0],\thresh,~onsetThreshold);
		Ndef(\switcher,\switcher).play;
		Ndef(\switcher,\switcher).set(\inBus,~switcherBus,\outBus,~globalInBus);
		Ndef(\globalOut,\globalOut).play;
		Ndef(\globalOut).set(\inBus,~globalInBus,\thresh,~onsetThreshold,\outBus,~outBus,\compThresh,~compThreshGlobal)
	});
});
)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STEP 6. EVALUATE THIS LINE TO START THE EIDOLON...
~eidolon.play; //don't forget to comment out input line in Transforms file!

// ...AND THIS ONE TO STOP IT
~eidolon.stop;
