%% Clear everything
clear;
close;

%% Set defaults Vars
savealldata=false;
savesinglechunk=false;
savemultwind=false;

sampleRate = 1000e6;
sampleRateDAC = 9e9;
adcDualChanMode = 1;
fullScaleMilliVolts =1000;
trigSource = 1; % 1 = external-trigger
dacChanInd = 1; % 1 = chan 1 and 2 = chan 2
adcChanInd = 0; % ADC Channel 1
measurementTimeSeconds = 7; %Integer
%delay = 0.0000178; % dead time
%delay = 0.0000348; % dead time
%delay=0.00000148;
%delay = 0.0000108; % dead time
%delay = 0.0000028; % dead time
delay = 0.0000038; % dead time

off = 0;
on = 1;


%% Load TEPAdmin.dll which is a .Net Assembly
% The TEPAdmin.dll is installed by WDS Setup in C:\Windows\System32

% Currently the tested DLL is installed in the following path
asm = NET.addAssembly('C:\Windows\System32\TEPAdmin.dll');

import TaborElec.Proteus.CLI.*
import TaborElec.Proteus.CLI.Admin.*
%% Create Administrator
% Create instance of the CProteusAdmin class, and open it.
% Note that only a single CProteusAdmin instance can be open,
% and it must be kept open till the end of the session.

admin = CProteusAdmin(@OnLoggerEvent);

rc = admin.Open();
assert(rc == 0);

%% Use the administrator, and close it at the end
try
    slotIds = admin.GetSlotIds();
    numSlots = length(slotIds);
    assert(numSlots > 0);
    
    connect = 1;
    % If there are multiple slots, let the user select one ..
    sId = slotIds(2);
    if numSlots > 1
        fprintf(1, '\n%d slots were found\n', numSlots);
        for n = 1:numSlots
            sId = slotIds(n);
            slotInfo = admin.GetSlotInfo(sId);
            if ~slotInfo.IsSlotInUse
                modelName = slotInfo.ModelName;
                if slotInfo.IsDummySlot
                    fprintf(1, ' * Slot Number: Model %s [Dummy Slot].\n', sId, ModelName);
                else
                    fprintf(1, ' * Slot Number: Model %s.\n', sId, ModelName);
                end
            end
        end
        choice = input('Enter SlotId ');
        fprintf(1, '\n');
        sId = uint32(choice);
    end
    
     sId = 8;
    
    % Connect to the selected instrument ..
    should_reset = false;
    inst = admin.OpenInstrument(sId);
    instId = inst.InstrId;
    
%     In other code...
%     % Connect to the selected instrument ..
%     should_reset = true;
%     inst = admin.OpenInstrument(sId, should_reset);
%     instId = inst.InstrId;
    
    % ---------------------------------------------------------------------
    % Setup instrument
    % ---------------------------------------------------------------------
    
    res = inst.SendScpi('*IDN?');
    assert(res.ErrCode == 0);
    fprintf(1, '\nConnected to ''%s''\n', netStrToStr(res.RespStr));
    
    pause(0.01);
    
    res = inst.SendScpi('*CLS'); % clear
    assert(res.ErrCode == 0);
    
    res = inst.SendScpi('*RST'); % reset
    assert(res.ErrCode == 0);
    
%     sampleRateDAC = 9e9;
%     sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
%     res = inst.SendScpi(sampleRateDAC_str); % set sample clock
%     assert(res.ErrCode == 0);
    
    fprintf('Reset complete\n');
    
    % ---------------------------------------------------------------------
    % ADC Config
    % ---------------------------------------------------------------------
    
    rc = inst.SetAdcDualChanMode(1); %set to dual frame granularity = 48
    assert(rc == 0);
    
    rc = inst.SetAdcSamplingRate(sampleRate);
    assert(rc == 0);
    
    rc = inst.SetAdcFullScaleMilliVolts(0,fullScaleMilliVolts);
    assert(rc == 0);
    
    fprintf('ADC Configured\n');
    %% 
        % 6 - Program MW chirp waveform
        % 7 - Play MW chirp waveform
            
%             case 6 % Program MW chirp waveform
              
                % ---------------------------------------------------------------------
                % Download chirp waveform of 1024 points to segment 1 of channel 1
                % ---------------------------------------------------------------------
%                 
%                 awg_center_freq = 3.775e9;
%                 awg_bw_freq = 24e6;
%                 awg_amp = 1.2;
%                 sweep_freq = 750;
%                 sweep_sigma = 1;
%                 symm = 1;
%                 srs_freq = 3.4e9; % should be 3.4e9
%                 srs_amp = 3;
%                 
%                 res = inst.SendScpi(['INST:CHAN ' num2str(dacChanInd)]); % select channel 2
%                 assert(res.ErrCode == 0);
%                 
%                 bits = 8;
%                 
%                 rampTime = 1/sweep_freq;
%                 fCenter = awg_center_freq - srs_freq;
%                 fStart = fCenter - 0.5*awg_bw_freq;
%                 fStop = fCenter + 0.5*awg_bw_freq;
%                 dt = 1/sampleRateDAC;
%                 dacSignal = makeChirp(sampleRateDAC, rampTime, dt, fStart, fStop, bits);   
%                 fprintf('waveform length - ');
%                 fprintf(num2str(length(dacSignal)));
%                 fprintf('\n') ;
%                 
%                 % Define segment 1 
%                 res = inst.SendScpi(strcat(':TRAC:DEF 1,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
%                 assert(res.ErrCode == 0);
%                 
%                 % select segmen 1 as the the programmable segment
%                 res = inst.SendScpi(':TRAC:SEL 1');
%                 assert(res.ErrCode == 0); 
%                 
%                 % Download the binary data to segment 1
%                 res = inst.WriteBinaryData(':TRAC:DATA 0,#', dacSignal);
%                 assert(res.ErrCode == 0);
%                 
%                 srs_freq_str = [':SOUR:CFR ' sprintf('%0.2e', srs_freq)];
%                 res = inst.SendScpi(srs_freq_str);
%                 assert(res.ErrCode == 0);
%                 
%                 res = inst.SendScpi(':SOUR:MODE DUC'); % IQ MODULATOR --
% %                 THINK OF A MIXER, BUT DIGITAL
%                 assert(res.ErrCode == 0);
%                 
%                 try
%                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
%                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
%                 assert(res.ErrCode == 0);
%                 catch
%                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
%                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
%                 assert(res.ErrCode == 0);
%                 end
%                 
%                 % Define segment 2
%                 res = inst.SendScpi(strcat(':TRAC:DEF 2,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
%                 assert(res.ErrCode == 0);
%                 
%                 % select segmen 2 as the the programmable segment
%                 res = inst.SendScpi(':TRAC:SEL 2');
%                 assert(res.ErrCode == 0); 
%                 
%                 % Download the binary data to segment 2
%                 res = inst.WriteBinaryData(':TRAC:DATA 0,#', fliplr(dacSignal));
%                 assert(res.ErrCode == 0);
%                 
%                 srs_freq_str = [':SOUR:CFR ' sprintf('%0.2e', srs_freq)];
%                 res = inst.SendScpi(srs_freq_str);
%                 assert(res.ErrCode == 0);
%                 
%                 res = inst.SendScpi(':SOUR:MODE DUC'); % IQ MODULATOR --
% %                 THINK OF A MIXER, BUT DIGITAL
%                 assert(res.ErrCode == 0);
%                 
%                 try
%                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
%                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
%                 assert(res.ErrCode == 0);
%                 catch
%                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
%                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
%                 assert(res.ErrCode == 0);
%                 end
%                 
%                 segLen = 40960;
%                 segLenDC = 50048;
%                 cycles = 800;
                
%                 dacSignalMod = sine(cycles, 0, segLen, bits); % sclk, cycles, phase, segLen, amp, bits, onTime(%)
%                 
%                 dacSignalDC = [];
%                 for i = 1 : segLenDC
%                   dacSignalDC(i) = 127;
%                 end
%                 
%                 dacSignal = [dacSignalMod dacSignalDC];
                
%             case 7 % Play MW chirp waveform
                
                % ---------------------------------------------------------------------
                % Play segment 1 in channel 1
                % ---------------------------------------------------------------------
            
%                 res = inst.SendScpi(['INST:CHAN ' num2str(dacChanInd)]); % select channel 2
%                 assert(res.ErrCode == 0);
%                 
%                 res = inst.SendScpi(':SOUR:FUNC:MODE:SEG 1');
%                 assert(res.ErrCode == 0);
%                 
%                 amp_str = [':SOUR:VOLT ' sprintf('%0.2f', awg_amp)];
%                 res = inst.SendScpi(amp_str);
%                 assert(res.ErrCode == 0);
%                 
%                 res = inst.SendScpi(':OUTP ON');
%                 assert(res.ErrCode == 0);
%                 
%                 fprintf('Waveform generated and playing\n');
                
%             case 8
%                 
%                 % Disable MW chirp output
%                 res = inst.SendScpi(':OUTP OFF');
%                 assert(res.ErrCode == 0);
%                 
%                 fprintf('MW Chirp Waveform stopped playing (on purpose)\n');
%                 
%             case 9
%                 
%                 % ---------------------------------------------------------------------
%                 % Play segment 2 in channel 1
%                 % ---------------------------------------------------------------------
%                 
% %                 res = inst.SendScpi(['INST:CHAN ' num2str(dacChanInd)]); % select channel 2
% %                 assert(res.ErrCode == 0);
%                 
%                 res = inst.SendScpi(':SOUR:FUNC:MODE:SEG 2');
%                 assert(res.ErrCode == 0);
%                 
% %                 amp_str = [':SOUR:VOLT ' sprintf('%0.2f', awg_amp)];
% %                 res = inst.SendScpi(amp_str);
% %                 assert(res.ErrCode == 0);
%                 
% %                 res = inst.SendScpi(':OUTP ON');
% %                 assert(res.ErrCode == 0);
%                 
%                 fprintf('Waveform in Segment 2 playing\n');
        
    
%     res = inst.SendScpi(':SYST:ERR?');
%     fprintf(1, '\nEnd - server stopped!! \nInstrument Error Status = %s\n', netStrToStr(res.RespStr));
%     
%     % It is recommended to disconnect from instrumet at the end
%     rc = admin.CloseInstrument(instId);
%     
%     % Close the administrator at the end ...
%     admin.Close();
catch ME
    admin.Close();
    rethrow(ME)
end

% Function netStrToStr
function str = netStrToStr(netStr)
    try
        str = convertCharsToStrings(char(netStr));
    catch
        str = '';
    end
end

%% Function - On Logger-Event
function OnLoggerEvent(~, e)
    try
        % print only:
        % TaborElec.Proteus.CLI.LogLevel.Critical (1)
        % TaborElec.Proteus.CLI.LogLevel.Error    (2)
        % TaborElec.Proteus.CLI.LogLevel.Warning  (3)
        if int32(e.Level) >= 1 &&  int32(e.Level) <= 3
            msg = netStrToStr(e.Message);
            if strlength(msg) > 0
                fprintf(2, '\n ~ %s\n', msg(1));
            end
        end
        System.Diagnostics.Trace.WriteLine(e.Message);
    catch ME
        rethrow(ME)
    end
end

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
