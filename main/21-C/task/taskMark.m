%% Initializing AWG Receiving & Digitizing Functionality
clear;clc;

pfunc = ProteusFunctions;

fprintf(1, 'INITIALIZING SETTINGS\n');

insturment = "LAN" %PXI"

if (insturment == "PXI")

    dll_path = 'C:\Windows\System32\TEPAdmin.dll';
    asm = NET.addAssembly(dll_path);

    import TaborElec.Proteus.CLI.*
    import TaborElec.Proteus.CLI.Admin.*
    import System.*

    admin = CProteusAdmin(@OnLoggerEvent);
    rc = admin.Open();
    assert(rc == 0);

    try
        slotIds = admin.GetSlotIds();
        numSlots = length(size(slotIds));
        assert(numSlots > 0);
        sId = 4;
        % Connect to the selected instrument ..
        should_reset = true;
        inst = admin.OpenInstrument(sId, should_reset);
        instId = inst.InstrId;

    catch ME
        admin.Close();
        rethrow(ME) 
    end
    
else

    % Define IP Address for Target Proteus device descriptor
    % VISA "Socket-Based" TCP-IP Device. Socket# = 5025
    connStr = '192.168.0.42';
    paranoia_level = 0;

    % Connect to Instrument and get visa Handle
    % Using the TEProteusInst library
    inst = TEProteusInst(connStr, paranoia_level);
    res = inst.Connect();
    assert (res == true);
    
end

% Identify instrument using the standard IEEE-488.2 Command
%idnstr = inst.identifyModel();
%fprintf('\nConnected to: %s\n', idnstr);

% ---------------------------------------------------------------------
% Setup instrument
% --------------------------------------------------------------------

% SET UP AWG
fprintf(1, 'SETTING AWG\n');

awgSRate = 1E9;
awgChan = 1;

%Select Channel
inst.SendCmd(sprintf(':INST:CHAN %d', awgChan));
inst.SendCmd(':OUTP OFF');
inst.SendCmd(':FUNC:MODE ARB');
inst.SendCmd(':TRAC:DEL:ALL');
inst.SendCmd(':TASK:ZERO:ALL');

inst.SendCmd("*CLS; *RST");

inst.SendCmd([':FREQ:RAST ' num2str(awgSRate)]);
inst.SendCmd(":INIT:CONT ON");

cycles = 10;
phase = 0;
segLen = 2048;
bits = 8;
dacSignal1 = sine(cycles, phase, segLen, bits);

cycles = 5;
phase = 0;
segLen = 2048;
bits = 8;
dacSignal2 = sine(cycles, phase, segLen, bits);

segment = 1;
 % Define segment 1 
inst.SendCmd(sprintf(':TRAC:DEF %d, %d', segment, length(dacSignal1)));   


% select segmen 1 as the the programmable segment
inst.SendCmd(sprintf(':TRAC:SEL %d', segment));

% Download the binary data to segment   
prefix = ':TRAC:DATA 0,';

if bits == 16
    inst.SendBinaryData(prefix, dacSignal1, 'uint16');
else
    inst.SendBinaryData(prefix, dacSignal1, 'uint8');
end   

segment = 2;
 % Define segment 1 
inst.SendCmd(sprintf(':TRAC:DEF %d, %d', segment, length(dacSignal2)));   


% select segmen 1 as the the programmable segment
inst.SendCmd(sprintf(':TRAC:SEL %d', segment));

% Download the binary data to segment   
prefix = ':TRAC:DATA 0,';

if bits == 16
    inst.SendBinaryData(prefix, dacSignal2, 'uint16');
else
    inst.SendBinaryData(prefix, dacSignal2, 'uint8');
end 

% % Play seg 1
% res = inst.SendScpi(':SOUR:FUNC:MODE:SEG 1');
% assert(res.ErrCode == 0);

% trig settings for ARB mode
% inst.SendScpi(':TRIG:ACTIVE:SEL TRG1'); 
% inst.SendScpi(':TRIG:ACTIVE:STAT ON');
% inst.SendScpi(':TRIG:SOUR:ENAB TRG1');
% inst.SendScpi(':TRIG:SLOP POS');
% inst.SendScpi(':TRIG:LEV 0.5');
% inst.SendScpi(':TRIG:COUN 0');

% The Task Composer is configured to handle a certain number of task entries
inst.SendCmd(':TASK:COMP:LENG 1'); 

% inst.SendScpi(':TASK:COMP:SEL 1');
% inst.SendScpi(':TASK:COMP:SEGM 2'); 
% inst.SendScpi(':TASK:COMP:ENAB CPU');
% inst.SendScpi(':TASK:COMP:DTR ON');
% inst.SendScpi(':TASK:COMP:JUMP EVEN');
% inst.SendScpi(':TASK:COMP:NEXT1 2');

inst.SendCmd(':TASK:COMP:SEL 1');
inst.SendCmd(':TASK:COMP:SEGM 2'); 
%inst.SendScpi(':TASK:COMP:TYPE SING');
%inst.SendScpi(':TASK:COMP:LOOP 20');
inst.SendCmd(':TASK:COMP:ENAB TRG2');
%inst.SendScpi(':TASK:COMP:ABOR TRG1');
% inst.SendScpi(':TASK:COMP:DTR ON');
% inst.SendScpi(':TASK:COMP:DEST NEXT');
inst.SendCmd(':TASK:COMP:NEXT1 1');
%inst.SendScpi(':TASK:COMP:KEEP OFF');

% inst.SendScpi(':TASK:COMP:SEL 2');
% inst.SendScpi(':TASK:COMP:SEGM 2');
% inst.SendScpi(':TASK:COMP:TYPE SING');
% inst.SendScpi(':TASK:COMP:LOOP 20');
% inst.SendScpi(':TASK:COMP:ENAB TRG2');
% inst.SendScpi(':TASK:COMP:ABOR TRG1');
% inst.SendScpi(':TASK:COMP:DTR ON');
% inst.SendScpi(':TASK:COMP:JUMP IMM');
% inst.SendScpi(':TASK:COMP:DEST NEXT');
% inst.SendScpi(':TASK:COMP:NEXT1 1');
% inst.SendScpi(':TASK:COMP:KEEP OFF');

% write task table
% inst.SendScpi(':TASK:COMP:WRIT');
inst.SendCmd(':TASK:COMP:WRITE');
fprintf(1, 'SEQUENCE CREATED!\n');

fprintf(1, 'SETTING AWG OUTPUT\n');

inst.SendCmd(':SOUR:FUNC:MODE TASK');

% trig settings for ARB mode
inst.SendCmd(':TRIG:ACTIVE:SEL TRG2'); 
inst.SendCmd(':TRIG:ACTIVE:STAT ON');
% inst.SendScpi(':TRIG:SOUR:ENAB TRG1');
% inst.SendScpi(':TRIG:SLOP POS');
% inst.SendScpi(':TRIG:LEV 0.5');
% inst.SendScpi(':TRIG:COUN 0');


inst.SendCmd(':OUTP ON');

% % ---------------------------------------------------------------------
% % ADC Config
% % ---------------------------------------------------------------------
% 
% sampleRate = 1000e6;
% adcDualChanMode = 1;
% fullScaleMilliVolts =1000;
% adcChanInd = 0; % ADC Channel 1
% trigSource = 1; % 1 = external-trigger
% numberOfPulses = 10;
% capture_first = 1;
% capture_count = numberOfPulses;
% loops = 1;
% tacq = 32; % acquisition time as in pulse sequence
% readLen = round2((tacq+2)*1e-6/1e-9,96)-96; % must be divisible by 96,
% %netArray = NET.createArray('System.UInt16', readLen*numberOfPulses); %total array -- all memory needed
% %number of points in a given small chunk
% 
% % Setup the digitizer 
% res = inst.SendScpi(':DIG:MODE DUAL');
% 
% % Enable capturing data from channel 1
% res = inst.SendScpi(':DIG:CHAN:SEL 1');
% 
% cmd = [':DIG:FREQ ' num2str(sampleRate)];
% res = inst.SendScpi(cmd);
% 
% cmd = ':DIG:FREQ?';
% res = inst.SendScpi(cmd);
% fprintf(pfunc.netStrToStr(res.RespStr));
% 
% % Enable acquisition in the digitizer's channels  
% res = inst.SendScpi(':DIG:CHAN:STATE ENAB');
% 
% % Setup frames layout   
% cmd = [':DIG:ACQuire:FRAM:DEF ' num2str(numberOfPulses) ',' num2str(readLen)];
% res = inst.SendScpi(cmd);
% 
% % Select internal or external as start-capturing trigger:
% %res = inst.SendScpi(':DIG:TRIG:SOURCE CH1');
% res = inst.SendScpi(':DIG:TRIG:SOURCE TASK1');
% 
% res = inst.SendScpi(':DIG:CHAN:SEL 1');
% 
% % Select which frames are filled with captured data 
% %(all frames in this example)
% inst.SendScpi(':DIG:ACQ:FRAM:CAPT:ALL');
% 
% % Delete all wafm memory
% inst.SendScpi(':DIG:ACQ:ZERO:ALL');
% 
% resp = inst.SendScpi(':DIG:DATA:FORM?');
% resp = strtrim(pfunc.netStrToStr(resp.RespStr));
% 
% inst.SendScpi(':DIG:INIT OFF'); 
%     
% res = inst.SendScpi(':DIG:CHAN:SEL 1');
% 
% inst.SendScpi(':DIG:INIT ON');  
% 
% for n = 1:250
%     resp = inst.SendScpi(':DIG:ACQ:FRAM:STAT?');
%     resp = strtrim(pfunc.netStrToStr(resp.RespStr));
%     items = split(resp, ',');
%     items = str2double(items);
%     if length(items) >= 3 && items(2) == 1
%         break
%     end
%     if mod(n, 10) == 0                
%         fprintf('%d. %s Time:\n', fix(n / 10), resp);
% %                 toc                
%     end
%     pause(0.1);
% end
% res = inst.SendScpi(':DIG:INIT OFF');
% pause(1);
% 
% % After this point aquisition is complete, next stage is to readout data
% 
% % Define what we want to read(frames data, frame-header, or both).
% res = inst.SendScpi(':DIG:DATA:TYPE FRAM');
% 
% % Choose which frames to read (all in this example)
% res = inst.SendScpi(':DIG:DATA:SEL ALL');
% 
% % Read binary block
% resp = inst.SendScpi(':DIG:DATA:SIZE?');
% resp = strtrim(pfunc.netStrToStr(resp.RespStr));
% num_bytes = str2double(resp);
% % 
% % Read the data that was captured by channel 1:
% inst.SendScpi(':DIG:CHAN:SEL 1');
% 
% % because read format is UINT16 we divide byte number by 2
% wavlen = floor(num_bytes / 2);
% 
% % allocate NET array
% netArray = NET.createArray('System.UInt16', wavlen);
% % read the captured frame
% %tic
% res = inst.ReadMultipleAdcFrames(0, capture_first, numberOfPulses, netArray);
% %toc
% assert(res == 0);
% 
% % cast to matlab vector
% samples = uint16(netArray);
% 
% % deallocate the NET array
% delete(netArray);
% 
% plot(samples);
% 
% % res = inst.SendScpi(':DIG:ACQ:ZERO:ALL 0');

if (insturment == "PXI")
    % It is recommended to disconnect from instrument at the end
    rc = admin.CloseInstrument(instId);
    assert(rc==0);
    fprintf('Instrument closed\n');

    % Close the administrator at the end ..
    admin.Close();
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
  
  plot(sine);
  
end

% Scale to FSD
function dacSignal = ampScale(bits, rawSignal)
 
  maxSig = max(rawSignal);
  verticalScale = ((2^bits)/2)-1;

  vertScaled = (rawSignal / maxSig) * verticalScale;
  
  if bits > 8
    dacSignal = uint16(vertScaled + verticalScale);
  else
    dacSignal = uint8(vertScaled + verticalScale); 
  end
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