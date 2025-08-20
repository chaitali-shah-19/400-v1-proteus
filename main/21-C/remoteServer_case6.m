     
%             case 6 % Program MW chirp waveform
                
                % ---------------------------------------------------------------------
                % Download chirp waveform of 1024 points to segment 1 of channel 1
                % ---------------------------------------------------------------------
                
                awg_center_freq = 3.775e9;
                awg_bw_freq = 24e6;
                awg_amp = 1.2;
                sweep_freq = 750;
                sweep_sigma = 1;
                symm = 1;
                srs_freq = 3.4e9; % should be 3.4e9
                srs_amp = 3;
                
                res = inst.SendScpi(['INST:CHAN ' num2str(dacChanInd)]); % select channel 2
                assert(res.ErrCode == 0);
                
                bits = 8;
                
                rampTime = 1/sweep_freq;
                fCenter = awg_center_freq - srs_freq;
                fStart = fCenter - 0.5*awg_bw_freq;
                fStop = fCenter + 0.5*awg_bw_freq;
                dt = 1/sampleRateDAC;
                dacSignal = makeChirp(sampleRateDAC, rampTime, dt, fStart, fStop, bits);   
                fprintf('waveform length - ');
                fprintf(num2str(length(dacSignal)));
                fprintf('\n') ;
                
                % Define segment 1 
                res = inst.SendScpi(strcat(':TRAC:DEF 1,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
                assert(res.ErrCode == 0);
                
                % select segmen 1 as the the programmable segment
                res = inst.SendScpi(':TRAC:SEL 1');
                assert(res.ErrCode == 0); 
                
                % Download the binary data to segment 1
                res = inst.WriteBinaryData(':TRAC:DATA 0,#', dacSignal);
                assert(res.ErrCode == 0);
                
                srs_freq_str = [':SOUR:CFR ' sprintf('%0.2e', srs_freq)];
                res = inst.SendScpi(srs_freq_str);
                assert(res.ErrCode == 0);
                
                res = inst.SendScpi(':SOUR:MODE DUC'); % IQ MODULATOR --
%                 THINK OF A MIXER, BUT DIGITAL
                assert(res.ErrCode == 0);
                
                try
                sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                assert(res.ErrCode == 0);
                catch
                sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                assert(res.ErrCode == 0);
                end
                
                % Define segment 2
                res = inst.SendScpi(strcat(':TRAC:DEF 2,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
                assert(res.ErrCode == 0);
                
                % select segmen 2 as the the programmable segment
                res = inst.SendScpi(':TRAC:SEL 2');
                assert(res.ErrCode == 0); 
                
                % Download the binary data to segment 2
                res = inst.WriteBinaryData(':TRAC:DATA 0,#', fliplr(dacSignal));
                assert(res.ErrCode == 0);
                
                srs_freq_str = [':SOUR:CFR ' sprintf('%0.2e', srs_freq)];
                res = inst.SendScpi(srs_freq_str);
                assert(res.ErrCode == 0);
                
                res = inst.SendScpi(':SOUR:MODE DUC'); % IQ MODULATOR --
%                 THINK OF A MIXER, BUT DIGITAL
                assert(res.ErrCode == 0);
                
                try
                sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                assert(res.ErrCode == 0);
                catch
                sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                assert(res.ErrCode == 0);
                end
                
                segLen = 40960;
                segLenDC = 50048;
                cycles = 800;
                
%                 dacSignalMod = sine(cycles, 0, segLen, bits); % sclk, cycles, phase, segLen, amp, bits, onTime(%)
%                 
%                 dacSignalDC = [];
%                 for i = 1 : segLenDC
%                   dacSignalDC(i) = 127;
%                 end
%                 
%                 dacSignal = [dacSignalMod dacSignalDC];

% trig setup
    res = inst.SendScpi(':INIT:CONT OFF'); % turn off continuous mode
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:SOUR:ENAB TRG2');
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:SOUR:DIS TRG2');
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:SEL TRG2');
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:STAT ON');
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:SLOP POS');
    assert(res.ErrCode == 0);
    
    trig1Thresh = 0.5;
    trig1Thresh_str = [':TRIG:LEV ' sprintf('%0.2e', trig1Thresh)];
    res = inst.SendScpi(trig1Thresh_str); % set trig level in volts
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi(':TRIG:COUN 0');% loop counter, 0 means loop forever
    assert(res.ErrCode == 0);
    
            res = inst.SendScpi(':INST:CHAN 1'); % select channel 1
            assert(res.ErrCode == 0);

%% Signal Processing Functions

%Create a sine wave
function sine = sine(cycles, phase, segLen, bits)
   
  verticalScale = ((2^bits))-1; % 2584 16 bits , 9082 8 bits
  time = -(segLen-1)/2:(segLen-1)/2;
  omega = 2 * pi() * cycles;
  rawSignal = sin(omega*time/segLen); 
  %rawSine = amp* cos(omega*time/segLen); 
 
  sine = ampScale(bits, rawSignal);
  
  %plot(sine);
  
end

function sine = addSinePulse(segment, starttime, dt, pulseDuration, freq, phase, bits)            
    rawSignal = segment;
    npoints = length(segment);
    starttimeIdx = roundCheck(starttime, dt)+1;
    durationPts = roundCheck(pulseDuration, dt);

    if starttimeIdx > 0 && starttimeIdx + durationPts <= npoints
        rawSignal(starttimeIdx:starttimeIdx+durationPts) = sin(2*pi*freq*dt*(0:durationPts) + 2*pi*freq*starttime + phase);
        sine = ampScale(bits, rawSignal);
    else
        error('Pulse out of bounds');
    end
end

function dacWav = makeChirp(sampleRateDAC, rampTime, dt, fStart, fStop, bits)            

    t = 0:1/sampleRateDAC:rampTime;
    dacWave = chirp(t,fStart,rampTime,fStop);
    seglenTrunk = (floor(length(dacWave)/ 64))*64;
    dacWave = dacWave(1:seglenTrunk);
    dacWav = ampScale(bits, dacWave);

end

% Scale to FSD
function dacSignal = ampScale(bits, rawSignal)
 
  maxSig = max(rawSignal);
  verticalScale = ((2^bits)/2)-1;

  vertScaled = (rawSignal / maxSig) * verticalScale;
  dacSignal = uint8(vertScaled + verticalScale);
  %plot(dacSignal);

%   if bits > 8
%       dacSignal16 = [];
%       sigLen = length(dacSignal);
%       k=1;
%       for j = 1:2:sigLen*2;
%         dacSignal16(j) = bitand(dacSignal(k), 255);
%         dacSignal16(j+1) = bitshift(dacSignal(k),-8);
%         k = k + 1;
%       end
%       dacSignal = dacSignal16;
%   end
end

function rNb = roundCheck(nb, units)
    global debug
    rNb = round(nb/units);
    if ~isempty(debug) && debug > 1 && abs(rNb*units - nb) > units/100
       disp([inputname(1) ' = ' num2str(nb/units) ' rounded to ' num2str(rNb)]);
    end
end