///////////////////////////////////////////////////////EIDOLON//////////////////////////////////////////////////////////////////////
(
//Allocate Audio and Control Busses
(

//these can all be put into a large dictionary!!
~analyserIn = Array.fill(~numPlayers,{Bus.audio(s,~numChannels)});
~switcherBus = Bus.audio(s,~numChannels);

~reverbBus = Bus.audio(s,~numChannels);
~globalInBus = Bus.audio(s,~numChannels);

~ampBus = Bus.control(s,1);
~silenceBus = Bus.control(s,1);
~freqBus = Bus.control(s,1);
~hasFreqBus = Bus.control(s,1);
~onsetsBus = Bus.control(s,1);
~centroidBus = Bus.control(s,1);
~specFlatnessBus = Bus.control(s,1);
~densityBus = Bus.control(s,1);
~meanIOIBus = Bus.control(s,1);
~varianceIOIBus = Bus.control(s,1);

/*
~controlBus = {
Dictionary.with(*[
"ampBus" -> Bus.control(s,1),
"silenceBus" -> Bus.control(s,1),
"freqBus" -> Bus.control(s,1),
"hasFreqBus" -> Bus.control(s,1),
"onsetsBus" -> Bus.control(s,1),
"centroidBus" -> Bus.control(s,1),
"specFlatnessBus" -> Bus.control(s,1),
"densityBus" -> Bus.control(s,1),
"meanIOIBus" -> Bus.control(s,1),
"varianceIOIBus" -> Bus.control(s,1),
])
} ! ~numPlayers;
*/

);

//Allocate buffers for recording
~buffers = {Array.fill(8,{Buffer.alloc(s, s.sampleRate * 12, 1)})} ! ~numPlayers;

//groups
(
~inGroup = Group(s,\addToHead);
~globalOutGroup = Group(s,\addToTail);
~interruptGroup = Group(~globalOutGroup,\addBefore);
);

//median filters for incoming data
(
~memory = {
	Dictionary.with(*[
		"past_amp" -> List(),
		"past_silence" -> List(),
		"past_freq" -> List(),
		"past_hasFreq" -> List(),
		"past_centroid" -> List(),
		"past_specFlatness" -> List(),
		"past_density" -> List(),
		"past_meanIOI" -> List(),
		"past_varianceIOI" -> List(),

		"bufferEvents" -> List(),
		"events" -> List(),
		"state" -> List()

	])
} ! ~numPlayers;

~globalMemory = Dictionary.with(*[
	"past_amp" -> List(),
	"past_silence" -> List(),
	"past_freq" -> List(),
	"past_hasFreq" -> List(),
	"past_centroid" -> List(),
	"past_specFlatness" -> List(),
	"past_density" -> List(),
	"past_meanIOI" -> List(),
	"past_varianceIOI" -> List(),

	"events" -> List()
])
);

//synth Key dictionaries
/*(
~synthKeys = ~numPlayers.collect({
	arg playerIndex;

	Dictionary[

		"percSynthKeys" -> ~transforms[playerIndex]["densePerc"].keys.asArray.scramble,
		"pitchSynthKeys" -> ~transforms[playerIndex]["pitchTrack"].keys.asArray.scramble,
		"silenceSynthKeys" -> ~transforms[playerIndex]["fillSilence"].keys.asArray.scramble,
		"bufferSynthKeys" -> ~bufTransforms[playerIndex].keys.asArray.scramble,


	]
})
);*/

~recorder = Array.fill(~numPlayers,0);

"Data file loaded".postln;

)