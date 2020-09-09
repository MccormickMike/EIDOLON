///////////////////////////////////////////////////////EIDOLON//////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////INDIVIDUAL ANALYSER///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
(
OSCdef(\listener0, {
	arg msg;
	var index = 0; //Make into a .do statement!!!!!
	var current_amp = msg[3].ampdb;
	var recent_amp = ~memory[index]["past_amp"][0..24].median;
	var current_silence = msg[4];
	var recent_silence = ~memory[index]["past_silence"][0..24].mean;
	var current_freq = msg[5];
	var recent_freq = ~memory[index]["past_freq"][0..24].median;
	var current_hasFreq = msg[6];
	var recent_hasFreq = ~memory[index]["past_hasFreq"][0..24].mean;
	var onsets = msg[7];
	var current_centroid = msg[8];
	var recent_centroid = ~memory[index]["past_centroid"][0..24].median;
	var current_specFlatness = msg[9];
	var recent_specFlatness = ~memory[index]["past_specFlatness"][0..24].median;
	var current_density = msg[10];
	var recent_density = ~memory[index]["past_density"][0..24].median;
	var current_meanIOI = msg[11];
	var recent_meanIOI = ~memory[index]["past_meanIOI"][0..24].median;
	var current_varianceIOI = msg[12];
	var recent_varianceIOI = ~memory[index]["past_varianceIOI"][0..24].median;
	var current_time = msg[13];
	var buffer_event = 0;
	var current_event = 0;

	var state;
	var fadeTime = 0.8;

	var keyList = List.newClear();

	~transforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{keyList.add(key)})});
	~bufTransforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{keyList.add(key)})});


	"\rPLAYER %
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

current_time: %".format(index,current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
		recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//determine state!!!!

	case
	{current_time < 20}{state = "tacet"}
	{current_time > 20 and: {current_time < ~performanceLength}} //40 minutes
	{
		if(current_time < 120, //120 seconds - 2 minutes
			{state = "ignore"},
			{
				if((~memory[index]["state"].indicesOfEqual(~memory[index]["state"][0])? 0).asArray.last % 600 == 599,//determines state length = 2.5 minutes
					{
						case
						{~memory[index]["state"][0] == "ignore"}{state = ["support","ignore"].wchoose([0.8,0.2])}
						{~memory[index]["state"][0] == "support"}{state = ["support","tacet"].wchoose([0.8,0.2])}
						// {~memory[index]["state"][0] == "contrast"}{state = ["contrast","ignore"].choose}
						{~memory[index]["state"][0] == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
					},
					{state = ~memory[index]["state"][0]});
			}
		);
	}
	{current_time > ~performanceLength}{state = "tacet"};

	state.postln;

	//determine fadeTime!!!!...maybe this is determined by state?

	/*
	case
	{state == "support"}{fadeTime = 10}
	{state == "contrast"}{fadeTime = 6}
	{state == "ignore"}{fadeTime = 0.08};
	*/


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//transforms

	case
	{state == "support"}
	{
		if(recent_amp >= -28 and: {recent_hasFreq > 0.8} and: {recent_density >= 9} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{if(Ndef(\ringMod).isPlaying.not,
				{Ndef(\ringMod,~transforms[index]["ringMod"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\ringMod).set(\inBus,~analyserIn[index]);
					current_event = "ringMod";
					"ringMod ON".postln},
			)},
			{if(Ndef(\ringMod).isPlaying and: {~memory[index]["events"].indicesOfEqual("ringMod").last > 120},
				{Ndef(\ringMod).end(fadeTime);
					"ringMod OFF".postln}
			)}
		);

		if(recent_amp <= -12 and: {recent_amp >= -24} and: {recent_density <= 5} and: {recent_silence < 0.6} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{if(Ndef(\comber).isPlaying.not,
				{Ndef(\comber,~transforms[index]["comber"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\comber).set(\inBus,~analyserIn[index]);
					current_event = "comber";
					"comber ON".postln},
			)},
			{if(Ndef(\comber).isPlaying and: {~memory[index]["events"].indicesOfEqual("comber").last > 120},
				{Ndef(\comber).end(fadeTime);
					"comber OFF".postln}
			)}
		);

		if(recent_hasFreq > 0.6 and: {recent_density <= 7} and: {recent_amp <= -24} and: {recent_silence < 0.4} and: {Ndef(\ringMod).isPlaying.not} and: {current_time > (~performanceLength/2)} and: {keyList.size < 3}and: {current_event == 0},
			{if(Ndef(\pitchShift).isPlaying.not,
				{Ndef(\pitchShift,~transforms[index]["pitchShift"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\pitchShift).set(\inBus,~analyserIn[index]);
					current_event = "pitchShift";
					"pitchShift ON".postln},
			)},
			{if(Ndef(\pitchShift).isPlaying and: {~memory[index]["events"].indicesOfEqual("pitchShift").last > 120},
				{Ndef(\pitchShift).end(fadeTime);
					"pitchShift OFF".postln}
			)}
		);

		if(recent_amp >= -30 and: {recent_silence < 0.4} and: {current_density >= 6} and: {recent_varianceIOI < 0.2} and: {Ndef(\percShiftDelay).isPlaying.not} and: {current_time > (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{if(Ndef(\brokenRecord).isPlaying.not,
				{Ndef(\brokenRecord,~transforms[index]["brokenRecord"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\brokenRecord).set(\inBus,~analyserIn[index]);
					current_event = "brokenRecord";
					"brokenRecord ON".postln},
			)},
			{if(Ndef(\brokenRecord).isPlaying and: {~memory[index]["events"].indicesOfEqual("brokenRecord").last > 120},
				{Ndef(\brokenRecord).end(fadeTime);
					"brokenRecord OFF".postln}
			)}
		);

		if(recent_density >= 6 and: {recent_density <= 10} and: {recent_specFlatness > 0.1} and: {Ndef(\brokenRecord).isPlaying.not} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{if(Ndef(\fftFreeze).isPlaying.not,
				{Ndef(\fftFreeze,~transforms[index]["fftFreeze"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\fftFreeze).set(\inBus,~analyserIn[index]);
					current_event = "fftFreeze";
					"fftFreeze ON".postln},
			)},
			{if(Ndef(\fftFreeze).isPlaying and: {~memory[index]["events"].indicesOfEqual("fftFreeze").last > 120},
				{Ndef(\fftFreeze).end(fadeTime);
					"fftFreeze OFF".postln}
			)}
		);

		if(recent_hasFreq <= 0.3 and: {recent_silence <= 0.35} and: {~memory[index]["past_density"][0..24].maxItem >= 7} and: {recent_centroid >= 1500} and: {keyList.size < 3} and: {current_event == 0},
			{if(Ndef(\percShiftDelay).isPlaying.not,
				{Ndef(\percShiftDelay,~transforms[index]["percShiftDelay"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\percShiftDelay).set(\inBus,~analyserIn[index]);
					current_event = "percShiftDelay";
					"percShiftDelay ON".postln},
			)},
			{if(Ndef(\percShiftDelay).isPlaying and: {~memory[index]["events"].indicesOfEqual("percShiftDelay").last > 120},
				{Ndef(\percShiftDelay).end(fadeTime);
					"percShiftDelay OFF".postln}
			)}
		);

		if(current_density <= 3 and: {recent_amp <= -28} and: (recent_hasFreq > 0.75) and: {current_time > (~performanceLength/2)} and: {current_event == 0},
			{
				{2.do({Synth(\snowSines,[\atk,8.0.rrand(10.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,~memory[index]["past_freq"][..24].asSet.choose,\outBus,~switcherBus]);
					"snowSines".postln;
					10.0.rrand(13.0).wait;
				})
				}.fork;
				current_event = "snowSines";
			}
		);

		if(~memory[index]["past_amp"][0..24].maxItem >= -25 and: {current_hasFreq == 1} and: {recent_specFlatness > 0.1} and: {~memory[index]["past_density"][0..24].maxItem <= 5} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{Synth(\freezeBells,[\inBus,~analyserIn[index],\outBus,~switcherBus],Ndef(\input0).nodeID,\addAfter);
				current_event = "freezeBells";
				"freezeBells".postln;
			}
		);

		if(current_freq < 1000 and: {current_hasFreq == 1} and: {~memory[index]["past_hasFreq"][0..7].mean > 0.8} and: {recent_silence > 0.6} and: {current_time > (~performanceLength/3)} and: {keyList.size < 3} and: {current_event == 0},
			{Synth(\blasterDelay,[\inBus,~analyserIn[index],\rate,3.rrand(5),\speed,current_specFlatness,\outBus,~switcherBus],Ndef(\input0).nodeID,\addAfter); //fix this!! \input0 is sloppy!!!!!
				current_event = "blasterDelayUp";
				"blasterDelayUp".postln;
			}
		);

		if(current_freq > 1000 and: {current_hasFreq == 1} and: {~memory[index]["past_hasFreq"][0..7].mean > 0.8} and: {recent_silence > 0.6} and: {current_time < (~performanceLength/3)} and: {keyList.size < 3} and: {current_event == 0},
			{Synth(\blasterDelay,[\inBus,~analyserIn[index],\rate,3.rand,\speed,current_specFlatness,\outBus,~switcherBus],Ndef(\input0).nodeID,\addAfter); //fix this!! \input0 is sloppy!!!!!
				current_event = "blasterDelayDown";
				"blasterDelayDown".postln;
			}
		);

		if(current_density >= 10 and: {current_centroid > 3000} and: {current_amp >= -18} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},
			{Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,~switcherBus]);
				current_event = "screech";
				"screech".postln;
			}
		);

		if(recent_silence > 0.9 and: {current_time > (~performanceLength/2)} and: {current_event == 0} || {recent_centroid > 2500} and: {recent_density > 10} and: {recent_varianceIOI > 0.2} and: {current_time > (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0}},
			{if(Ndef(\tesla).isPlaying.not,
				{Ndef(\tesla,~transforms[index]["tesla"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					current_event = "tesla";
					"tesla ON".postln},
			)},
			{if(Ndef(\tesla).isPlaying and: {~memory[index]["events"].indicesOfEqual("tesla").last > 120},
				{Ndef(\tesla).end(fadeTime);
					"tesla OFF".postln}
			)}
		);

		if(recent_centroid > 3000 and: {recent_meanIOI < 0.3} and: {recent_varianceIOI < 0.1} and: {current_time < (~performanceLength/3)} and: {keyList.size < 3} and: {current_event == 0} || {Ndef(\tesla).isPlaying.not} and: {recent_silence > 0.9} and: {current_time > (~performanceLength/3)} and: {current_event == 0},
			{
				{2.do({
					2.0.rrand(10.0).wait;
					Synth(\clicks,[\ts,(recent_silence + 2) * 10,\freq,current_varianceIOI.clip(0.01,0.3),\feedback,60,\amp,0.1,\outBus,~switcherBus]);
					15.0.rrand(20.0).wait;
				})
				}.fork;
				"crawlers".postln;
				current_event = "crawlers";
			}
		);

		if(~recorder[index] > 0 and: {recent_silence >= 0.45} and: {recent_amp <= -24} and: {recent_density <= 7} and: {current_time > (~performanceLength/3)} and: {current_time < (~performanceLength * 2/3)} and: {current_event == 0},
			{if(Ndef(\bufGlitch).isPlaying.not,
				{Ndef(\bufGlitch,~bufTransforms[index]["bufGlitch"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\bufGlitch).set(\bufnum,~buffers[index][~recorder[index].rand]);
					current_event = "bufGlitch";
					"bufGlitch ON".postln},
			)},
			{if(Ndef(\bufGlitch).isPlaying and: {~memory[index]["events"].indicesOfEqual("bufGlitch").last > 120},
				{Ndef(\bufGlitch).end(fadeTime);
					"bufGlitch OFF".postln}
			)}
		);

		if(~recorder[index] > 0 and: {recent_silence > 0.6} and: {recent_amp <= -24} and: {recent_density <= 5} and: {Ndef(\bufGlitch).isPlaying.not} and: {current_time > (~performanceLength/2)} and: {current_event == 0},
			{if(Ndef(\bufStutter).isPlaying.not,
				{Ndef(\bufStutter,~bufTransforms[index]["bufStutter"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\bufStutter).set(\bufnum,~buffers[index][~recorder[index].rand]);
					current_event = "bufStutter";
					"bufStutter ON".postln},
			)},
			{if(Ndef(\bufStutter).isPlaying and: {~memory[index]["events"].indicesOfEqual("bufStutter").last > 120},
				{Ndef(\bufStutter).end(fadeTime);
					"bufStutter OFF".postln}
			)}
		);

		if(~recorder[index] > 0 and: {recent_amp <= -24} and: {recent_hasFreq > 0.6} and: {Ndef(\bufGlitch).isPlaying.not} and: {Ndef(\bufStutter).isPlaying.not} and: {current_time < (~performanceLength/2)} and: {current_event == 0},
			{if(Ndef(\bufAMRing).isPlaying.not,
				{Ndef(\bufAMRing,~bufTransforms[index]["bufAMRing"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\bufAMRing).set(\bufnum,~buffers[index][~recorder[index].rand]);
					current_event = "bufAMRing";
					"bufAMRing ON".postln},
			)},
			{if(Ndef(\bufAMRing).isPlaying and: {~memory[index]["events"].indicesOfEqual("bufAMRing").last > 120},
				{Ndef(\bufAMRing).end(fadeTime);
					"bufAMRing OFF".postln}
			)}
		);

		if(~recorder[index] > 0 and: {recent_silence > 0.4} and: {recent_density <= 8} and: {Ndef(\bufAMRing).isPlaying.not} and: {Ndef(\bufStutter).isPlaying.not} and: {current_time > (~performanceLength/2)} and: {current_event == 0},
			{if(Ndef(\tGrainz).isPlaying.not,
				{Ndef(\tGrainz,~bufTransforms[index]["tGrainz"]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(\tGrainz).set(\bufnum,~buffers[index][~recorder[index].rand]);
					current_event = "tGrainz";
					"tGrainz ON".postln},
			)},
			{if(Ndef(\tGrainz).isPlaying and: {~memory[index]["events"].indicesOfEqual("tGrainz").last > 120},
				{Ndef(\tGrainz).end(fadeTime);
					"tGrainz OFF".postln}
			)}
		);

	}

	//{state == "contrast"}{} //gotta figure this out!

	{state == "ignore"}
	{

		case
		{(~memory[index]["state"].indicesOfEqual("ignore") ? 0).asArray.last % 720 == 1}
		{
			~transforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})})
		}
		{(~memory[index]["state"].indicesOfEqual("ignore") ? 0).asArray.last % 300 == 2}
		{
			var key,newKey;

			~transforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})});

			key = ~transforms[index];
			key = key.keys.choose;
			newKey = key.asSymbol;

			if(Ndef(newKey).isPlaying.not,
				{Ndef(newKey,~transforms[index][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(newKey).set(\inBus,~analyserIn[index]);
					current_event = key;
					"% ON".format(newKey).postln;
				},
				{
					if(Ndef(newKey).isPlaying,{Ndef(newKey).end(fadeTime)})
				}
			);
		}
	}

	{state == "tacet"}
	{
		case
		{(~memory[index]["state"][..10].indicesOfEqual("tacet") ? 0).asArray.last == 4}{~transforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})})}
		{(~memory[index]["state"][..10].indicesOfEqual("tacet") ? 0).asArray.last == 8}{~bufTransforms[index].keysDo({arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})})};

		current_event = 0;

	};


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//buffer recording

	if(current_time > 60 and: {recent_density > 7} and: {recent_amp > -25} and: {~recorder[index] < 12},{
		case
		{~recorder[index] < 1}{
			Synth(\recorder,[\inBus,~analyserIn[index],\bufnum,(~buffers[index][~recorder[index]]).bufnum],Ndef(\input0).nodeID,\addAfter);
			buffer_event = "bufRec";
			"Buffer % full".format(~recorder[index]).postln;
			~recorder[index] = (~recorder[index] + 1);

		}
		{~recorder[index] >= 1}{
			if((~memory[index]["bufferEvents"].indicesOfEqual("bufRec") ? 0).asArray.first > 90,{ //at least 1.5 minutes between recordings...
				Synth(\recorder,[\inBus,~analyserIn[index],\bufnum,(~buffers[index][~recorder[index]]).bufnum],Ndef(\input0).nodeID,\addAfter);
				buffer_event = "bufRec";
				"Buffer % full".format(~recorder[index]).postln;
				~recorder[index] = (~recorder[index] + 1);
			})
		}
	});

	~memory[index]["past_amp"] = ~memory[index]["past_amp"].addFirst(current_amp);
	~memory[index]["past_silence"] = ~memory[index]["past_silence"].addFirst(current_silence);
	~memory[index]["past_freq"] = ~memory[index]["past_freq"].addFirst(current_freq);
	~memory[index]["past_hasFreq"] = ~memory[index]["past_hasFreq"].addFirst(current_hasFreq);
	~memory[index]["past_centroid"] = ~memory[index]["past_centroid"].addFirst(current_centroid);
	~memory[index]["past_specFlatness"] = ~memory[index]["past_specFlatness"].addFirst(current_specFlatness);
	~memory[index]["past_density"] = ~memory[index]["past_density"].addFirst(current_density);
	~memory[index]["past_meanIOI"] = ~memory[index]["past_meanIOI"].addFirst(current_meanIOI);
	~memory[index]["past_varianceIOI"] = ~memory[index]["past_varianceIOI"].addFirst(current_varianceIOI);

	~memory[index]["bufferEvents"] = ~memory[index]["bufferEvents"].addFirst(buffer_event);
	~memory[index]["events"] = ~memory[index]["events"].addFirst(current_event);
	~memory[index]["state"] = ~memory[index]["state"].addFirst(state);

}, '/analysis');

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////GLOBAL ANALYSER///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

OSCdef(\globalListener, {
	arg msg;
	var current_amp = msg[3].ampdb;
	var recent_amp = ~globalMemory["past_amp"][0..24].median;
	var current_silence = msg[4];
	var recent_silence = ~globalMemory["past_silence"][0..24].mean;
	var current_freq = msg[5];
	var recent_freq = ~globalMemory["past_freq"][0..24].median;
	var current_hasFreq = msg[6];
	var recent_hasFreq = ~globalMemory["past_hasFreq"][0..24].mean;
	var onsets = msg[7];
	var current_centroid = msg[8];
	var recent_centroid = ~globalMemory["past_centroid"][0..24].median;
	var current_specFlatness = msg[9];
	var recent_specFlatness = ~globalMemory["past_specFlatness"][0..24].median;
	var current_density = msg[10];
	var recent_density = ~globalMemory["past_density"][0..24].median;
	var current_meanIOI = msg[11];
	var recent_meanIOI = ~globalMemory["past_meanIOI"][0..24].median;
	var current_varianceIOI = msg[12];
	var recent_varianceIOI = ~globalMemory["past_varianceIOI"][0..24].median;
	var current_time = msg[13];
	var current_event = 0;


	"\rGLOBAL
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

current_time: %".format(current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
		recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;



	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//interrupt layer

	// if(current_time > 3.0 and: {current_time < 3.2},{Ndef(\switcher,\reverbBus)});

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	~globalMemory["past_amp"] = ~globalMemory["past_amp"].addFirst(current_amp);
	~globalMemory["past_silence"] = ~globalMemory["past_silence"].addFirst(current_silence);
	~globalMemory["past_freq"] = ~globalMemory["past_freq"].addFirst(current_freq);
	~globalMemory["past_hasFreq"] = ~globalMemory["past_hasFreq"].addFirst(current_hasFreq);
	~globalMemory["past_centroid"] = ~globalMemory["past_centroid"].addFirst(current_centroid);
	~globalMemory["past_specFlatness"] = ~globalMemory["past_specFlatness"].addFirst(current_specFlatness);
	~globalMemory["past_density"] = ~globalMemory["past_density"].addFirst(current_density);
	~globalMemory["past_meanIOI"] = ~globalMemory["past_meanIOI"].addFirst(current_meanIOI);
	~globalMemory["past_varianceIOI"] = ~globalMemory["past_varianceIOI"].addFirst(current_varianceIOI);

	~globalMemory["events"] = ~globalMemory["events"].addFirst(current_event);

}, '/globalAnalysis');

"OSCdefs loaded".postln;

);