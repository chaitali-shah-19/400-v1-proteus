classdef DAQNI_simu < handle
    % Matlab Object Class implementing control for National Instruments
    % Digital Acquistion Card
    
    properties
        LibraryName             % alias for library loaded
        LibraryFilePath         % path to nicaiu.dll on Windows
        HeaderFilePath          % path to NIDAQmx.h on Windows
        DigitalIOLines          % Digital Output Line Port Names
        DigitalIOStates         % Digital IO Line States
        AnalogOutLines          % Analog Out Lines
        AnalogOutVoltages       % Analog Output Voltages
        AnalogOutMinVoltage = -10;
        AnalogOutMaxVoltage = 10;
        AnalogInputVoltages     % Analog Input Voltages
        CounterOutLines         % Counter Output Lines
        CounterInLines          % Counter Input Lines (logical counter line, e.g. /Dev1/ctr0)
        CounterInLinesPhysical  % Counter Physical Input Lines (e.g. /Dev1/PFI0)
        TrigLines               % Trigger lines
        TrigLinePhysical
        TrigLineLogical
        AILineLogical
        TaskHandles = 0;        % Task Handles
        ClockLineLogical        % Clock Line (e.g. /Dev1/ctr1 )
        ClockLinePhysical       % Physical Clock Line (e.g. /Dev1/PFI7)
        ClockRate = 0;          % Clock Rate
        hasAborted = 0          %shouldnt be defined here
        SampleRate
        
        
        % replaced containers.Map data type with java.util.Hashtable for
        % 7.6 compatability
        %Tasks = containers.Map(); % Task Map Container (key/value pairs)
        Tasks = java.util.Hashtable;
        
        ReadTimeout = 10;       % Timeout for a read operation (sec)
        WriteTimeout = 10;      % Timeout for a write operation (sec)
        
        ErrorStrings = {};      % Strings from DAQmx Errors
        
        CounterOutSamples = 10000000000; % default value for implicit timing buffer size
        
    end
    properties (Constant, GetAccess = private)
        % constants for NI Board
        DAQmx_Val_Volts =  10348;
        DAQmx_Val_Rising = 10280; % Rising
        DAQmx_Val_Falling =10171; % Falling
        DAQmx_Val_CountUp =10128; % Count Up
        DAQmx_Val_CountDown =10124; % Count Down
        DAQmx_Val_ExtControlled =10326; % Externally Controlled
        DAQmx_Val_Hz = 10373; % Hz
        DAQmx_Val_Low =10214; % Low
        DAQmx_Val_ContSamps =10123; % Continuous Samples
        DAQmx_Val_GroupByChannel = 0;
        DAQmx_Val_Cfg_Default = int32(-1);
        DAQmx_Val_FiniteSamps =10178; % Finite Samples
        DAQmx_Val_Auto = -1;
        DAQmx_Val_WaitInfinitely = -1.0 %*** Value for the Timeout parameter of DAQmxWaitUntilTaskDone
        DAQmx_Val_Ticks =10304;
        DAQmx_Val_Seconds =10364;
        DAQmx_Val_ChanPerLine = 0;
        DAQmx_Val_SampClkPeriods = 10286; % Sample Clock Periods
        DAQmx_Val_Sawtooth = 14754;
        DAQmx_Val_Acquired_Into_Buffer = 1;
        DAQmx_Val_GroupByScanNumber = 1;
        
    end
    
    methods
        
        % instantiation function
        function obj = DAQNI_simu(obj)
           % obj.LibraryName = LibraryName;
            %obj.LibraryFilePath = LibraryFilePath;
            %obj.HeaderFilePath = HeaderFilePath;
            %obj.Initialize();
        end
        
        function [obj] = CheckErrorStatus(obj,ErrorCode)
            
            if ErrorCode == 0,
                Code = ErrorCode;
                ErrorString  = '';
                return;
            end
            
            % get the required buffer size
            BufferSize = 0;
           %[BufferSize] = calllib(obj.LibraryName,'DAQmxGetErrorString',ErrorCode,[],BufferSize);
           % create a string of spaces
           ErrorString = char(32*ones(1,BufferSize));
           % now get the actual string
          % [a,ErrorString] = calllib(obj.LibraryName,'DAQmxGetErrorString',ErrorCode,ErrorString,BufferSize);
           %warning(['DAQNI Error!! -- ',datestr(now),char(13),num2str(ErrorCode),'::',ErrorString]);
           obj.ErrorStrings{end+1} = ErrorString;
        end
        % adds a named line (e.g. Dev1/PFI1.0 )for digital IO to the driver object with
        % default State = 0 or 1
        function obj = addDIOLine(obj,Name,State)
            obj.DigitalIOLines{end+1} = Name;
            obj.DigitalIOStates(end+1) = State;
        end       
        % adds a named line (e.g. Dev1/ao0 ) for analog output with default
        % output Voltage value
        function obj = addAOLine(obj,Name,Voltage)
            obj.AnalogOutLines{end+1} = Name;
            obj.AnalogOutVoltages(end+1) = Voltage;
            
        end
        
        function obj = addClockLine(obj,Name,PhysicalName)
            obj.ClockLineLogical{end+1} = Name;
            obj.ClockLinePhysical{length(obj.ClockLineLogical)} = PhysicalName;
        end
        
        function obj = addAILine(obj,Name)
            obj.AILineLogical{end+1} = Name;
           
        end
        
         function  [power_data,std,array] = MonitorPower(obj)
 
       
        
        power_data = 5*rand;
        std = rand;
        array = rand(1,20);
        end
        
        
        
         function obj = addTrigLine(obj,Name,PhysicalName)
            obj.TrigLineLogical{end+1} = Name;
            obj.TrigLinePhysical{length(obj.ClockLineLogical)} = PhysicalName;
        end
        
        function obj = addCounterInLine(obj,Name,PhysicalName)
            
            obj.CounterInLines{end+1} = Name;
            % function updated 31 July 2009, jhodges
            % adds capability to adjust physical line
            obj.CounterInLinesPhysical{length(obj.CounterInLines)} = PhysicalName;
        end
        
        % initialization function upon instantiation
        % loads the ni .dll library and header
        function Initialize(obj)
            if  ~libisloaded(obj.LibraryName),
               % [pOk,warnings] = loadlibrary(obj.LibraryFilePath,obj.HeaderFilePath,'alias',obj.LibraryName);
            end
        end       
        
        function UpdateDigitalIO_All(obj)
            
            % iterate over the DigitalLines
            for k=1:length(obj.DigitalIOLines),
                Device = obj.DigitalIOLines{k};
                Value = obj.DigitalIOStates(k);
                WriteDigitalIO(obj,Device,Value);
            end
        end
        
        function WriteDigitalIO(obj,Device,Value)
            
                % create a task
                %[status,b,obj.TaskHandles] = ...
                  %  calllib(obj.LibraryName,'DAQmxCreateTask','NIDAQTask',obj.TaskHandles);
                
                    % Error Check
                    %obj.CheckErrorStatus(status);
                
                % designate a digital output channel with new task
                %[status,b,c] = calllib(obj.LibraryName,'DAQmxCreateDOChan',obj.TaskHandles,Device,'MyDO',0);
                
                    % Error Check
                 %   obj.CheckErrorStatus(status);

                % start the task
                %[status] = calllib(obj.LibraryName,'DAQmxStartTask',obj.TaskHandles);
                
                    % Error Check
                  %  obj.CheckErrorStatus(status);
                
                % write the Value to the digital line defined in Task
                %[status,b,c,d] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',obj.TaskHandles,1,1,10.0,0,Value,0,[]);
                
                    % Error Check
                   % obj.CheckErrorStatus(status);

                % close up shop
                %[status]=calllib(obj.LibraryName,'DAQmxStopTask',obj.TaskHandles);
                
                    % Error Check
                 %   obj.CheckErrorStatus(status);
                    
                %[status]=calllib(obj.LibraryName,'DAQmxClearTask',obj.TaskHandles);
                
                    % Error Check
                  %  obj.CheckErrorStatus(status);
                    
                % return the TaskHandles back to 1
                obj.TaskHandles = 0;
        end
        
        function WriteAnalogOutLine(obj,Line)
            Device = obj.AnalogOutLines{Line};
            Value = obj.AnalogOutVoltages(Line);
           
             WriteAnalogOutVoltage(obj,Device,Value,...
             obj.AnalogOutMinVoltage,obj.AnalogOutMaxVoltage);
        end
        
        function WriteAnalogOutArray(obj,Lines,Values,Grouping)
            
            % create a new task
           % [status,b,obj.TaskHandles] = ...
            %        calllib(obj.LibraryName,'DAQmxCreateTask','NIDAQTask',obj.TaskHandles);
                
                    % Error Check
                %    obj.CheckErrorStatus(status);          
        end
        
        function WriteAnalogOutAllLines(obj)
            for k=1:length(obj.AnalogOutLines),
                WriteAnalogOutLine(obj,k);
            end
        end
        
        function WriteAnalogOutVoltage(obj,Device,Value,MinVal,MaxVal)
            
            % explicit casting to double precision float
            Value = double(Value);
            MinVal = double(MinVal);
            MaxVal = double(MaxVal);
            
            % create a new task
            %[status,b,obj.TaskHandles] = ...
             %       calllib(obj.LibraryName,'DAQmxCreateTask','NIDAQTask',obj.TaskHandles);
                
                    % Error Check
              %      obj.CheckErrorStatus(status);
                
            % create an analog out voltage channel
            %[status] = calllib(obj.LibraryName,'DAQmxCreateAOVoltageChan',obj.TaskHandles,Device,'MyAO',...
             %   MinVal, MaxVal,obj.DAQmx_Val_Volts ,[]);
            
                    % Error Check
              %      obj.CheckErrorStatus(status);
            
            % write an arbitrary voltage to the task
            AutoStart = 1;
            DefaultTimeOut = 10; %seconds
            
            
           % [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogScalarF64',...
            %    obj.TaskHandles, AutoStart, DefaultTimeOut, Value,[]);
            
                    % Error Check
             %       obj.CheckErrorStatus(status);
            
            % stop the task
            %[status]=calllib(obj.LibraryName,'DAQmxStopTask',obj.TaskHandles);
            
                    % Error Check
             %       obj.CheckErrorStatus(status);
            
            % clear the task
            %[status]=calllib(obj.LibraryName,'DAQmxClearTask',obj.TaskHandles);
            
                    % Error Check
             %       obj.CheckErrorStatus(status);
            
            % return the TaskHandles back to 0
            obj.TaskHandles = 0;
        end % WriteAnalogOutVoltage       
        
        function [count] = ReadCounter(obj,TaskName)
            % returns cumulative count from buffer
            % DAQmxGetCICount(TaskHandle taskHandle, const char channel[], uInt32 *data);
            th = obj.Tasks.get(TaskName);
            count = uint32(0);
            pCount = libpointer('uint32Ptr',count);
            TimeOut = 1; %read once, then report
            %[status,count] = calllib(obj.LibraryName,'DAQmxReadCounterScalarU32',th,TimeOut,pCount,[]);
            
                % Error Check
             %   obj.CheckErrorStatus(status);
                
            count = pCount.value;
        end

        function [count] = GetAvailableSamples(obj,TaskName)
            
            th = obj.Tasks.get(TaskName);
            count = uint32(0);
            TimeOut = 0; %read once, then report
            
            if th,
             %   [status,count] = calllib(obj.LibraryName,'DAQmxGetReadAvailSampPerChan',th,count);

                % Error Check
                obj.CheckErrorStatus(status);
            else
                count = 0;
            end
        end

        function [BufferData,status] = ReadCounterBuffer(obj,TaskName,NumSamplesToRead,varargin)
          
            % get task handle
            th = uint32(obj.Tasks.get(TaskName));
            
            
            % allocate buffer memory
            BufferData = zeros(1,NumSamplesToRead); %original
            
            %BufferData_h = zeros(1,NumSamplesToRead); %not original
            %BufferData = uint32(BufferData_h);
            
            % size of buffer
            SizeOfBuffer = uint32(NumSamplesToRead);
            %SizeOfBuffer_int = int32(NumSamplesToRead); %not original
            
            %SizeOfBuffer_h = NumSamplesToRead; %not original
            %SizeOfBuffer 
            pBufferData = libpointer('uint32Ptr', BufferData);
            SampsPerChanRead = 0;
            pSampsPerChanRead = libpointer('int32Ptr',SampsPerChanRead);
            if size(varargin,2)==0
                timeout=obj.DAQmx_Val_WaitInfinitely;
            else
                timeout=varargin{1};
            end
            % when calling the functions in Matlab, the resultant data is
            % passed as an output from calllib instead of using a C-like
            % pointer or passing by reference
            if ~isempty(th) %PAOLA, Sep 19, 2010: if the scan is stopped, the Task is not defined, so do nothing
                
%              Distr = 'Normal';
%              A = 30; %A param for normal is mean
%              B = 5;%0.3e-1; %B param for normal is std dev
%              BufferData =[];
%              for jjj = 1:1:NumSamplesToRead
%              Eps = abs(random(Distr,A,B));
%              Bufferdata = [BufferData Eps];
%              end
                
                %working
                BufferData = 10*abs(rand(1,NumSamplesToRead));
                
                
               %BufferData = [2e3*(1:NumSamplesToRead).^2];
               % [status,BufferData] = calllib(obj.LibraryName,'DAQmxReadCounterU32',th,SizeOfBuffer,...
              %timeout,BufferData,SizeOfBuffer,pSampsPerChanRead,[]);  
                % Error Check
               % obj.CheckErrorStatus(status);
               status = 0;
            end
        end
        
        function [obj] = CreateTask(obj,TaskName)    
           
            % before trying to create a task, check to see if the task
            % exists already
           
            
            if obj.Tasks.containsKey(TaskName),
                % clear out the task
              %  [status] = calllib(obj.LibraryName,'DAQmxClearTask',obj.Tasks.get(TaskName));
                
                    % Error Check
                   % obj.CheckErrorStatus(status);
                    
                warning(sprintf('TaskName: %s already exists.  Purging old task and creating new one',TaskName));
            end
            
            
            th = 0; %taskhandle
            % here 0, in Paul/Jero's code is uint32(1)
           % [status,b,th] = calllib(obj.LibraryName,'DAQmxCreateTask',TaskName,th);
            
                % Error Check
              %  obj.CheckErrorStatus(status);
            
            obj.Tasks.put(TaskName,th);
          
        end
        
        function [obj] = StartTask(obj,TaskName)
            % start the task
           
          %  [status] = calllib(obj.LibraryName,'DAQmxStartTask',obj.Tasks.get(TaskName));
            
                % Error Check
           %     obj.CheckErrorStatus(status);
                
        end
        
        function [obj] = StopTask(obj,TaskName)
            % start the task
           
            th = obj.Tasks.get(TaskName);
            if th
           %     [status] = calllib(obj.LibraryName,'DAQmxStopTask',obj.Tasks.get(TaskName));

                % Error Check
            %    obj.CheckErrorStatus(status);
            end
            
        end

        function [obj] = ClearTask(obj,TaskName)
            
            % check to see if the task name exists
           
            if obj.Tasks.containsKey(TaskName)
                % start the task
               % [status] = calllib(obj.LibraryName,'DAQmxClearTask',obj.Tasks.get(TaskName));

                % Error Check
               % obj.CheckErrorStatus(status);

                % remove task from obj.Task MapContainer
                obj.Tasks.remove(TaskName);
            end
        end
        
        function [obj] = ClearAllTasks(obj)
            %%%%%%%%%%%%%%%%%%%not working
           
            %taskHandles  %= obj.Tasks.keys()
            %~isempty(taskHandles);
%             a = obj.Tasks
%             isempty(a)
%             isempty(obj.Tasks)
%             obj.Tasks
            if ~isempty(obj.Tasks)
            %if ~isempty(taskHandles)
            while taskHandles.hasNext,
                TaskName = taskHandles.nextElement;
                val = obj.Tasks.get(TaskName);

                if val > 0,
                  %  [status] = calllib(obj.LibraryName,'DAQmxClearTask',val);
                    
                        % Error Check
                      %  obj.CheckErrorStatus(status);
                end
                obj.Tasks.remove(TaskName);
            end
            end
            %???? ~isempty(taskHandles);
        end
            
        function [] = WaitUntilTaskDone(obj,TaskName)
       
            % int32 DAQmxWaitUntilTaskDone (TaskHandle taskHandle, float64 timeToWait);
            th = obj.Tasks.get(TaskName);
           % [status] = calllib(obj.LibraryName,'DAQmxWaitUntilTaskDone',th,obj.ReadTimeout);
            
                % Error Check
                obj.CheckErrorStatus(status);
                if status == -200560, % task didn't finish,
                
                    %clear task
                    
                  %  calllib(obj.LibraryName,'DAQmxStopTask',th);
                    return;
                end
        end
        
        function [bool] = IsTaskDone(obj,TaskName)
            
            p = libpointer('ulongPtr',0);
            th = obj.Tasks.get(TaskName);
            if th,
                % [status,bool] = calllib(obj.LibraryName,'DAQmxIsTaskDone',th,p);
            
                % Error Check
               % obj.CheckErrorStatus(status);
            else
                bool = 1; % task done b/c doesn't exist
            end
        end
        
        function [tasks] = GetSysTasks(obj)
            task = [];
          %  [status,tasks] = calllib(obj.LibraryName,'DAQmxGetSysTasks',[],0);
            
                % Error Check
            %    obj.CheckErrorStatus(status);
        end
        
        function [] = ResetDevice(obj)
           % [status] = calllib(obj.LibraryName,'DAQmxResetDevice','Dev1');
                % Error Check
               % obj.CheckErrorStatus(status);
        end

        function [obj] = ConfigureClockOut(obj,TaskName,CounterOutLines,ClockFrequency,DutyCycle)
            %Device = obj.ClockLineLogical{CounterOutLines};
            %th = obj.Tasks.get(TaskName);
            
            % initialize a Freq based pulse train
            %
            %       int32 DAQmxCreateCOPulseChanFreq (TaskHandle taskHandle, const
            %               char counter[], const char nameToAssignToChannel[], int32 units, 
            %               int32 idleState, float64 initialDelay, float64 freq, float64 dutyCycle);
            %
            initialDelay = 0.0;
           % [status] = calllib(obj.LibraryName,'DAQmxCreateCOPulseChanFreq',th,Device,'',obj.DAQmx_Val_Hz,obj.DAQmx_Val_Low,initialDelay,ClockFrequency,DutyCycle);
            
                % Error Check
            %    obj.CheckErrorStatus(status);
            
            % Configure so that the pulse train is generated continuously
            %[status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj.DAQmx_Val_ContSamps,obj.CounterOutSamples);
            
                % Error Check
               % obj.CheckErrorStatus(status);

            obj.ClockRate = ClockFrequency;
        end

        function ConfigureCounterIn(obj,TaskName,CounterInLines,ClockLine,NSamples)
            
            if NSamples <= 0   
             uiwait(warndlg({'Number of samples smaller or equal to 0!'}));
             return;
            end
            
            
            th = obj.Tasks.get(TaskName);
%            CounterDevice = obj.CounterInLines{CounterInLines};
       
               %  updated 31 July 2009, jhodges
            % adds capability to adjust physical line
        %    CounterLinePhysical = obj.CounterInLinesPhysical{CounterInLines};
            
         %   ClockLinePhysical = obj.ClockLinePhysical{ClockLine};

            % create a counter input channel
            %
            %       int32 DAQmxCreateCICountEdgesChan (TaskHandle taskHandle,
            %               const char counter[], const char nameToAssignToChannel[], 
            %               int32 edge, uInt32 initialCount, int32 countDirection);
            %
            
%Masashi04/22/2011 [status] = calllib(obj.LibraryName,'DAQmxCreateCICountEdgesChan',th,CounterDevice,'', obj.DAQmx_Val_Rising,0, obj.DAQmx_Val_CountUp);
            
                % Error Check
%Masashi04/22/2011  obj.CheckErrorStatus(status);
            
%Masashi04/22/2011  [status] = calllib(obj.LibraryName,'DAQmxSetCICountEdgesTerm',th,CounterDevice,CounterLinePhysical);
            
                % Error Check
%Masashi04/22/2011 obj.CheckErrorStatus(status);
            
            % fixed bug here 31 july 2009, jhodges
            % used to be if obj.ClockRate > 0
            if obj.ClockRate <= 0,
                Freq = 1000.0;
            else
                Freq = obj.ClockRate;
            end
            
            % set counter clock to NIDAQ configured line
           % [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical,Freq  , obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NSamples);
            
%             %tell it to be rettrigerable
%              [status] = calllib(obj.LibraryName,'DAQmxSetStartTrigRetriggerable', th, 1);
%                 % Error Check
%                 obj.CheckErrorStatus(status);
            
        end    
        
       
        
        function ConfigurePulseWidth(obj,TaskName,CounterInLines,NSamples)         
            %%%%% works if counterin and clocklines belong to same crt or NOT
            
            if NSamples <= 0   
             uiwait(warndlg({'Number of samples smaller or equal to 0!'}));
             return;
            end
            
            
            
            taskh = obj.Tasks.get(TaskName);
            
            
            % logical name of counter channel
            CounterDevice = obj.CounterInLines{CounterInLines};
            % physical device line of counter channel
            CounterLinePhysical = obj.CounterInLinesPhysical{CounterInLines};
         
            MinVal = 0.000000100; % expected minimum number of ticks
            MaxVal = 100000; %expected max number of ticks
           % [status] = calllib(obj.LibraryName,...
              %  'DAQmxCreateCIPulseWidthChan',taskh,CounterDevice,'', ...
              %  MinVal,MaxVal, obj.DAQmx_Val_Ticks,obj.DAQmx_Val_Rising,'');
              %  obj.CheckErrorStatus(status); % Error Check
          
% %   %             % set to a finite number of samples
           % [status] = calllib(obj.LibraryName,...
            %     'DAQmxCfgImplicitTiming',taskh,obj.DAQmx_Val_FiniteSamps, NSamples );            
%                 % Error Check
%obj.CheckErrorStatus(status);
% %           
                
            % set Duplicate Counter prevention for this counting mode
          %  [status] = calllib(obj.LibraryName,...
             %   'DAQmxSetCIDupCountPrevent',taskh,CounterDevice,1);            
                % Error Check
             %   obj.CheckErrorStatus(status);
        end
        
        
         function ConfigurePulseWidthCounterIn(obj,TaskName,CounterInLines,ClockLine,NSamples)         
            %%%%% works if counterin and clocklines belong to same crt or NOT
           
            % use this style counter for pulsed spin measurements (i.e.
            % not scan, imaging or basic counting)  
           
            if NSamples <= 0   
             uiwait(warndlg({'Number of samples smaller or equal to 0!'}));
             return;
            end
            
            
            
            taskh = obj.Tasks.get(TaskName);
            
            
            % logical name of counter channel
%            CounterDevice = obj.CounterInLines{CounterInLines};
            % physical device line of counter channel
 %           CounterLinePhysical = obj.CounterInLinesPhysical{CounterInLines};
            % gate/clock line for counter
  %          ClockLinePhysical = obj.ClockLinePhysical{ClockLine};
            
           
            MinVal = 0.000000100; % expected minimum number of ticks
            MaxVal = 100000; %expected max number of ticks
          %  [status] = calllib(obj.LibraryName,...
              %  'DAQmxCreateCIPulseWidthChan',taskh,CounterDevice,'', ...
              %  MinVal,MaxVal, obj.DAQmx_Val_Ticks,obj.DAQmx_Val_Rising,'');
              %  obj.CheckErrorStatus(status); % Error Check
                
            % the source of the counting  
           % [status] = calllib(obj.LibraryName,...
              %  'DAQmxSetCIPulseWidthTerm',taskh,CounterDevice, ClockLinePhysical);
             %   obj.CheckErrorStatus(status);% Error Check
                
               
       %set counter clock to NIDAQ configured line
             %uses external source, which is the piezo ttl    
          % [status] = calllib(obj.LibraryName,...
           %    'DAQmxSetCICtrTimebaseSrc',taskh, CounterDevice, CounterLinePhysical);            
                % Error Check
%                
              %  obj.CheckErrorStatus(status);    
% % %                 
% %   %             % set to a finite number of samples
           % [status] = calllib(obj.LibraryName,...
            %    'DAQmxCfgImplicitTiming',taskh,obj.DAQmx_Val_FiniteSamps, NSamples );            
%                 % Error Check
          %      obj.CheckErrorStatus(status);
% %           
                
            % set Duplicate Counter prevention for this counting mode
          %  [status] = calllib(obj.LibraryName,...
          %      'DAQmxSetCIDupCountPrevent',taskh,CounterDevice,1);            
                % Error Check
            %    obj.CheckErrorStatus(status);
        end
        
        function ConfigureDigitalOut(obj,TaskName,DigitalOutLines,ClockLine,WriteVoltages,ClockRate)
            
            % get the task handle
            th = obj.Tasks.get(TaskName);
            
            % get the total number of digital lines
            NLines = length(DigitalOutLines);
            NVoltagesPerLine = length(WriteVoltages)/NLines;
            
            Device = ''
            for k=1:NLines,
                Device = [Device,',',obj.DigitalIOLines{DigitalOutLines(k)}];
            end
            
           % create an digital out channel
           % [status] = calllib(obj.LibraryName,'DAQmxCreateDOChan',th,Device,'MyDO',...
            %    obj.DAQmx_Val_ChanPerLine);
            
                % Error Check
              %  obj.CheckErrorStatus(status);
                
                
           % timing of the channel is set to that of the digial clock
          %  [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, obj.ClockLinePhysical{ClockLine},...
             %   ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
            
                % Error Check
             %   obj.CheckErrorStatus(status);
        
            AutoStart = 0 % don't autostart
            % write an arbitrary voltage to the task
           % [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogF64',th,...
              %  NVoltagesPerLine, AutoStart, obj.WriteTimeout, obj.DAQmx_Val_GroupByChannel, WriteVoltages, [],[]);
            
           % [status] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',th,NVoltagesPerLine,AutoStart,...
             %   obj.WriteTimeout,obj.DAQmx_Val_GroupByChannel,WriteVoltages,[],[])
            
                % Error Check
              %  obj.CheckErrorStatus(status);
        end
        
        function Connect(obj, source_terminal, destination_terminal)
            
            %[status] = calllib(obj.LibraryName,'DAQmxConnectTerms',source_terminal, destination_terminal, 0);
            
             % Error Check
                obj.CheckErrorStatus(status);
            
        end
        
        
         function ConfigReadVoltageInput(obj,TaskName,analog_in_line, max_signal, min_signal,NSamples,Freq)
             %max_signal, min_signal (negative) in V; 
             %�10 V to 10 V -> resolution 320muV
             %-5V to 5V-> resolution 160muV
             %-1V to +1V -> resolution 32muV
             
             %in the example, NSamples = 1000
             %Freq = 10000

             
             if NSamples <= 0   
             uiwait(warndlg({'Number of samples smaller or equal to 0!'}));
             return;
            end
             
             
            % get task handle
            th = uint32(obj.Tasks.get(TaskName));
            
            NSamples = uint32(NSamples);
%             line = obj.AILineLogical{analog_in_line};
            
      %[status] = calllib(obj.LibraryName,'DAQmxCreateAIVoltageChan',th,line,'',obj.DAQmx_Val_Cfg_Default,min_signal,max_signal,obj.DAQmx_Val_Volts,'');
      
             
     %[status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th,'',Freq,obj.DAQmx_Val_Rising,obj.DAQmx_Val_FiniteSamps,NSamples);
     
         end
   
         
         function [data] = ReadVoltageInput(obj,TaskName,NSamples)
             
             if NSamples <= 0   
             uiwait(warndlg({'Number of samples smaller or equal to 0!'}));
             return;
            end
             
             
             th = uint32(obj.Tasks.get(TaskName));
             NSamples = uint32(NSamples);
             
            data = rand*ones(1,NSamples);
            data_ptr = libpointer('doublePtr',data);
            sampread = 0;
            sampread_ptr = libpointer('int32Ptr',sampread);
            empty = [];
            emptry_ptr = libpointer('uint32Ptr',empty);
     
  % [status,data,sampread,empty] = calllib(obj.LibraryName,'DAQmxReadAnalogF64',th,-1,-1,obj.DAQmx_Val_GroupByScanNumber,data_ptr,NSamples, sampread_ptr,emptry_ptr);
          
     %     obj.CheckErrorStatus(status);
      
          
         end
        
         
         
        
        function delete(obj)
            % destructor method
            %
            % unload library
            %if ~libisloaded(obj.LibraryName),
             %   [pOk,warnings] = unloadlibrary(obj.LibraryName);
            %end
        end %delete
            
            
    end 
    
     events
        UpdateCounterData
        UpdateCounterProcData
    end
end
