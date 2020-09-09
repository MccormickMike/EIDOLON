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

Ndef.all.clear;
OSCdef.freeAll;
server.freeAll;

server.waitForBoot({

	// load config file
	// load player profiles
	// load program files

	// if more than 2 channels, load multichannel synthdefs!

	~eidolon = Routine({ //inPlayer modules need pan argument - especially for multiple inputs! Check with engineer about live panning?

		~numPlayers.do({
			arg playerIndex;

			Ndef("input%".format(playerIndex).asSymbol,\inPlayer).play(group:~inGroup);
			Ndef("input%".format(playerIndex).asSymbol).set(\amp,~inVolume[playerIndex],\compThresh,~compThresh[playerIndex],\pan,~pan[playerIndex],\inBus,~inBus[playerIndex],\analyserOut,~analyserIn[playerIndex],\outBus,~switcherBus);
			Ndef("analyser%".format(playerIndex).asSymbol,\analyser).play(group:~inGroup);
			Ndef("analyser%".format(playerIndex).asSymbol).set(
				\inBus,~analyserIn[playerIndex],
				\thresh,~onsetThreshold[playerIndex],
				\amp,~controlBus[playerIndex]["ampBus"],
				\silence,~controlBus[playerIndex]["silenceBus"],
				\freq,~controlBus[playerIndex]["freqBus"],
				\hasFreq,~controlBus[playerIndex]["hasFreqBus"],
				\onsets,~controlBus[playerIndex]["onsetsBus"],
				\centroid,~controlBus[playerIndex]["centroidBus"],
				\specFlatness,~controlBus[playerIndex]["specFlatnessBus"],
				\density,~controlBus[playerIndex]["densityBus"],
				\meanIOI,~controlBus[playerIndex]["meanIOIBus"],
				\varianceIOI,~controlBus[playerIndex]["varianceIOIBus"],
			);
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
