///////////////////////////////////////////////////////EIDOLON SynthKeys//////////////////////////////////////////////////////////////////////

(
~synthKeys = ~numPlayers.collect({
	arg playerIndex;

	Dictionary[

		"percSynthKeys" -> ~transforms["densePerc"].keys.asArray.scramble,
		"pitchSynthKeys" -> ~transforms["pitchTrack"].keys.asArray.scramble,
		"silenceSynthKeys" -> ~transforms["fillSilence"].keys.asArray.scramble,
		"bufferSynthKeys" -> ~bufTransforms.keys.asArray.scramble,
	]
});

"Synth keys loaded".postln;

);
