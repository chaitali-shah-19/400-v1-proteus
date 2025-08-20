classdef Oxford_temp_controller
    properties
        gpib_obj
    end
    methods
        function obj=MW_Open(obj)
            obj.gpib_obj=gpib('ni',0,24); 
            fopen(obj.gpib_obj);
            obj.gpib_obj.EOSMode = 'read&write';
            obj.gpib_obj.EOSCharCode = 'CR';
            fprintf(obj.gpib_obj,'C3'); %sets ITC control panel to remote and unlocked
        end
        
        function temp= read_temp(obj)
            fprintf(obj.gpib_obj,'R1'); %queries sensor 1 temperature
            pause(0.1);
            a=fread(obj.gpib_obj);
            b=char(a)';temp=str2num(b(2:6));            
        end
        
        function set_temp(obj,set_temp)
            fprintf(obj.gpib_obj,['T' set_temp]); %set temperature
            pause(0.1);
        end
        
        function set_volt(obj,max_volt,set_volt)
            fprintf(obj.gpib_obj,['M',max_volt]);
            fprintf(obj.gpib_obj,['O' set_volt]);
        end
    end     
end