///////////////////////////////////////////////////////EIDOLON//////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////INDIVIDUAL ANALYSER///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
(
OSCdef(\listener0, {
	arg msg;
	var index = 0; //Makesx into a .do statement!!!!!
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


	"\rPLAYER %
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

current_time: %".format(index,current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
		recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//determine state!!!!

	case
	{current_time < 30}{state = "support"}//tacet
/*	{current_time > 30 and: {current_time < 2400}}//40 minutes
	{
		if(current_time < 150,//120 seconds - 2 minutes
			{state = "ignore"},
			{
				if(~memory[index]["state"].indicesOfEqual(~memory[index]["state"][0]).last % 600 == 0,//determines minimum phrase length...
					{
						case
						{~memory[index]["state"][0] == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
						{~memory[index]["state"][0] == "support"}{state = ["support","tacet"].wchoose([0.85,0.15])}
						// {~memory[index]["state"][0] == "contrast"}{state = ["contrast","ignore"].choose}
						{~memory[index]["state"][0] == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
					},
					{state = ~memory[index]["state"][0]});
			}
		);
	}*/
	{current_time > 2400}{state = "tacet"};

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
		var keyList = List.newClear();

		~transforms[index].values.flat.collect({
			arg subDicts; subDicts.keysDo({
				arg key; if(Ndef(key.asSymbol).isPlaying,{keyList.add(key)})
			})
		});

		//{keyList.size < 3}


		case
		{current_time.round % 5 == 3}//"densePerc"
		{var key = ~synthKeys[index]["percSynthKeys"][0];

			if(keyList.size < 3,
				{if(Ndef(key.asSymbol).isPlaying.not,
					{Ndef(key.asSymbol,~transforms[index]["densePerc"][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
						Ndef(key.asSymbol).set(\inBus,~analyserIn[index]);
						current_event = key;
						"% ON".format(key).postln},
				)},
				{if(Ndef(key.asSymbol).isPlaying and: {~memory[index]["events"].indicesOfEqual(key).last > 120},
					{Ndef(key.asSymbol).end(fadeTime);
						"% OFF".format(key).postln}
				)}
			);
		}
		{current_time.round % 20 == 19} //"pitchTrack"
		{var key = ~synthKeys[index]["pitchSynthKeys"][0];

			if(keyList.size < 3,
				{if(Ndef(key.asSymbol).isPlaying.not,
					{Ndef(key.asSymbol,~transforms[index]["pitchTrack"][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
						Ndef(key.asSymbol).set(\inBus,~analyserIn[index]);
						current_event = key;
						"% ON".format(key).postln},
				)},
				{if(Ndef(key.asSymbol).isPlaying and: {~memory[index]["events"].indicesOfEqual(key).last > 120},
					{Ndef(key.asSymbol).end(fadeTime);
						"% OFF".format(key).postln}
				)}
			);
		}
		{current_time.round % 500 == 20} //"fillSilence"
		{var key = ~synthKeys[index]["silenceSynthKeys"][0];

			if(keyList.size < 3,
				{if(Ndef(key.asSymbol).isPlaying.not,
					{Ndef(key.asSymbol,~transforms[index]["fillSilence"][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
						// Ndef(key.asSymbol).set(\inBus,~analyserIn[index]);
						current_event = key;
						"% ON".format(key).postln},
				)},
				{if(Ndef(key.asSymbol).isPlaying and: {~memory[index]["events"].indicesOfEqual(key).last > 120},
					{Ndef(key.asSymbol).end(fadeTime);
						"% OFF".format(key).postln}
				)}
			);
		}
		{~recorder[index] > 0} //"bufTransforms"
		{var key = ~synthKeys[index]["bufferSynthKeys"][0];

			if(keyList.size < 3,
				{if(Ndef(key.asSymbol).isPlaying.not,
					{Ndef(key.asSymbol,~bufTransforms[index][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
						Ndef(key.asSymbol).set(\bufnum,~buffers[index][~recorder[index].rand]);
						current_event = key;
						"% ON".format(key).postln},
				)},
				{if(Ndef(key.asSymbol).isPlaying and: {~memory[index]["events"].indicesOfEqual(key).last > 120},
					{Ndef(key.asSymbol).end(fadeTime);
						"% OFF".format(key).postln}
				)}
			);
		}

		//add synthesized sounds (snow sines, etc.)
	}

	//{state == "contrast"}{} //gotta figure this out!

	{state == "ignore"}
	{
		case
		{~memory[index]["state"].indicesOfEqual("ignore").asArray.last % 720 == 1}
		{
			~transforms[index].values.flat.collect({
				arg subDicts; subDicts.keysDo({
					arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})
				})
			});
		}
		{~memory[index]["state"].indicesOfEqual("ignore").asArray.last % 300 == 2}
		{
			var key,dict,newKey;

			~transforms[index].values.flat.collect({
				arg subDicts; subDicts.keysDo({
					arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})
				})
			});

			dict = ~transforms[index].keys.choose;
			key = ~transforms[index][dict].keys.choose;
			newKey = key.asSymbol;

			if(Ndef(newKey).isPlaying.not,
				{Ndef(newKey,~transforms[index][dict][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
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
		if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == 4,{
			~transforms[index].values.flat.collect({
				arg subDicts; subDicts.keysDo({
					arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})
				})
			});
		});

		if(~memory[index]["state"].indicesOfEqual("tacet").asArray.last == 8,{
			~bufTransforms[index].keysDo({
				arg key; if(Ndef(key.asSymbol).isPlaying,{Ndef(key.asSymbol).end(fadeTime)})
			})
		});

		current_event = 0;

	};

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//buffer recording

	if(current_time > 10 and: {recent_density > 7} and: {recent_amp > -25} and: {~recorder[index] < 8},{
		case
		{~recorder[index] < 1}{ //must make the Ndef symbol name ++ index
			Synth(\recorder,[\inBus,~analyserIn[index],\bufnum,(~buffers[index][~recorder[index]]).bufnum],Ndef(\input0).nodeID,\addAfter);
			buffer_event = "bufRec";
			"Buffer % full".format(~recorder[index]).postln;
			~recorder[index] = (~recorder[index] + 1);

		}
		{~recorder[index] >= 1}{
			if((~memory[index]["bufferEvents"].indicesOfEqual("bufRec") ? 0).asArray.first > 120,{ //at least two minutes between recordings...
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