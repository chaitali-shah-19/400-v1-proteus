clear;
%% CLOSE ALL OPEN PORTS
serialObj = instrfind;
s=size(serialObj);
for i=1:s(1,2)
fclose(serialObj(i));
delete(serialObj(i));
end
%% Initialize Lakeshore
s = serial('com5');
set(s, 'Baudrate', 57600);
set(s, 'DataBits', 7);
set(s, 'Parity', 'odd');
%set(s, 'StartBits', 1);
set(s, 'StopBits', 1);
set(s, 'FlowControl', 'none');
fopen(s);

%% Initialize shuttler
com = actxserver('SPiiPlusCOM660.Channel.1');
com.OpenCommEthernetTCP('10.0.0.100', 701)
com.Enable(com.ACSC_AXIS_0);

%% Set velocity of shuttler
com.SetVelocity(com.ACSC_AXIS_0,1);
com.SetAcceleration(com.ACSC_AXIS_0,10);%mm/s2
com.SetDeceleration(com.ACSC_AXIS_0,10);
com.SetJerk(com.ACSC_AXIS_0,10);

% Move to start position
start_position=100;
com.ToPoint(com.ACSC_AMF_WAIT, com.ACSC_AXIS_0, -start_position); %MOVE
com.Go(com.ACSC_AXIS_0);
pause(30);

%% Move shuttler

for j=1:20
current_position=com.GetFPosition(com.ACSC_AXIS_0)
new_position=-(abs(current_position)+1);
com.ToPoint(com.ACSC_AMF_WAIT, com.ACSC_AXIS_0, new_position); %MOVE
com.Go(com.ACSC_AXIS_0);
pause(2);
val=lakeshoreReadOut(s) %readout Lakeshore
mag_array(j,1)=abs(current_position);
mag_array(j,2)=val;
end
% savemat(mag_array);
figure(1);
plot(mag_array(:,1),abs(mag_array(:,2)),'ob-');

%% Close lakeshore
fclose(s);

