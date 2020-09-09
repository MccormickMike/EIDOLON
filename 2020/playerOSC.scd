///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

/*-----------------------------------------------    analyser     -------------------------------------------*/

(
~numPlayers.do({
	arg playerIndex;

	OSCdef("listener%".format(playerIndex).asSymbol, {
		arg msg;
		var current_amp = msg[3].ampdb;
		var recent_amp = ~memory[playerIndex]["past_amp"][0..24].median;
		var current_silence = msg[4];
		var recent_silence = ~memory[playerIndex]["past_silence"][0..24].mean;
		var current_freq = msg[5];
		var recent_freq = ~memory[playerIndex]["past_freq"][0..24].median;
		var current_hasFreq = msg[6];
		var recent_hasFreq = ~memory[playerIndex]["past_hasFreq"][0..24].mean;
		var onsets = msg[7];
		var current_centroid = msg[8];
		var recent_centroid = ~memory[playerIndex]["past_centroid"][0..24].median;
		var current_specFlatness = msg[9];
		var recent_specFlatness = ~memory[playerIndex]["past_specFlatness"][0..24].median;
		var current_density = msg[10];
		var recent_density = ~memory[playerIndex]["past_density"][0..24].median;
		var current_meanIOI = msg[11];
		var recent_meanIOI = ~memory[playerIndex]["past_meanIOI"][0..24].median;
		var current_varianceIOI = msg[12];
		var recent_varianceIOI = ~memory[playerIndex]["past_varianceIOI"][0..24].median;
		var current_time = msg[13];
		var buffer_event = 0;
		var current_event = 0;

		var keyList = List.newClear();
		var percKey = ~synthKeys[playerIndex]["percSynthKeys"][0];
		var pitchKey = ~synthKeys[playerIndex]["pitchSynthKeys"][0];
		var silenceKey = ~synthKeys[playerIndex]["silenceSynthKeys"][0];
		var bufferKey = ~synthKeys[playerIndex]["bufferSynthKeys"][0];

		var state;
		var fadeTime = 0.8;


		"\rPLAYER %
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

current_time: %".format(playerIndex,current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
			recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//determine state!!!!

		case
		{current_time < ~waitBeforeStartTime}{state = "tacet"} //tacet
		// {current_time > ~waitBeforeStartTime}{state = "support"} // testing....
		{current_time > ~waitBeforeStartTime and: {current_time < ~performanceLength}}
		{
			if((current_time - ~waitBeforeStartTime) < 120,//2 minutes of ignore time...
				{state = "ignore"},
				{
					if(~memory[playerIndex]["state"].indicesOfEqual(~memory[playerIndex]["state"][playerIndex]).last % 300 == 0,//determines minimum phrase length...
						{
							case
							{~memory[playerIndex]["state"][0] == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
							{~memory[playerIndex]["state"][0] == "support"}{state = ["support","tacet"].wchoose([0.85,0.15])}
							// {~memory[playerIndex]["state"][0] == "contrast"}{state = ["contrast","ignore"].wchoose([0.65,0.35])}
							{~memory[playerIndex]["state"][0] == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
						},
						{state = ~memory[playerIndex]["state"][0]});
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

		~transforms.values.collect({
			arg subDicts;
			subDicts.keysDo({
				arg key;
				if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{keyList.add(key)})
			})
		});

		case
		{state == "support"}
		{
			//"densePerc"
			if(recent_hasFreq <= 0.3 and: {recent_density >= 7} and: {recent_silence <= 0.35} and: {recent_centroid >= 1500} and: {keyList.size < 3} and: {current_event == 0},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["densePerc"][percKey]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,~analyserIn[playerIndex]);
					current_event = key;
					"% ON".format(key).postln
				})
			},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).last > 120},{ // prevents synths from turning off too quickly...
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"pitchTrack"
			if(recent_hasFreq > 0.6 and: {recent_density <= 7} and: {recent_silence < 0.4} and: {keyList.size < 3} and: {current_event == 0},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["pitchTrack"][pitchKey]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,~analyserIn[playerIndex]);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).last > 120},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"fillSilence"
			if(recent_silence > 0.9 and: {current_time < (~performanceLength/2)} and: {current_event == 0} || {recent_centroid > 2500} and: {recent_density > 10} and: {recent_varianceIOI > 0.2} and: {current_time > (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["fillSilence"][silenceKey]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,~analyserIn[playerIndex]);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).last > 120},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});


			//fix all this - it's soooo messy! Can't they be put in a Dictionary and controlled by Ndefs??
			//  |
			//  |
			//  V

			if(current_density <= 3 and: {recent_amp <= -28} and: (recent_hasFreq > 0.75) and: {current_time > (~performanceLength/2)} and: {current_event == 0},{
				{
					2.do({Synth(\snowSines,[\atk,8.0.rrand(10.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,~memory[playerIndex]["past_freq"][..24].asSet.choose,\outBus,~switcherBus]);
						"snowSines%".format(playerIndex).postln;
						10.0.rrand(13.0).wait;
					})
				}.fork;
				current_event = "snowSines%".format(playerIndex);
			});

			if(~memory[playerIndex]["past_amp"][0..24].maxItem >= -25 and: {current_hasFreq == 1} and: {recent_specFlatness > 0.1} and: {~memory[playerIndex]["past_density"][0..24].maxItem <= 5} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},{
				Synth(\freezeBells,[\inBus,~analyserIn[playerIndex],\outBus,~switcherBus],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				current_event = "freezeBells%".format(playerIndex);
				"freezeBells%".format(playerIndex).postln;
			});

			if(current_density >= 10 and: {current_centroid > 3000} and: {current_amp >= -18} and: {current_time < (~performanceLength/2)} and: {keyList.size < 3} and: {current_event == 0},{
				Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,~switcherBus]);
				current_event = "screech%".format(playerIndex);
				"screech%".format(playerIndex).postln;
			});

			if(recent_centroid > 3000 and: {recent_meanIOI < 0.3} and: {recent_varianceIOI < 0.1} and: {current_time < (~performanceLength/3)} and: {keyList.size < 3} and: {current_event == 0} || {Ndef("tesla%".format(playerIndex).asSymbol).isPlaying.not} and: {recent_silence > 0.94} and: {current_time > (~performanceLength * 0.75)} and: {current_event == 0},{
				Synth(\clicks,[\ts,current_varianceIOI.rrand(20),\freq,(recent_silence % 0.9 * 4.rrand(15)),\feedback,60,\amp,0.1,\outBus,~switcherBus]);

				"crawlers%".format(playerIndex).postln;
				current_event = "crawlers%".format(playerIndex);
			});

			//"bufTransforms"
			if(~recorder[playerIndex] > 0 and: {recent_amp <= -18} and: {recent_hasFreq > 0.3} and: {keyList.size < 3} and: {current_event == 0},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~bufTransforms[bufferKey]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\bufnum,~buffers[playerIndex][(~recorder[0] + 1).rand]); //double check this...can maybe use recorder.size.rand?
					current_event = key;
					"% ON".format(key).postln
				})
			},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {~memory[playerIndex]["events"].indicesOfEqual(key).last > 120},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln
				})
			});

		}

		//{state == "contrast"}{} //gotta figure this out!




		{state == "ignore"}
		{
			case
			{(~memory[playerIndex]["state"].indicesOfEqual("ignore") ? 0).asArray.last % 720 == 1} //after 3 minutes (?????) it should be silent for a bit...I think!
			{
				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg key;
						if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{Ndef((key ++ playerIndex).asSymbol).end(fadeTime)})
					})
				});
			}
			{(~memory[playerIndex]["state"].indicesOfEqual("ignore") ? 0).asArray.last % 180 == 2}
			{
				var key,dict, playerKey;

				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg key;
						if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{Ndef((key ++ playerIndex).asSymbol).end(fadeTime)});
						"% OFF".format(playerKey).postln;
					})
				});

				dict = ~transforms.keys.choose;
				key = ~transforms[dict].keys.choose;
				playerKey = (key ++ playerIndex);

				if(Ndef(playerKey.asSymbol).isPlaying.not,
					{Ndef(playerKey.asSymbol,~transforms[dict][key]).play(~switcherBus,~numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
						Ndef(playerKey.asSymbol).set(\inBus,~analyserIn[playerIndex]);
						current_event = playerKey;
						"% ON".format(playerKey).postln;
					},
					{
						if(Ndef(playerKey).isPlaying,{Ndef(playerKey).end(fadeTime)});
						"% OFF".format(playerKey).postln;
					}
				);
			}
		}

		{state == "tacet"} //this doesn't seem to always work...
		{
			if((~memory[playerIndex]["state"].indicesOfEqual("tacet").asArray.at(4) ? 0) == 4,{
				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg key;
						if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{Ndef((key ++ playerIndex).asSymbol).end(fadeTime)})
					})
				});

				~bufTransforms.keysDo({
					arg key;
					if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{Ndef((key ++ playerIndex).asSymbol).end(fadeTime)})
				})
			});

			current_event = 0;

		};

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//buffer recording

		if(current_time > ~waitBeforeStartTime and: {recent_density > 7} and: {recent_amp > -25} and: {~recorder[playerIndex] < 12},{ //the current_time value should also be linked to the startTime variable??
			case
			{~recorder[playerIndex] < 1}{ //must make the Ndef symbol name ++ index
				Synth(\recorder,[\inBus,~analyserIn[playerIndex],\bufnum,(~buffers[playerIndex][~recorder[playerIndex]]).bufnum],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				buffer_event = "bufRec" ++ playerIndex;
				"Buffer % full".format(~recorder[playerIndex]).postln;
				~recorder[playerIndex] = (~recorder[playerIndex] + 1);

			}
			{~recorder[playerIndex] >= 1}{
				if((~memory[playerIndex]["bufferEvents"].indicesOfEqual("bufRec" ++ playerIndex) ? 0).asArray.first > 90,{ //at least two minutes between recordings...
					Synth(\recorder,[\inBus,~analyserIn[playerIndex],\bufnum,(~buffers[playerIndex][~recorder[playerIndex]]).bufnum],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
					buffer_event = "bufRec" ++ playerIndex;
					"Buffer % full".format(~recorder[playerIndex]).postln;
					~recorder[playerIndex] = (~recorder[playerIndex] + 1);
				})
			}
		});

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//cycle synths

		(
			~synthKeys[playerIndex].keysDo({
				arg key;
				var synthKey = (~synthKeys[playerIndex][key][0] ++ playerIndex);

				if(Ndef(synthKey.asSymbol).isPlaying.not and: {(~memory[playerIndex]["events"].indicesOfEqual(synthKey) ? 0).asArray.last > 720},{ //should cycle synths every 3 minutes
					~synthKeys[playerIndex][key] = ~synthKeys[playerIndex][key].rotate(-1);
				});
			})
		);

		// can this be rewritten into an iteration/.do statement?

		~memory[playerIndex]["past_amp"] = ~memory[playerIndex]["past_amp"].addFirst(current_amp);
		~memory[playerIndex]["past_silence"] = ~memory[playerIndex]["past_silence"].addFirst(current_silence);
		~memory[playerIndex]["past_freq"] = ~memory[playerIndex]["past_freq"].addFirst(current_freq);
		~memory[playerIndex]["past_hasFreq"] = ~memory[playerIndex]["past_hasFreq"].addFirst(current_hasFreq);
		~memory[playerIndex]["past_centroid"] = ~memory[playerIndex]["past_centroid"].addFirst(current_centroid);
		~memory[playerIndex]["past_specFlatness"] = ~memory[playerIndex]["past_specFlatness"].addFirst(current_specFlatness);
		~memory[playerIndex]["past_density"] = ~memory[playerIndex]["past_density"].addFirst(current_density);
		~memory[playerIndex]["past_meanIOI"] = ~memory[playerIndex]["past_meanIOI"].addFirst(current_meanIOI);
		~memory[playerIndex]["past_varianceIOI"] = ~memory[playerIndex]["past_varianceIOI"].addFirst(current_varianceIOI);

		~memory[playerIndex]["bufferEvents"] = ~memory[playerIndex]["bufferEvents"].addFirst(buffer_event);
		~memory[playerIndex]["events"] = ~memory[playerIndex]["events"].addFirst(current_event);
		~memory[playerIndex]["state"] = ~memory[playerIndex]["state"].addFirst(state);

	}, '/analysis');

});

"Analysers loaded".postln;

);