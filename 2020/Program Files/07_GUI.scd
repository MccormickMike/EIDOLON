///////////////////////////////////////////////////////EIDOLON GUI//////////////////////////////////////////////////////////////////////


(
var bounds = Rect(0,0,260,440).center_( Window.availableBounds.center );
var window = Window("EIDOLON Controls",bounds);
var flow = window.addFlowLayout();

flow.left_(33);

EZSlider(
	parent: window,
	bounds: 60@390,
	label: "Input0\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{
		arg slider;
		if(Ndef(\input0).isPlaying,{

			Ndef(\input0).set(\amp,slider.value);

		},{ "input% not playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\inVolume],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);


EZSlider(
	parent: window,
	bounds: 60@390,
	label: "Reverb0\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{
		arg slider;
		if(Ndef(\reverb0).isPlaying,{

			Ndef(\reverb0).set(\amp,slider.value);

		},{ "Reverb% playing".format(0).postln; })
	},
	initVal: ~players["Mascha"][\verbAmp],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);


EZSlider(
	parent: window,
	bounds: 60@390,
	label: "EIDOLON\nVolume",
	labelHeight: 30,
	controlSpec: \amp,
	action:{
		arg slider;
		if(Ndef(\globalOut).isPlaying,{

			Ndef(\globalOut).set(\amp,slider.value);

		},{ "EIODLON not playing".postln; })
	},
	initVal:~config[\globalVolume],
	layout: \vert,
	gap: 8@4,
).numberView.align_(\center);

flow.nextLine;
flow.left_(5);

Button(window.view,120@30)
.states_([["START EIDOLON",Color.black, Color.green],["STOP EIDOLON",Color.black, Color.red]])
.action_({
	arg state;
	var val = state.value;

	case
	{val == 0}{
		~stop.value;
		"EIDOLON stopped".postln;
	}
	{val == 1}{
		~play.value;
	}
});

Button(window.view,120@30)
.states_([["START RECORD",Color.black, Color.green],["STOP RECORD",Color.black, Color.red]])
.action_({
	arg state;
	var val = state.value;

	case
	{val == 0}{
		Server.default.stopRecording;
		"Recording stopped".postln;
	}
	{val == 1}{
		Server.default.record(numChannels: ~config[\numChannels]);
		"Recording starting".postln;
	}
});

window.view.background = Color(0.6,0.8,0.8);

window.front;
)