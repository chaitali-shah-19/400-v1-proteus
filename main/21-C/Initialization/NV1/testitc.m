 % Find a serial port object.
  obj1 = instrfind('Type', 'serial', 'Port', 'COM7', 'Tag', '');
% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = serial('COM7');
else
    fclose(obj1);
    obj1 = obj1(1)
end
% Disconnect from instrument object, obj1.
fclose(obj1);
% Connect to instrument object, obj1.
fopen(obj1);
%%
handles.obj1 = instrfind('Type', 'serial', 'Port', 'COM7', 'Tag', '');
if isempty(handles.obj1)
    handles.obj1 = serial('COM7');
else
    fclose(handles.obj1);
    handles.obj1 = handles.obj1(1)
end
% Connect to instrument object, obj1.
fopen(handles.obj1);

status1 = query(handles.obj1, 'READ:SYS:CAT?');
set(handles.text2, 'String', status1) 
ReadTemp = query(handles.obj1, 'READ:DEV:MB1.T1:TEMP:SIG:TEMP?');
set(handles.text5, 'String', ReadTemp(31:end))