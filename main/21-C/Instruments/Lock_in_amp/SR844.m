classdef SR844 < handle
    properties
        gpib_obj
    end
    methods
        function obj=SR844(obj)
            obj.gpib_obj=gpib('ni',1,8);
            fopen(obj.gpib_obj);
        end


        function output=read_single(obj)
            fprintf(gpib_obj,'OUTP?5');
            pause(0.1);
            a=fread(gpib_obj); b=char(a)';output=str2num(b);
        end

        function freq=read_freq(obj)
            fprintf(gpib_obj,'FREQ?');
            pause(0.1);
            a=fread(gpib_obj); b=char(a)';freq=str2num(b);
        end

        function set_freq(obj,freq)
            fprintf(gpib_obj,['FREQ' num2str(freq)]);
        end

         function volt=read_voltage(obj)
            fprintf(gpib_obj,'OUTP?3');
            pause(0.1);
            a=fread(gpib_obj); b=char(a)';volt=str2num(b);
        end

        function rate=read_sampling_rate(obj)
            fprintf(gpib_obj,'SRAT?');
            pause(0.1);
            a=fread(gpib_obj); b=char(a)';rate=str2num(b);
        end

         function set_sampling_rate(obj,rate)
            fprintf(gpib_obj,['SRAT' num2str(rate)]);
        end


    end
end
       