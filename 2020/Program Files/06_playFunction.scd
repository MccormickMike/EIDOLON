///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

/*---------------------------------------------   play function   ----------------------------------------*/

(
~play = {
	var players = ~config[\playerProfiles];
	var wait = ~config[\waitBeforeStartTime];


	players.do({
		arg profileName,playerIndex;
		var profile = ~players[profileName];

		Ndef("input%".format(playerIndex).asSymbol,\inPlayer).play(group:~inGroup);
		Ndef("input%".format(playerIndex).asSymbol).set(
			\amp,profile[\inVolume],
			\compThresh,profile[\compThresh],
			\pan,profile[\pan],
			\inBus,profile[\inBus],
			\analyserOut,~audioBus["analyserIn"][playerIndex],
			\outBus,~audioBus["switcherBus"],
		);

		Ndef("analyser%".format(playerIndex).asSymbol,\analyser).play(group:~inGroup);
		Ndef("analyser%".format(playerIndex).asSymbol).set(
			\inBus,~audioBus["analyserIn"][playerIndex],
			\thresh,profile[\onsetThreshold],
			\trigRate, profile[\pollRate],

			\ampBus,~controlBus[playerIndex]["ampBus"],
			\silenceBus,~controlBus[playerIndex]["silenceBus"],
			\freqBus,~controlBus[playerIndex]["freqBus"],
			\hasFreqBus,~controlBus[playerIndex]["hasFreqBus"],
			\onsetsBus,~controlBus[playerIndex]["onsetsBus"],
			\centroidBus,~controlBus[playerIndex]["centroidBus"],
			\specFlatnessBus,~controlBus[playerIndex]["specFlatnessBus"],
			\densityBus,~controlBus[playerIndex]["densityBus"],
			\meanIOIBus,~controlBus[playerIndex]["meanIOIBus"],
			\varianceIOIBus,~controlBus[playerIndex]["varianceIOIBus"],
		);
	});

	Ndef(\switcher,\switcher).play;
	Ndef(\switcher,\switcher).set(\inBus,~audioBus["switcherBus"],\outBus,~audioBus["globalInBus"]);

	Ndef(\globalOut,\globalOut).play;
	Ndef(\globalOut).set(
		\inBus,~audioBus["globalInBus"],
		\thresh,~config[\onsetThreshGlobal],
		\trigRate, ~config[\pollRateGlobal],
		\compThresh,~config[\compThreshGlobal],
		\outBus,~config[\hardwareOut],
	);

	Routine({

		"EIDOLON starting in % seconds\n".format(wait).postln;
		wait.wait;
		"EIDOLON starting now\n".postln;
	}).play;

})