/* ------ Mascha ------ */

(
//this also needs to change..make into a dictionary or something???

// hardware
~players.add(

	"Mascha" -> (
		inBus: 0,
		outBus: 0,

		compThresh: 0.5, // compressor threshold between 0.0 and 1.0 for inputs
		onsetThreshold: 0.18, // value between 0.0 and 1.0, depends on instrument, microphone, etc.
		silenceThreshold: 0.01,
		pollRate: 4,

		pan: 0,
		inVolume: 0.9, // between 0.0 and 1.0; volume for clean thru signal
		damp: 0.4, // between 0.0 and 1.0; high frequency dampening
		verbAmp: 0.4, // between 0.0 and 1.0; reverb volume

		// EQ stuff??

	);
);

"Profile \"Mascha\" loaded".postln;
)

