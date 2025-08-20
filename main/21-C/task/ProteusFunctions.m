classdef ProteusFunctions
    %PROTEUSFUNCTIONS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        
        %% 
        function retval = convertToBynaryOffset (~,myArray, dacRes)
  
          minLevel = 0;
          maxLevel = 2 ^ dacRes - 1;  
          numOfLevels = maxLevel - minLevel + 1;

          retval = round((numOfLevels .* (myArray + 1) - 1) ./ 2);
          retval = retval + minLevel;

          retval(retval > maxLevel) = maxLevel;
          retval(retval < minLevel) = minLevel;

        end
        %%
        function [normI,  normQ] = NormalIq(~,wfmI, wfmQ)    
    
            maxPwr = max(wfmI.*wfmI + wfmQ .* wfmQ);
            maxPwr = maxPwr ^ 0.5;

            normI = wfmI / maxPwr;
            normQ = wfmQ / maxPwr;

        end
        %% 
        function outWfm = Interleave(~,wfmI, wfmQ)   

            wfmLength = length(wfmI);
            outWfm = zeros(1, 2 * wfmLength);

            outWfm(1:2:(2 * wfmLength - 1)) = wfmI;
            outWfm(2:2:(2 * wfmLength)) = wfmQ;
        end
        
        %% 
        function dataOut = expanData(~,inputWfm, oversampling)
            dataOut = zeros(1, oversampling * length(inputWfm));
            dataOut(1:oversampling:length(dataOut)) = inputWfm;
        end
        
        %% 
        function dataOut = getRnData(~,nOfS, bPerS)
            maxVal = 2 ^ bPerS;
            dataOut = maxVal * rand(1, nOfS);
            dataOut = floor(dataOut);
            dataOut(dataOut >= maxVal) = maxVal - 1;    
        end
        
        %% 
        function [dataOut] = Digital_Modulation_wave(obj,modType,numOfSymbols,symbolRate,rollOff,sampleRate,interpol)      
            % modType     Modulation
            % 5                 QPSK
            % 6                 QAM16
            % 7                 QAM32
            % 8                 QAM64
            % 9                 QAM128
            %10                 QAM256
            %11                 QAM512
            %12                 QAM1024
            
            if modType == 5
                bitsPerSymbol = 2;
            elseif modType == 6
                bitsPerSymbol = 4;
            elseif modType == 7
                bitsPerSymbol = 5;
            elseif modType == 8
                bitsPerSymbol = 6;
            elseif modType == 9
                bitsPerSymbol = 7;
            elseif modType == 10
                bitsPerSymbol = 8;
            elseif modType == 11
                bitsPerSymbol = 9;
            elseif modType == 12
                bitsPerSymbol = 10;
            else
                bitsPerSymbol = 2;
            end
       

            % Waveform Length Calculation
            sampleRate = sampleRate / interpol;

            [decimation, oversampling] = obj.reduceFraction(symbolRate, sampleRate);              


            % Create IQ for QPSK/QAM    
            % accuracy is the length of the shaping filter
            accuracy = 64;
            fType = 'normal'; % 'normal' or 'sqrt'
            % Get symbols in the range 1..2^bps-1
            data = obj.getRnData(numOfSymbols, bitsPerSymbol);
            % Map symbols to I/Q constellation locations
            [dataI, dataQ] = obj.getIqMap(data, bitsPerSymbol);
            % Adapt I/Q sample rate to the AWG's

            dataI = obj.expanData(dataI, oversampling);
            dataQ = obj.expanData(dataQ, oversampling);
            % Calculate baseband shaping filter
            rsFilter = rcosdesign(rollOff,accuracy,oversampling, fType);
            % Apply filter through circular convolution
            dataI = cconv(dataI, rsFilter, length(dataI));
            dataQ = cconv(dataQ, rsFilter, length(dataQ));

            dataI = dataI(1:decimation:length(dataI));
            dataQ = dataQ(1:decimation:length(dataQ));
            
            L = length(dataI);
            Lr = 32*floor(L/32);
            
            dataI = dataI(1:Lr);
            dataQ = dataQ(1:Lr);
            
            
            % Output waveforfm must be made of complex samples
            dataOut = dataI + 1i * dataQ;
        end
        %% 
        function [outNum, outDen] = reduceFraction(~,num, den)
        %reduceFraction Reduce num/den fraction
        %   Use integers although not mandatory
            num = round(num);
            den = round(den);
            % Reduction is obtained by calcultaing the greater common divider...
            G = gcd(num, den);
            % ... and then dividing num and den by it.
            outNum = num / G;
            outDen = den / G;
        end
        %% 
        function [symbI, symbQ] = getIqMap(~,data, bPerS)
   
            if bPerS == 5 % QAM32 mapping
                lev = 6;
                data = data + 1;
                data(data > 4) = data(data > 4) + 1;
                data(data > 29) = data(data > 29) + 1; 

            elseif bPerS == 7 % QAM128 mapping      
                lev = 12;
                data = data + 2;
                data(data > 9) = data(data > 9) + 4;
                data(data > 21) = data(data > 21) + 2;
                data(data > 119) = data(data > 119) + 2;
                data(data > 129) = data(data > 129) + 4;

             elseif bPerS == 9 % QAM512 mapping       
                lev = 24;
                data = data + 4;
                data(data > 19) = data(data > 19) + 8;
                data(data > 43) = data(data > 43) + 8;
                data(data > 67) = data(data > 67) + 8;
                data(data > 91) = data(data > 91) + 4;
                data(data > 479) = data(data > 479) + 4;
                data(data > 499) = data(data > 499) + 8;
                data(data > 523) = data(data > 523) + 8;
                data(data > 547) = data(data > 547) + 8;            
            else
                lev = 2 ^ (bPerS / 2); % QPSK, QAM16, QAM64, QAM256, QAM1024      
            end

            symbI = floor(data / lev);
            symbQ = mod(data, lev);
            lev = lev / 2 - 0.5;   
            symbI = (symbI - lev) / lev;
            symbQ = (symbQ - lev) / lev;
        end
        
        %%
        function str = netStrToStr(~,netStr)
            try
                str = convertCharsToStrings(char(netStr));
            catch        
                str = '';
            end
        end

        %% 
        function [dataout] = ConvertSampleToNormalsigned(~,inp,size)
            M = 2^(size-1);
            A = 2^size;
            
            dataout = double(inp) - M;
            dataout = dataout ./ M;
        end
        
     
        
        
    end
end

