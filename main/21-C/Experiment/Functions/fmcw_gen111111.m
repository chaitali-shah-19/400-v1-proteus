% EXAMPLE FOR DIRECT MODE
%===================================================
% This example calculates up to 4 different signals and download them into
% each available channel in the target Proteus device.
% 
% The basic waveform is an square waveform using the full DAC range and it
% is downloaded to channel #1. For each channel, the waveform is calculated
% by integration of the previous waveform in a similar way to some analog
% signal generators, where the triangular wave is obtained by integration
% of an square wave, and the sinusoidal waveform is obtained by integration
% of the triangular wave. Channel #4, when available, will generate a
% "cosine" wave obatined by integration of the sinewave assigned to channel
% #3.

%clc;

sampleRateDAC = 9000e6;
sampleRate = 1000e6;%1000e6
adcDualChanMode = 1;
fullScaleMilliVolts =1000;
%trigSource = 1; % 1 = external-trigger
adcChanInd = 0; % ADC Channel 1
measurementTimeSeconds = 7; %Integer
delay = 0.0000173; % dead time

fprintf(1, 'INITIALIZING SETTINGS\n');

%% Load TEPAdmin.dll which is a .Net Assembly
% The TEPAdmin.dll is installed by WDS Setup in C:\Windows\System32 

% Currently the tested DLL is installed in the following path
asm = NET.addAssembly('C:\Windows\System32\TEPAdmin.dll');

import TaborElec.Proteus.CLI.*
import TaborElec.Proteus.CLI.Admin.*
%%
admin = CProteusAdmin(@OnLoggerEvent);
rc = admin.Open();
assert(rc == 0);

%% Use the administrator, and close it at the end
try
    slotIds = admin.GetSlotIds();
    numSlots = length(slotIds);
    assert(numSlots > 0);
    
    
    % If there are multiple slots, let the user select one ..
    sId = slotIds(8);
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
   
    % Connect to the selected instrument ..

    should_reset = true;
    inst = admin.OpenInstrument(sId,should_reset);%, should_reset
    instId = inst.InstrId;
 
    % ---------------------------------------------------------------------
    % Send SCPI commands
    % ---------------------------------------------------------------------
    
    res = inst.SendScpi('*IDN?');
    assert(res.ErrCode == 0);
    fprintf(1, '\nConnected to ''%s''\n', netStrToStr(res.RespStr));

    pause (0.01)
    
    % Reset AWG
    rc = inst.SendScpi('*CLS');
    assert(rc.ErrCode == 0);
    
    rc = inst.SendScpi('*RST');
    assert(rc.ErrCode == 0);
  
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
    
    
    fprintf(1, 'Calculating WAVEFORMS\n');
    
    % SETTING AWG
    fprintf(1, 'SETTING AWG\n');
    
    % Set sampling rate for AWG to maximum.
    inst.SendScpi([':FREQ:RAST ' num2str(sampleRate)]);
    %inst.SendCmd(':TRAC:FORM U8');
    
    % Get the default DAC resolution for the current settings.
   % dacRes = inst.getDacResolution();
    %fprintf('\nDAC resolution: %d\n', dacRes);
    
    inst.SendScpi(':TRAC:DEL:ALL');
    
    awg_center_freq = 3.25e9; %in hz
    awg_bw_freq = 10000000;
    awg_amp = 1.2;
    sweep_freq = 75;
    sweep_sigma = 1;
    symm = 0;
    srs_freq = 2.875E9; % should be 3.4e9
    srs_amp = 3;
    
    bits = 8;
    segment = 1;
    segLen = 40960;
    cycles = 800;

    rampTime = 1/sweep_freq;
    fCenter = awg_center_freq - srs_freq;
    fStart = (fCenter*1) - 0.5*awg_bw_freq;
    fStop = (fCenter*1) + 0.5*awg_bw_freq;
    dt = 1/sampleRate;
    dacSignal = makeChirp(sampleRate, rampTime, dt, fStart, fStop, bits);
    plot(dacSignal)
    
    inst.SendScpi('INST:CHAN 1'); % select channel 1
    
    % Define segment 1
    inst.SendScpi(strcat(':TRAC:DEF 1,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
    
    % select segmen 1 as the the programmable segment
    inst.SendScpi(':TRAC:SEL 1');
    
    % Download the binary data to segment 1
    
   % prefix = ':TRAC:DATA 0,';
    
   % if dacRes == 16
    %    inst.SendBinaryData(prefix, dacSignal, 'uint16');
    %else
     %   inst.SendBinaryData(prefix, dacSignal, 'uint8');
   % end
     res = inst.WriteBinaryData(':TRAC:DATA 0,#', dacSignal);
     assert(res.ErrCode == 0);
     
     srs_freq_str = [':CFR ' sprintf('%0.2e', srs_freq)];
     inst.SendScpi(srs_freq_str);

    inst.SendScpi(':SOUR:MODE IQM'); % IQ MODULATOR --
    % THINK OF A MIXER, BUT DIGITAL 
 % why DUC vs IQM???
    
    %set sample rate 
    inst.SendScpi([':FREQ:RAST ' num2str(sampleRate)]);
    
    fprintf(1, 'SETTING AWG OUTPUT\n');
    res = inst.SendScpi(sprintf(':FUNC:MODE:SEGM %d', segment));
    assert(res.ErrCode == 0);

    % Output volatge set to MAX
    inst.SendScpi(':SOUR:VOLT MAX');
    % Activate outpurt and start generation
    res = inst.SendScpi(':OUTP ON');
    assert(res.ErrCode == 0);

    fprintf('Waveform generated and playing\n');

%     %% Disable MW chirp output
    % inst.SendScpi(':OUTP OFF');
     % fprintf(1,'MW Chirp Waveform stopped playing (on purpose)\n');
%     
%     % It is recommended to disconnect from instrument at the end
     % inst.Disconnect();
      %clear inst;
      %clear;
      %fprintf(1, 'END\n');

end
%% Signall Processing Functions

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

% Sacle to FSD

function dacSignal = ampScale(bits, rawSignal)
 
  maxSig = max(rawSignal);
  verticalScale = ((2^bits)/2)-1;

  vertScaled = (rawSignal / maxSig) * verticalScale;
  dacSignal = uint8(vertScaled + verticalScale);
  %plot(dacSignal);

  if bits > 8
      dacSignal16 = [];
      sigLen = length(dacSignal);
      k=1;
      for j = 1:2:sigLen*2;
        dacSignal16(j) = bitand(dacSignal(k), 255);
        dacSignal16(j+1) = bitshift(dacSignal(k),-8);
        k = k + 1;
      end
      dacSignal = dacSignal16;
  end
end

function dacWav = makeChirp(sampleRateDAC, rampTime, dt, fStart, fStop, bits)            

    t = 0:1/(sampleRateDAC):rampTime;
    dacWave = chirp(t,fStart,rampTime,fStop);
    seglenTrunk = (floor(length(dacWave)/ 64))*64;
    dacWave = dacWave(1:seglenTrunk);
    dacWav = ampScale(bits, dacWave);

end

% Function netStrToStr
function str = netStrToStr(netStr)
    try
        str = convertCharsToStrings(char(netStr));
    catch
        str = '';
    end
end
