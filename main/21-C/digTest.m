%% Initializing AWG Receiving & Digitizing Functionality

fprintf(1, 'INITIALIZING SETTINGS\n');

% The TEPAdmin.dll is installed by WDS Setup in C:\Windows\System32

% Currently the tested DLL is installed in the following path
asm = NET.addAssembly('C:\Windows\System32\TEPAdmin.dll');

import TaborElec.Proteus.CLI.*
import TaborElec.Proteus.CLI.Admin.*

admin = CProteusAdmin(@OnLoggerEvent);
admin.Close();
rc = admin.Open();
assert(rc == 0);
%try
slotIds = admin.GetSlotIds();
numSlots = length(slotIds);
assert(numSlots > 0);

connect = 1;
% If there are multiple slots, let the user select one ..
sId = slotIds(1);
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

res = inst.SendScpi('*IDN?'); %asking for instrument IP address, model/serial #
assert(res.ErrCode == 0);
fprintf(1, '\nConnected to ''%s''\n', netStrToStr(res.RespStr));

% ---------------------------------------------------------------------
% ADC Config
% ---------------------------------------------------------------------

sampleRate = 1000e6;
adcDualChanMode = 1;
fullScaleMilliVolts =1000;
adcChanInd = 0; % ADC Channel 1
trigSource = 1; % 1 = external-trigger
numberOfPulses = 3;
loops = 1;
tacq = 32; % acquisition time as in pulse sequence
readLen = round2((tacq+2)*1e-6/1e-9,96)-96; % must be divisible by 96, 
    %number of samples in a given acquisition window

rc = inst.SetAdcDualChanMode(adcDualChanMode); %set to dual frame granularity = 48
assert(rc == 0);

rc = inst.SetAdcSamplingRate(sampleRate);
assert(rc == 0);

rc = inst.SetAdcFullScaleMilliVolts(adcChanInd,fullScaleMilliVolts);
assert(rc == 0);

rc = inst.SetAdcCaptureTrigSource(adcChanInd, trigSource);
assert(rc == 0);

rc = inst.SetAdcExternTrigPattern(0);
assert(rc==0)

rc = inst.SetAdcExternTrigGateModeEn(1);
assert(rc==0);

rc = inst.SetAdcExternTrigPolarity(1);
assert(rc==0);

rc = inst.SetAdcExternTrigThresh(adcChanInd,0.3); % AWG will record anything above 0.3V
assert(rc==0);

fprintf('ADC Configured\n');

rc = inst.SetAdcExternTrigDelay(4.1e-6); % 300 value is 4.1e-6
assert(rc==0);

rc = inst.SetAdcAcquisitionEn(1,0);
assert(rc == 0);

fprintf('Instrument setup complete and ready to aquire\n');

netArray = NET.createArray('System.UInt16', readLen*numberOfPulses); %total array -- all memory needed

for c = 1 : readLen*numberOfPulses
    netArray(c) = 1;
end

rc = inst.SetAdcAcquisitionEn(1,0);
assert(rc == 0);

rc = inst.SetAdcFramesLayout(numberOfPulses*loops, readLen); %set memory of the AWG
assert(rc == 0);

fprintf('Waiting for TRX Switch Trig\n');
rc = inst.SetAdcCaptureEnable(1);
assert(rc == 0);

% Measure

% Wait to see if AWG is ready to start capturing (?)
status = inst.ReadAdcCaptureStatus();
for i = 1 : 250
    if status ~= 0
        break;
    end
    pause(0.01);
    status = inst.ReadAdcCaptureStatus();
end

rc = inst.SetAdcCaptureEnable(1);
assert(rc == 0);

rc = inst.ReadAdcCaptureStatus();
 
% disp('Press a key !')    
% pause; 

fprintf('Transfering aquired data to computer....\n')

for n = 1:loops
    fprintf('Start Read %d .... ', n);
    firstIndex = ((n-1)*numberOfPulses)+1;
    tic
    rc = inst.ReadMultipleAdcFrames(adcChanInd, firstIndex, numberOfPulses, netArray); %this is where the device reads
    assert(rc == 0);
    samples = double(netArray); %get the data 
    fprintf('Read %d Complete\n', n);
    toc

    tic
    %delete mem
    fprintf('Clear mem %d .... ', n);
    rc =inst.WipeMultipleAdcFrames(adcChanInd, firstIndex, numberOfPulses, 0);
    assert(rc == 0);
    fprintf('Clear mem %d Complete\n', n);
    toc
    
    figure(1);clf;plot(samples);

end

rc = inst.SetAdcCaptureEnable(0);
assert(rc == 0);
% Free the memory space that was allocated for ADC capture
rc = inst.FreeAdcReservedSpace();
assert(rc == 0);

% It is recommended to disconnect from instrument at the end
rc = admin.CloseInstrument(instId);

% Close the administrator at the end ..
admin.Close();

% Function netStrToStr
function str = netStrToStr(netStr)
    try
        str = convertCharsToStrings(char(netStr));
    catch
        str = '';
    end
end

