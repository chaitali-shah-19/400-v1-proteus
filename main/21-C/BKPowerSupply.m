classdef BKPowerSupply
    properties
        gpib_obj
    end
    methods
        function obj=BKPowerSupply(obj)
            obj.gpib_obj=serial('COM9');
            set(obj.gpib_obj, ...
     'BaudRate', 9600, ...
     'DataBits', 8, ...
     'FlowControl', 'none', ...
     'Parity', 'none', ...
     'StopBits', 1, ...
     'Terminator','CR/LF')
 fopen(obj.gpib_obj);
            
        end
        function VoltRead=PS_VoltRead(obj)
            fprintf(obj.gpib_obj,'GETS');
            VoltStr=fscanf(obj.gpib_obj);
            VoltRead=str2num(VoltStr);
        end
        function PS_VoltSet(obj,Volt_Set)
            VoltSetStr=sprintf('VOLT%03d',Volt_Set*10);
            fprintf(obj.gpib_obj,VoltSetStr);
        end
        function CurrRead=PS_CurrRead(obj)
            fprintf(obj.gpib_obj,'GETS');
            CurrStr=fscanf(obj.gpib_obj);
            CurrRead=str2num(CurrStr);
        end
        function PS_CurrSet(obj,Curr_Set)
            CurrSetStr=sprintf('CURR%03d[CR]',Curr_Set*10);
            fprintf(obj.gpib_obj,CurrSetStr);
        end
        function PS_Close(obj)
            serialObj = instrfind;
            s=size(serialObj);
            for i=1:s(1,2)
            fclose(serialObj(i));
            end
        end
        function PS_OUTOn(obj)
            fprintf(obj.gpib_obj,'SOUT0');
        end
        function PS_OUTOff(obj)
            fprintf(obj.gpib_obj,'SOUT1');
        end
        
    end
end