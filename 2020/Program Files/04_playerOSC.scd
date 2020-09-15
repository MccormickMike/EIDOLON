///////////////////////////////////////////////////////EIDOLON////////////////////////////////////////////////////////////////////

/*-----------------------------------------------    analyser     -------------------------------------------*/

(
var players = ~config[\playerProfiles];
var waitBeforeStartTime = ~config[\waitBeforeStartTime];
var performanceLength = ~config[\performanceLength];
var numChannels = ~config[\numChannels];
var numPlayers = ~config[\numPlayers];
var switcherBus = ~audioBus["switcherBus"];

players.do({
	arg profileName,playerIndex;
	var memory = ~memory[playerIndex];
	var synthKeys = ~synthKeys[playerIndex];
	var analyserIn = ~audioBus["analyserIn"][playerIndex];
	var recorder = ~recorder[playerIndex];
	var maxVoices = 3; // degree of polyphony
	var minPhraseLength = 60; // 60 seconds
	var memoryScale = ~players.asArray[playerIndex][\pollRate]; // this probably needs to change at some point as well...
	var memLength = memoryScale * 6; // 6 seconds

	OSCdef("listener%".format(playerIndex).asSymbol, {
		arg msg;
		var current_amp = msg[3].ampdb;
		var recent_amp = memory["past_amp"][..memLength].median;
		var current_silence = msg[4];
		var recent_silence = memory["past_silence"][..memLength].mean;
		var current_freq = msg[5];
		var recent_freq = memory["past_freq"][..memLength].median;
		var current_hasFreq = msg[6];
		var recent_hasFreq = memory["past_hasFreq"][..memLength].mean;
		var onsets = msg[7];
		var current_centroid = msg[8];
		var recent_centroid = memory["past_centroid"][..memLength].median;
		var current_specFlatness = msg[9];
		var recent_specFlatness = memory["past_specFlatness"][..memLength].median;
		var current_density = msg[10];
		var recent_density = memory["past_density"][..memLength].median;
		var current_meanIOI = msg[11];
		var recent_meanIOI = memory["past_meanIOI"][..memLength].median;
		var current_varianceIOI = msg[12];
		var recent_varianceIOI = memory["past_varianceIOI"][..memLength].median;

		var current_time = msg[13];
		var buffer_event = 0;
		var current_event = 0;

		var keyList = List.newClear();

		var percKey = synthKeys["percSynthKeys"].first;
		var pitchKey = synthKeys["pitchSynthKeys"].first;
		var silenceKey = synthKeys["silenceSynthKeys"].first;
		var bufferKey = synthKeys["bufferSynthKeys"].first;

		var state;
		var fadeTime = 0.8;


		"\rPLAYER: %
current_amp: % \rrecent_amp: % \rcurrent_silence: % \rrecent_silence: % \rcurrent_freq: % \rrecent_freq: % \rcurrent_hasFreq: % \rrecent_hasFreq: % \ronsets: % \rcurrent_centroid: % \rrecent_centroid: %
current_specFlatness: % \rrecent_specFlatness: % \rcurrent_density: % \rrecent_density: % \rcurrent_meanIOI: % \rrecent_meanIOI: % \rcurrent_varianceIOI: % \rrecent_varianceIOI: %

current_time: %".format(profileName,current_amp,recent_amp,current_silence,recent_silence,current_freq,recent_freq,current_hasFreq,recent_hasFreq,onsets,current_centroid,recent_centroid,current_specFlatness,
			recent_specFlatness,current_density,recent_density,current_meanIOI,recent_meanIOI,current_varianceIOI,recent_varianceIOI,current_time).postln;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//determine state!!!!

		case
		{current_time < waitBeforeStartTime}{state = "tacet"} // tacet
		// {current_time > waitBeforeStartTime}{state = "support"} // just for testing....
		{current_time > waitBeforeStartTime and: {current_time < performanceLength}}
		{
			if((current_time - waitBeforeStartTime) < (performanceLength * 0.08),{ // relative to performanceLength?
				state = "ignore";
			},{
				if(memory["state"].indicesOfEqual(memory["state"].first).last % (memoryScale * performanceLength * 0.1) == 0,{ // minimum state length: 3 minutes...or also related to performance length?
					case
					{memory["state"][0] == "ignore"}{state = ["support","ignore"].wchoose([0.85,0.15])}
					{memory["state"][0] == "support"}{state = ["support","tacet"].wchoose([0.85,0.15])}
					// {memory["state"][0] == "contrast"}{state = ["contrast","ignore"].wchoose([0.65,0.35])}
					{memory["state"][0] == "tacet"}{state = ["support","ignore"].wchoose([0.75,0.25])}
				},{
					state = memory["state"][0];
				});
			});
		}
		{current_time >= performanceLength}{state = "tacet"}; // this could also call some other fucntion that neatly wraps up the performance?

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
				arg subDictKey;
				if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{keyList.add(subDictKey)})
			})
		});

		case               // need to double check this...case will go through each statement in order, prioritizing the first entries, no? Should it be a switch?
		{state == "support"}    // can these each be turned into a function with some args passed in? (conditions, transform key, etc.)
		{
			//"densePerc"
			if(recent_hasFreq <= 0.3 and: {recent_density >= 7} and: {recent_silence <= 0.35} and: {recent_centroid >= 1500} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["densePerc"][percKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln
				})
			},{
				var key = (percKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {memory["events"].indicesOfEqual(key).last > (memoryScale * minPhraseLength)},{ // prevents synths from turning off too quickly...
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"pitchTrack"
			if(recent_hasFreq > 0.6 and: {recent_density <= 7} and: {recent_silence < 0.4} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["pitchTrack"][pitchKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (pitchKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {memory["events"].indicesOfEqual(key).last > (memoryScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"fillSilence"
			if(recent_silence > 0.9 and: {current_time < (performanceLength/2)} and: {current_event == 0} || {recent_centroid > 2500} and: {recent_density > 10} and: {recent_varianceIOI > 0.2} and: {current_time > (performanceLength/2)} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~transforms["fillSilence"][silenceKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\inBus,analyserIn);
					current_event = key;
					"% ON".format(key).postln;
				})
			},{
				var key = (silenceKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {memory["events"].indicesOfEqual(key).last > (memoryScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln;
				})
			});

			//"bufTransforms"
			if(recorder > 0 and: {recent_amp <= -18} and: {recent_hasFreq > 0.3} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying.not,{
					Ndef(key.asSymbol,~bufTransforms[bufferKey]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(key.asSymbol).set(\bufnum,~buffers[playerIndex][(recorder + 1).rand]);
					"% ON".format(key).postln
				})
			},{
				var key = (bufferKey ++ playerIndex);

				if(Ndef(key.asSymbol).isPlaying and: {memory["bufferEvents"].indicesOfEqual(key).last > (memoryScale * minPhraseLength)},{
					Ndef(key.asSymbol).end(fadeTime);
					"% OFF".format(key).postln
				})
			});


			//fix all this - it's soooo messy! Can't they be put in a Dictionary and controlled by Ndefs??
			//  |
			//  |
			//  V

			if(current_density <= 3 and: {recent_amp <= -28} and: (recent_hasFreq > 0.75) and: {current_time > (performanceLength/2)} and: {current_event == 0},{
				{
					2.do({Synth(\snowSines,[\atk,8.0.rrand(10.0),\rls,8.0.rrand(10.0),\pan,1.0.rand2,\amp,0.02.rrand(0.03),\freq,memory["past_freq"][..memLength].asSet.choose,\outBus,switcherBus]);
						"snowSines%".format(playerIndex).postln;
						10.0.rrand(13.0).wait;
					})
				}.fork;
				current_event = "snowSines%".format(playerIndex);
			});

			if(memory["past_amp"][..memLength].maxItem >= -25 and: {current_hasFreq == 1} and: {recent_specFlatness > 0.1} and: {memory["past_density"][..memLength].maxItem <= 5} and: {current_time < (performanceLength/2)} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				Synth(\freezeBells,[\inBus,analyserIn,\outBus,switcherBus],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				current_event = "freezeBells%".format(playerIndex);
				"freezeBells%".format(playerIndex).postln;
			});

			if(current_density >= 10 and: {current_centroid > 3000} and: {current_amp >= -18} and: {current_time < (performanceLength/2)} and: {keyList.size <= maxVoices} and: {current_event == 0},{
				Synth(\screech,[\freq,1000,\amp,0.18.rrand(0.25),\pan,1.0.rand2,\outBus,switcherBus]);
				current_event = "screech%".format(playerIndex);
				"screech%".format(playerIndex).postln;
			});

			// these arguments are fucked, I think...

			if(recent_centroid > 3000 and: {recent_meanIOI < 0.3} and: {recent_varianceIOI < 0.1} and: {current_time < (performanceLength/3)} and: {keyList.size <= maxVoices} and: {current_event == 0} || {Ndef("tesla%".format(playerIndex).asSymbol).isPlaying.not} and: {recent_silence > 0.94} and: {current_time > (performanceLength * 0.75)} and: {current_event == 0},{
				Synth(\clicks,[\ts,current_varianceIOI.rrand(20),\freq,(recent_silence % 0.9 * 4.rrand(15)),\feedback,60,\amp,0.1,\outBus,switcherBus]);
				"crawlers%".format(playerIndex).postln;
				current_event = "crawlers%".format(playerIndex);
			});

		}

		//{state == "contrast"}{} //gotta figure this out!




		{state == "ignore"}
		{
			case
			{(memory["state"].indicesOfEqual("ignore") ? 0).asArray.last % (memoryScale * 60 * 3) == 1} //after 3 minutes(?) it should be silent for a bit?
			{
				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg subDictKey;
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime)})
					})
				});
			}
			{(memory["state"].indicesOfEqual("ignore") ? 0).asArray.last % (memoryScale * 60 * 1.5) == 2}
			{
				var dict = ~transforms.keys.choose;
				var key = ~transforms[dict].keys.choose;
				var playerKey = (key ++ playerIndex);

				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg subDictKey;
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{
							Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime);
							"% OFF".format(subDictKey ++ playerIndex).postln;
						});
					})
				});

				if(Ndef(playerKey.asSymbol).isPlaying.not,{
					Ndef(playerKey.asSymbol,~transforms[dict][key]).play(switcherBus,numChannels,fadeTime:fadeTime,group:~inGroup,addAction:\addToTail);
					Ndef(playerKey.asSymbol).set(\inBus,analyserIn);
					current_event = playerKey;
					"% ON".format(playerKey).postln;
				},{
					if(Ndef(playerKey).isPlaying,{
						Ndef(playerKey).end(fadeTime);
						"% OFF".format(playerKey).postln;
					});
				});
			};

			// need to also add a way to use all the other synths here, regardless of input....

		}

		{state == "tacet"} //this doesn't seem to always work...
		{
			// need another conditional - if Ndefs.all(not all though, becase we want to keep our analysers going).do.isPlaying.etc.
			// then kill 'em all
			// otherwise don't do anything and save some CPU

			if((memory["state"].indicesOfEqual("tacet").asArray.at(memoryScale) ? 0) == memoryScale,{
				~transforms.values.collect({
					arg subDicts;
					subDicts.keysDo({
						arg subDictKey;
						if(Ndef((subDictKey ++ playerIndex).asSymbol).isPlaying,{
							Ndef((subDictKey ++ playerIndex).asSymbol).end(fadeTime)
						})
					})
				});

				~bufTransforms.keysDo({
					arg key;
					if(Ndef((key ++ playerIndex).asSymbol).isPlaying,{
						Ndef((key ++ playerIndex).asSymbol).end(fadeTime)
					})
				})
			});

			current_event = 0;

		};

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//buffer recording


		//this is a bad if statment!!! The logic doesn't really make sense - it should be nested inside another if statement...
		if(current_time > waitBeforeStartTime and: {recent_density > 7} and: {recent_amp > -25} and: {recorder < 12},{
			case
			{recorder < 1}{
				Synth(\recorder,[\inBus,analyserIn,\bufnum,(~buffers[playerIndex][recorder]).bufnum],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
				buffer_event = "bufRec" ++ playerIndex;
				"Buffer % full".format(recorder).postln;
				recorder = (recorder + 1);
			}
			{recorder >= 1}{
				if((memory["bufferEvents"].indicesOfEqual("bufRec" ++ playerIndex) ? 0).asArray.first > (memoryScale * 60 * 1.5),{ //at least 1.5 min between recordings...
					Synth(\recorder,[\inBus,analyserIn,\bufnum,(~buffers[playerIndex][recorder]).bufnum],Ndef("input%".format(playerIndex).asSymbol).nodeID,\addAfter);
					buffer_event = "bufRec" ++ playerIndex;
					"Buffer % full".format(recorder).postln;
					recorder = (recorder + 1);
				})
			}
		});

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//cycle synths


		// this cycles based on time...should it also be based on number of occurences?
		(
			synthKeys.keysDo({
				arg key;
				var synthKey = (synthKeys[key].first ++ playerIndex);

				if(Ndef(synthKey.asSymbol).isPlaying.not and: {(memory["events"].indicesOfEqual(synthKey) ? 0).asArray.last > (memoryScale * (performanceLength/5))},{
					synthKeys[key] = synthKeys[key].rotate(-1);
				});
			})
		);

		// can this be rewritten into an iteration / .do statement?

		memory["past_amp"] = memory["past_amp"].addFirst(current_amp);
		memory["past_silence"] = memory["past_silence"].addFirst(current_silence);
		memory["past_freq"] = memory["past_freq"].addFirst(current_freq);
		memory["past_hasFreq"] = memory["past_hasFreq"].addFirst(current_hasFreq);
		memory["past_centroid"] = memory["past_centroid"].addFirst(current_centroid);
		memory["past_specFlatness"] = memory["past_specFlatness"].addFirst(current_specFlatness);
		memory["past_density"] = memory["past_density"].addFirst(current_density);
		memory["past_meanIOI"] = memory["past_meanIOI"].addFirst(current_meanIOI);
		memory["past_varianceIOI"] = memory["past_varianceIOI"].addFirst(current_varianceIOI);

		memory["bufferEvents"] = memory["bufferEvents"].addFirst(buffer_event);
		memory["events"] = memory["events"].addFirst(current_event);
		memory["state"] = memory["state"].addFirst(state);

	},'/analysis');

});

"Analysers loaded".postln;

)