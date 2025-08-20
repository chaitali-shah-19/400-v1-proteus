%% Initializing AWG Receiving & Digitizing Functionality
clear;clc;
fprintf(1, 'INITIALIZING SETTINGS\n');

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
    sId = 8;%change
    % Connect to the selected instrument ..
    should_reset = true;
    inst = admin.OpenInstrument(sId, should_reset);
    instId = inst.InstrId;

catch ME
    admin.Close();
    rethrow(ME) 
end
   

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
numberOfPulses = 1;
capture_first = 1;
capture_count = numberOfPulses;
loops = 1;
tacq = 200; % acquisition time as in pulse sequence
%readLen = round2((tacq+2)*1e-6/1e-9,96)-96; % must be divisible by 96,
%**NEW**
readLen = (tacq+4)*2^(-20)/(2^(-30))-96; % must be divisible by 96,
netArray = NET.createArray('System.UInt16', readLen*numberOfPulses); %total array -- all memory needed
%number of points in a given small chunk

% Setup the digitizer 

res = inst.SendScpi(':DIG:MODE DUAL');

%this is the line printing the DIG:FREQ, is it necessary?
fprintf(strcat([':DIG:FREQ ',num2str(sampleRate), '\n']));
cmd = [':DIG:FREQ ' num2str(sampleRate)];
res = inst.SendScpi(cmd);

cmd = ':DIG:FREQ?';
res = inst.SendScpi(cmd);
fprintf(netStrToStr(res.RespStr));

% Enable capturing data from channel 1
res = inst.SendScpi(':DIG:CHAN:SEL 1');
res = inst.SendScpi(':DIG:CHAN:STATE ENAB');
% Select internal or external as start-capturing trigger:
%res = inst.SendScpi(':DIG:TRIG:SOURCE CPU');
res = inst.SendScpi(':DIG:TRIG:SOURCE EXT');

%ND copy/pasted in 5/3/22 from ExpFxns
    res = inst.SendScpi(':DIG:TRIG:TYPE EDGE');
    assert(res.ErrCode == 0);

    %Set trigger to falling edge
    res = inst.SendScpi(':DIG:TRIG:SLOP NEG');
    assert(res.ErrCode == 0);

    %Set trigger threshold to 0.3 V
    %Check that LEV1 vs LEV2 is correct and
    %that 0.3 is pos/neg
    res = inst.SendScpi('DIG:TRIG:LEV1 0.3');
    assert(res.ErrCode == 0);
    
    %Set external trigger delay
    %Is this the right command to do this?
    %res = inst.SendScpi('DIG:TRIG:DEL:EXT 0.5e-06');
    %assert(res.ErrCode == 0);
                                 
cmd = [':DIG:ACQuire:FRAM:DEF ' num2str(numberOfPulses) ',' num2str(readLen)];
res = inst.SendScpi(cmd);

% Select the frames for the capturing 
% (all the four frames in this example)
cmd = [':DIG:ACQuire:FRAM:CAPT ' num2str(capture_first) ',' num2str(numberOfPulses)];
res = inst.SendScpi(cmd);

% Clean memory **NEW**
res = inst.SendScpi(':DIG:ACQ:ZERO:ALL');

%res = inst.SendScpi(':DIG:CHAN:SEL 1');

%**NEW** INIT OFF,ON Order
% Close instrument in case improperly closed from prior run
res = inst.SendScpi(':DIG:INIT OFF');
% Start the digitizer's capturing machine
res = inst.SendScpi(':DIG:INIT ON');

%**NEW**
rTrg=0;
while rTrg < numberOfPulses
  %res = inst.SendScpi(':DIG:TRIG:IMM');
  res = inst.SendScpi(":DIG:ACQuire:FRAM:STATus?");
  assert(res.ErrCode == 0);
  respFields= split(convertCharsToStrings(char((res.RespStr))),','); 
  fprintf(1, '\nADC Status  ''%s''\n', convertCharsToStrings(char(res.RespStr)));
  paramlen= size(respFields)
  if paramlen(1) >=4 
      rTrg = str2num(respFields(4)); %the 4th element of respFields is numberOfPulses
  end
end

res = inst.SendScpi(':DIG:INIT OFF');

res = inst.SendScpi('*OPC?');

% Choose which frames to read (all in this example)
res = inst.SendScpi(':DIG:DATA:SEL ALL');

% Choose what to read 
% (only the frame-data without the header in this example)
res = inst.SendScpi(':DIG:DATA:TYPE FRAM');

% Get the total data size (in bytes)
res = inst.SendScpi(':DIG:DATA:SIZE?');
fprintf(netStrToStr(res.RespStr));
%num_bytes = uint32(str2num(netStrToStr(res.RespStr)));
%num_bytes = uint32(str2num(char(res.RespStr)));
% 
% Read the data that was captured by channel 1:
inst.SendScpi(':DIG:CHAN:SEL 1');
%wavlen = floor(num_bytes / 2);
rc = inst.ReadMultipleAdcFrames(adcChanInd, capture_first, numberOfPulses, netArray); %this is where the device reads
assert(rc == 0);
samples = double(netArray); %get the data

%new signal processing and digital filter code from Ashok
figure(1);clf;plot(samples);

points=1:size(samples,2);
figure(100);clf;plot(points(1:1000),samples(1:1000),'b-');hold on;
A=2040+200*cos(2*pi*(1/50).*points);
plot(points(1:500),A(1:500),'r-');
M=(A-mean(A)).*(samples-mean(samples));
figure(101);clf;plot(M-2040);

Y = fft(M-2040);L=length(Y);
P2 = (Y);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
Fs=1e9;
f = Fs*(0:(L/2))/L;
figure(102);clf;plot(f,abs(P1));set(gca,'xlim',[0, 40e6]);

[v,b]=min(abs(f-2e6));

Y2=P1;Y2(1,b:L/2)=0;
figure(102);clf;plot(f,abs(Y2));set(gca,'xlim',[0, 40e6]);
X2=ifft(Y2);
Fs_time=1e-9;L2=length(Y2);
f_time = Fs_time*(0:L2-1);
figure(103);clf;plot(f_time,real(X2),'r-');

%res = inst.SendScpi(':DIG:ACQ:ZERO:ALL 0');
assert(res.ErrCode == 0);

% It is recommended to disconnect from instrument at the end
rc = admin.CloseInstrument(instId);
assert(rc==0);
fprintf('Instrument closed\n');

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