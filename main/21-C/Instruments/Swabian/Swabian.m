classdef Swabian < handle
    properties
        gpib_obj
    end
    methods
        function obj=Swabian(obj)
            import PulseStreamer.*;
            ip = '169.254.8.2';
            obj=PulseStreamer(ip);
%             obj.reset(); 
        end

    end
end
       