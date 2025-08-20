classdef ProteusHeader
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    properties
        header_size = 72
        header_nmb {mustBeNumeric}
        buf
    end
    
    properties
        TriggerPos 	,
        GateLength 	,
        minVpp 		,
        maxVpp 		,
        TimeStamp 	,
        real1_dec 	,
        im1_dec 	,
        real2_dec 	,
        im2_dec 	,
        state1 		,
        state2 		
    end
    
    methods
        % Constructor
        function obj = ProteusHeader(val,array)
            if nargin == 0
                obj.header_nmb = 1;
                obj.buf = zeros(1, obj.header_size);
            elseif nargin == 1
                obj.header_nmb = val;
                obj.buf = zeros(1, obj.header_size);    
            elseif nargin == 2
                obj.header_nmb = val;
                obj.buf = array;
            end
            
            obj.TriggerPos  = typecast(uint8(obj.buf(1:4)),'int32');
            obj.GateLength  = typecast(uint8(obj.buf(5:8)),'int32');
            obj.minVpp      = typecast(uint8(obj.buf(9:10)),'int16');
            obj.maxVpp      = typecast(uint8(obj.buf(11:12)),'int16');
            obj.TimeStamp   = typecast(uint8(obj.buf(13:20)),'int64');
            obj.real1_dec   = typecast(uint8(obj.buf(21:24)),'int32');
            obj.im1_dec     = typecast(uint8(obj.buf(25:28)),'int32');
            obj.real2_dec   = typecast(uint8(obj.buf(29:32)),'int32');
            obj.im2_dec     = typecast(uint8(obj.buf(33:36)),'int32');
            obj.state1      = uint8(obj.buf(37));
            obj.state2      = uint8(obj.buf(38));
           
        end
        
        
        function obj = parseHeader(obj)
            obj.TriggerPos  = typecast(uint8(obj.buf(1:4)),'int32');
            obj.GateLength  = typecast(uint8(obj.buf(5:8)),'int32');
            obj.minVpp      = typecast(uint8(obj.buf(9:10)),'int16');
            obj.maxVpp      = typecast(uint8(obj.buf(11:12)),'int16');
            obj.TimeStamp   = typecast(uint8(obj.buf(13:20)),'int64');
            obj.real1_dec   = typecast(uint8(obj.buf(21:24)),'int32');
            obj.im1_dec     = typecast(uint8(obj.buf(25:28)),'int32');
            obj.real2_dec   = typecast(uint8(obj.buf(29:32)),'int32');
            obj.im2_dec     = typecast(uint8(obj.buf(33:36)),'int32');
            obj.state1      = uint8(obj.buf(37));
            obj.state2      = uint8(obj.buf(38));
        end
        
        function [hsize] = getHeaderSize(obj)
            hsize = obj.header_size;
        end
        
        function printHeader(obj)
            fprintf('header# %d\n',obj.header_nmb);
            fprintf('TriggerPos : %d\n',obj.TriggerPos);
            fprintf('GateLength : %d\n',obj.GateLength);
            fprintf('Min Amp    : %d\n',obj.minVpp);
            fprintf('Max Amp    : %d\n',obj.maxVpp);
            fprintf('TimeStamp  : %d\n',obj.TimeStamp);
            fprintf('Decision1  : %d + j* %d\n',obj.real1_dec,obj.im1_dec);
            fprintf('Decision2  : %d + j* %d\n',obj.real2_dec,obj.im2_dec);
            fprintf('STATE1     : %d\n',obj.state1);
            fprintf('STATE2     : %d\n',obj.state2);
        end
   
    end
    
end

