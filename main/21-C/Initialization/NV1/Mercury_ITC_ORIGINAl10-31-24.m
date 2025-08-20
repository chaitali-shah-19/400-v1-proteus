classdef Mercury_ITC
    properties
        gpib_obj
        port_name
    end
    methods
        function obj=Mercury_ITC(port_name)
            obj.gpib_obj=serial(port_name);
            set(obj.gpib_obj, ...
     'BaudRate', 9600, ...
     'DataBits', 8, ...
     'FlowControl', 'none', ...
     'Parity', 'none', ...
     'StopBits', 1, ...
     'Terminator','LF')
 fopen(obj.gpib_obj);
            
        end

        function temp=ReadTemp(obj)
            fprintf(obj.gpib_obj,'READ:DEV:MB1.T1:TEMP:SIG:TEMP?');
            readout=fscanf(obj.gpib_obj);
            start_ind=strfind(readout,'TEMP');start_ind=start_ind(2)+4;
            end_ind=strfind(readout,'K');
            temp=str2num(readout(start_ind+1:end_ind-1));
        end

        function volt=ReadVoltage(obj)
            fprintf(obj.gpib_obj,'READ:DEV:MB0.H1:TEMP:SIG:VOLT?');
            readout=fscanf(obj.gpib_obj);
            start_ind=strfind(readout,'VOLT');start_ind=start_ind(1)+4;
            end_ind=strfind(readout,'V');end_ind=end_ind(end);
            volt=str2num(readout(start_ind+1:end_ind-1));
        end

        function SetTemp(obj,temp)
              fprintf(obj.gpib_obj,['SET:DEV:MB1.T1:TEMP:LOOP:TSET:' num2str(temp)]);
              %fprintf(obj.gpib_obj,'SET:DEV:MB1.T1:TEMP:LOOP:TSET:100.00');
              readout=fscanf(obj.gpib_obj);
              pause(0.5);
        end

        function SetAuto(obj,flag)
            if flag==1
            fprintf(obj.gpib_obj,'SET:DEV:MB1.T1:TEMP:LOOP:ENAB:ON');%auto OFF/ON
            elseif flag==0
                fprintf(obj.gpib_obj,'SET:DEV:MB1.T1:TEMP:LOOP:ENAB:OFF');%auto OFF/ON
            end
            readout=fscanf(obj.gpib_obj);
            pause(0.1);
        end
        
        function SetHeater(obj,heat_level)
            fprintf(obj.gpib_obj,['SET:DEV:MB1.T1:TEMP:LOOP:HSET:' num2str(heat_level)]);%percentage
            readout=fscanf(obj.gpib_obj);
            pause(0.5);
        end
       
        function SetP(obj,P)
            fprintf(obj.gpib_obj,['SET:DEV:MB1.T1:TEMP:LOOP:P:' num2str(P)]);%SET PID
            readout=fscanf(obj.gpib_obj);
            pause(0.5);
        end

        function SetI(obj,I)
            fprintf(obj.gpib_obj,['SET:DEV:MB1.T1:TEMP:LOOP:I:' num2str(I)]);%SET PID
            readout=fscanf(obj.gpib_obj);
            pause(0.5);
        end

        function SetD(obj,D)
            fprintf(obj.gpib_obj,['SET:DEV:MB1.T1:TEMP:LOOP:D:' num2str(D)]);%SET PID
            readout=fscanf(obj.gpib_obj);
            pause(0.5);
        end

        function Mercury_Close(obj)
            serialObj = instrfind;
            s=size(serialObj);
            for i=1:s(1,2)
            fclose(serialObj(i));
            end
        end
        
    end
end