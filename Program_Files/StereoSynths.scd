///////////////////////////////////////////////////////EIDOLON//////////////////////////////////////////////////////////////////////
(
(
~transforms = ~numPlayers.collect({
	arg player;

	Dictionary[

		"ringMod" -> {
			arg inBus;
			var dev,gate,mod,sig;

			dev = TExpRand.kr(0.01,4000,In.kr(~onsetsBus));
			gate = In.kr(~hasFreqBus);
			sig = (In.ar(inBus,1))*gate;
			mod = SinOsc.ar(In.kr(~freqBus)*2*SinOsc.ar(dev).range(0.75,0.75.reciprocal));
			sig = sig*mod;
			sig = Pan2.ar(sig,LFNoise2.kr(0.2));
		},

		"comber" -> {
			arg inBus;
			var trig,gate,ramp,rand,sig;

			sig = In.ar(inBus,1);
			trig = In.kr(~onsetsBus);
			gate = EnvGen.ar(Env.perc(0.05,0.125),trig);
			rand = TExpRand.kr(0.0001,0.001,trig);
			ramp = Phasor.ar(trig,rand*[1,1.01],0.01,rand.linlin(0.0001,0.001,0.05,0.1),0.01);
			sig = CombC.ar(sig * gate,0.1,ramp.linexp(0.01,1.0,0.01,1.0),3.0,0.1);
			sig = LeakDC.ar(sig);
		},


		"pitchShift" -> {
			arg inBus;
			var grainSize=0.15,freqDev,maxDev,sig;

			freqDev = Drand([7/8,8/7,8/9,9/8,9/10,10/9],inf);
			freqDev = Demand.kr(Dust.kr(In.kr(~specFlatnessBus)*5),0,freqDev);
			maxDev = SinOsc.kr(In.kr(~varianceIOIBus)).clip(0.01,0.05);
			sig = In.ar(inBus,1);
			sig = PitchShift.ar(sig,grainSize,freqDev,maxDev,grainSize);
			sig = Pan2.ar(sig,LFNoise2.kr(0.2));
		},

		"brokenRecord" -> {
			arg inBus,amp=0.7;
			var gate,rand,sig,sig1,trig;

			sig = In.ar(inBus,1);
			trig = In.kr(~onsetsBus) + In.kr(~hasFreqBus);
			gate = EnvGen.ar(Env.sine(0.1),trig);
			rand = In.kr(~silenceBus);
			rand = TExpRand.kr(0.05,0.3,rand);
			sig = CombC.ar(sig*gate,0.6,rand,Select.kr(Trig1.kr(trig,rand-0.01),[inf,0]));
			sig1 = DelayN.ar(sig,0.6,rand*7/5);
			sig = Pan2.ar(sig,LFNoise2.kr(0.2)) + Pan2.ar(sig1,LFNoise2.kr(0.2));
			sig*amp;
		},

		"percShiftDelay" -> {
			arg inBus,amp=1.0;
			var freqDev,maxDev,grainSize=1.0,freq,hasFreq,sig;

			freqDev = In.kr(~varianceIOIBus).clip(0.6,1.2);
			maxDev = In.kr(~specFlatnessBus).clip(0.3,0.8);
			sig = In.ar(inBus,1);
			sig = sig + LocalIn.ar(1);
			#freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.05, median: 7);
			sig = sig*(1-hasFreq);
			sig = PitchShift.ar(sig,grainSize,freqDev.clip(0.5,4.0),maxDev.clip(0.0,3.0),grainSize);
			sig = LeakDC.ar(sig);
			LocalOut.ar(sig*0.7);
			sig = Pan2.ar(sig,TRand.kr(-1.0,1.0,1-hasFreq).lag(maxDev),amp);
		},

		"tesla" -> {
			arg carfreq=1.3,modfreq=8000,modFB=3,filt=8000,rq=1,amp=0.08;
			var car,mod,sig;

			mod = SinOscFB.ar(modfreq*Dust.ar(LFNoise0.kr(0.3).range(0.2,10)).lag,modFB);
			car = LFTri.ar([carfreq,carfreq*1.05],pi,0.5,0.5)+mod;
			sig = car*mod;
			sig = BHiPass4.ar(sig,100,2);
			sig = BLowPass4.ar(sig,filt,rq);
			sig = LeakDC.ar(sig);
			sig = sig*amp;
		},
	];
});

~bufTransforms = ~numPlayers.collect({
	arg player;
	Dictionary[
		"bufGlitch" -> {
			arg bufnum;
			var freq,bufFr,pointer,sig;

			freq = (In.kr(~specFlatnessBus)).clip(0.6,1.0);
			bufFr = BufFrames.kr(bufnum)-1;
			pointer = LFDNoise1.ar(freq).range(0,bufFr);
			sig = BufRd.ar(1,bufnum,pointer,1);
			sig = Pan2.ar(sig,pointer.linlin(0,bufFr,-1.0,1.0))

		},

		"bufStutter" -> {
			arg bufnum;
			var bufFr,trig,rand,speed,rate,pointer,sig;

			rate = TExpRand.kr(0.7,1.1,In.kr(~silenceBus));
			speed = In.kr(~hasFreqBus).clip(1.0,6.0);
			bufFr = BufFrames.kr(bufnum)-1;
			trig = Impulse.kr(speed.lag(0.5));
			pointer = Phasor.ar(0,0.05,0,bufFr);
			rand = TIRand.kr(-1,1,trig);
			sig = PlayBuf.ar(1,bufnum,rate,trig,pointer,loop: 1).lag(rate.reciprocal*0.066);
			sig = BLowPass4.ar(sig,6000);
			sig = Pan2.ar(sig,pointer.linlin(0,bufFr,rand.asFloat,rand.neg.asFloat),0.8);
		},

		"bufAMRing" -> {
			arg bufnum;
			var modfreq,ringfreq,car,mod,sig;

			ringfreq = Latch.kr(In.kr(~centroidBus),Impulse.kr(0.8));
			modfreq = 7;
			car = BufRd.ar(1,bufnum,LFTri.ar((BufDur.ir(bufnum).reciprocal)*LFNoise2.kr(0.5).range(0.6,0.8)).range(0, BufFrames.ir(bufnum)),1);
			mod = LFPulse.ar(modfreq*LFNoise2.kr(2).range(0.2,2.0),0,LFNoise0.ar(4).range(0.3,0.8)).abs;
			sig = car*mod.lag;
			sig = sig * SinOsc.ar(ringfreq);
			sig = BHiShelf.ar(sig,6000,0.5,-6);
			sig = Pan2.ar(sig,LFNoise2.kr(0.2));
		},

		"tGrainz" -> {
			arg bufnum,amp=0.8;
			var sig,rate,trig,pointer,posDif=0.5,posLo,posDev=0.03,bufSection,bufDur,grainDur=1.2;

			trig = In.kr(~silenceBus);
			rate = Latch.kr(In.kr(~specFlatnessBus),trig);
			bufDur = BufDur.kr(bufnum);
			posLo = TRand.kr(0.0,0.5,In.kr(~hasFreqBus));
			bufSection = bufDur * posDif;
			pointer = posLo * bufDur +
			(Phasor.ar(trig, BufRateScale.kr(bufnum) / SampleRate.ir,posLo * bufDur,(posLo + posDif) * bufDur)
				+
				(TRand.kr(-0.5 * posDev, 0.5 * posDev, trig) * bufDur)).mod(bufSection);

			sig = TGrains.ar(2,trig,bufnum,rate.clip(0.3,2.0).neg,pointer,grainDur,Latch.kr(LFNoise2.kr(40),trig),amp);
		},

	]
});

SynthDef(\inPlayer,{
	arg inBus,compThresh=0.5,filtFreqHi=2000,rsHi=0.25,filtFreqLo=80,rsLo=0.25,amp=1.0,analyserOut,transformOut,outBus;
	var sig;

	sig = SoundIn.ar(inBus);
	sig = BHiShelf.ar(sig,filtFreqHi,rsHi,0);
	sig = BLowShelf.ar(sig,filtFreqLo,rsLo,0);
	sig = Compander.ar(sig,sig,compThresh,1,0.5,0.01,0.01);
	sig = Pan2.ar(sig,0);
	Out.ar(analyserOut,Mix(sig));
	Out.ar(outBus,sig*amp);

}).add;

SynthDef(\analyser, {
	arg inBus,frames=1024,thresh;
	var sig,amp,silence,freq,hasFreq,chain,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time,trig;

	sig = In.ar(inBus,1);

	amp = Amplitude.kr(sig);
	silence = DetectSilence.ar(sig + Impulse.ar(0),0.01);
	# freq, hasFreq = Pitch.kr(LPF.ar(sig,2000) , ampThreshold: 0.01, median: 7);
	chain = FFT(LocalBuf(frames),sig);
	onsets = Onsets.kr(chain,thresh, \rcomplex);
	centroid = SpecCentroid.kr(chain);
	specFlatness = SpecFlatness.kr(chain);
	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,3.0);
	time = Sweep.ar;
	trig = Impulse.kr(4);

	SendReply.kr(trig, '/analysis', [amp,silence,freq,hasFreq,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time]);
	Out.kr(~ampBus,amp);
	Out.kr(~silenceBus,silence);
	Out.kr(~freqBus,freq);
	Out.kr(~hasFreqBus,hasFreq);
	Out.kr(~onsetsBus,onsets);
	Out.kr(~centroidBus,centroid);
	Out.kr(~specFlatnessBus,specFlatness);
	Out.kr(~densityBus,density);
	Out.kr(~meanIOIBus,meanIOI);
	Out.kr(~varianceIOIBus,varianceIOI);

}).add;

SynthDef(\switcher,{
	arg inBus,outBus;
	var sig;

	sig = In.ar(inBus,~numChannels);
	Out.ar(outBus,sig);

}).add;

SynthDef(\globalOut,{
	arg inBus,frames=1024,compThresh,thresh,outBus;
	var in,sig,amp,silence,freq,hasFreq,chain,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,trig,time;

	in = In.ar(inBus,~numChannels);
	sig = Mix(in);

	amp = Amplitude.kr(sig);
	silence = DetectSilence.ar(sig + Impulse.ar(0),0.01);
	# freq, hasFreq = Pitch.kr(LPF.ar(sig,2000) , ampThreshold: 0.01, median: 7);
	chain = FFT(LocalBuf(frames),sig);
	onsets = Onsets.kr(chain,thresh, \rcomplex);
	centroid = SpecCentroid.kr(chain);
	specFlatness = SpecFlatness.kr(chain);
	# density, meanIOI, varianceIOI = OnsetStatistics.kr(onsets,3.0);
	time = Sweep.ar;
	trig = Impulse.kr(4);

	SendReply.kr(trig, '/globalAnalysis', [amp,silence,freq,hasFreq,onsets,centroid,specFlatness,density,meanIOI,varianceIOI,time]);

	in = Compander.ar(in,in,compThresh,1,0.5,0.01,0.01);
	Out.ar(outBus,in);

}).add;

SynthDef(\recorder,{
	arg inBus,bufnum,recLevel=1.0, preLevel=0.0;
	var sig;

	sig = In.ar(inBus,1);
	RecordBuf.ar(sig,bufnum,0,recLevel,preLevel,loop:0, doneAction: 2);

}).add;

SynthDef(\reverb,{
	arg inBus,mix=0.8,room=100,damp=0.2,amp=0.8,outBus;
	var sig;

	sig = In.ar(inBus,~numChannels);
	sig = FreeVerb.ar(sig,mix,room,damp);
	Out.ar(outBus,sig);

}).add;

SynthDef(\snowSines, {
	arg freq,rq=0.5,atk,rls,gate=1,pan,amp,outBus;
	var env,sig;

	env = EnvGen.kr(Env([0,1,0],[atk,rls]),gate,doneAction: 2);
	sig = SinOsc.ar(freq)*BrownNoise.ar(0.5,0.5);
	sig = RLPF.ar(sig,freq*1.5,rq,1/rq.sqrt);
	sig = Pan2.ar(sig,pan,amp*0.7);
	sig = sig*env;
	Out.ar(outBus,sig);

}).add;

SynthDef(\screech,{
	arg freq=80,trig=1,amp=0.8,pan=0,outBus=0;
	var in,sig;

	in = SinOsc.ar(freq)*Trig.kr(trig,0.04);
	sig = CombC.ar(in,0.04,0.04*LFNoise0.ar(50).abs,6.0,1);
	sig = Limiter.ar(sig,1.0);
	sig = Pan2.ar(sig,pan,amp);
	sig = LeakDC.ar(sig);
	DetectSilence.ar(sig,doneAction:2);
	Out.ar(outBus,sig);

}).add;

SynthDef(\freezeBells,{
	arg inBus,outBus,amp=0.8;
	var chain,ramp,rate,sig;

	ramp = Line.ar(-1.0,-0.001,ExpRand(8.0,14.0),doneAction: 2);
	sig = In.ar(inBus,1);
	chain = FFT(LocalBuf(1024),sig);
	chain = PV_Freeze(chain,1);
	chain = PV_BrickWall(chain,ramp);
	sig = IFFT(chain)!2;
	sig = AllpassC.ar(sig,0.2,0.2,1.0);
	sig = Splay.ar(sig*ramp.abs,ramp.abs.reciprocal/1000,amp);
	sig = Out.ar(outBus,sig);

}).add;

SynthDef(\clicks,{
	arg freq,feedback,outBus,ts,amp=0.1;
	var osc,sig,env,pan;

	osc = SinOscFB.ar([freq,freq*1.005],feedback);
	env = EnvGen.kr(Env.new([0.01,1,0.01],[0.05,0.5],\exp),1,timeScale:ts.clip(2,20),doneAction: 2);
	pan = LinRand(-1,1);
	sig = osc*osc+osc;
	sig = BLowPass.ar(sig,8000*env.lag(ts*0.8),env.reciprocal/4);
	sig = Pan2.ar(sig*env,Line.kr(pan,pan.neg,ts/4));
	sig = LeakDC.ar(sig);
	Out.ar(outBus,sig*amp);

}).add;

);

"Transforms loaded".postln;

);
