classdef ExperimentFunctions < handle
    
    properties
        
        interfaceSigGen
        interfaceSigGen2 %for the second SG386 source
        interfaceBNC
        RawData
        AvgData
        Std_dev
        delay_init_and_end_seq
        statuswbexp =0; %will be used as a handle to close the waitbar in case of stop scan
        wf
        com
        mw2
        mw
        arb1
        arb2
        arb3
        arb4
        arb5
        arb6
        arb7
        arb8
        arb9
        arb10
        arb11
        arb12
        arb_mag
        pw1
        pw2
        pw3
        pw4
        pw5
        pw6
        pw7
        pw8
        laser
        gpib_LockInAmp
        att
        ramp
        psu
        psu2
        tabor
        srs
        laserdome
        %aaatProteus
    end
    
    methods
        
        %%%%% Run experiment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function RunExperiment(obj,handles)
           warning('off','all');
            handles.ExperimentFinished=0;
            profile on
          
            err = 0; % var that tracks hardware limits on the sequence (for SG, AWG)
            err_latency=0;
            handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted = 0;
            set(handles.text_power,'Visible','on');
            set(handles.slider_each_avg,'Visible','off');
            set(handles.avg_nb,'Visible','off');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % General setup
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            set(handles.uipanel90,'Visible','off');
            set(handles.text_ExpStatus,'String','Experiment Started');
            set(handles.sliderExpScan,'Visible','off');
            set(handles.edit_NoteExp,'Enable','on');
            set(handles.edit_NoteExp,'String','Notes on Experiment:');
            handles.ExperimentalScan.Notes = 'Notes on Experiment:';
            set(handles.button_NoteExp,'Enable','on');
            set(handles.sliderExpScan,'Visible','off');
            set(handles.popup_experiments,'Value',1);
            set(handles.axes_RawData,'Visible','on');
            set(handles.text181,'Visible','on');
            
            %Open MWGenerator
            %handles.ExperimentFunctions.mw.AM100();
            
            %here commented only for random noise exps
            cla(handles.axes_AvgData,'reset');
            cla(handles.axes_RawData,'reset');
           
            % get number of sequence repetitions and averages
            if get(handles.average_continuously,'Value')
                Averages = 1;
            else
                Averages = str2num(get(handles.edit_Averages,'String'));
            end

            Repetitions = str2num(get(handles.edit_Repetitions,'String'));
            handles.ExperimentalScan.Repetitions = Repetitions;
           
            %commented only for Random noise exp
            handles.kk = 1; %worst case picture

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            odnmr_rawdata=[];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % No loop over second dimension
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%OPEN SPIKE
            try
            Close_spike();
            end
            [start,stop]= Initialize_spike();
            
%             %% Initialize Proteus on Sage
%             %Sage_write('1');
%             Sage_write('1');
            

        for  avg_count=1:1:Averages
               %%Loop over averages
                  helper_scan=1;  
 
                 if ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
             
                        try
                           for aux=1:1:handles.ExperimentalScan.vary_points(1)  %loop over first scan dimension
    %                         pause(3);
                            disp(['Running experiment number:' num2str(aux)])
                            status=1;                        
                            if ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                            tic;
                
                                 %% SETUP Helmholtz Coil
                                if length(handles.Array_PSeq{1}.Channels)>=34
                                if handles.Array_PSeq{1}.Channels(34).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                helmholtz_current=handles.Array_PSeq{helper_scan,aux}.Channels(34).Frequency;
                                end
                                end
           

                                %% SETUP AWG + SRS
                                if length(handles.Array_PSeq{1}.Channels)>=39
                                    if handles.Array_PSeq{1}.Channels(39).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted

    %                                     obj.tabor.awg_reset(); %reset
    %                                     pause(1);
    %                                     
                                        %AWG parameters
    %                                     awg_start_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).Frequency;
    %                                     awg_stop_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).Phase;
                                        awg_center_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).Frequency;
                                        awg_bw_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).Phase;
                                        awg_amp=handles.Array_PSeq{helper_scan,aux}.Channels(39).Amplitude;
                                        sweep_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).PhaseQ;
                                        sweep_sigma=handles.Array_PSeq{helper_scan,aux}.Channels(39).FreqIQ;
                                        symm=handles.Array_PSeq{helper_scan,aux}.Channels(39).Phasemod;
                                        %SRS parameters
                                        srs_freq=handles.Array_PSeq{helper_scan,aux}.Channels(39).FreqmodI;
                                        srs_amp=handles.Array_PSeq{helper_scan,aux}.Channels(39).FreqmodQ;

                                        % setup AWG for start and stop freq
                                        %obj.tabor.awg_chirp(srs_freq-awg_start_freq,srs_freq-awg_stop_freq,awg_amp,0,1/sweep_freq);

                                        % setup AWG for bandwidth and center
                                        % freq
                                       % obj.tabor.awg_chirp(srs_freq-awg_start_freq,srs_freq-awg_stop_freq,awg_amp,0,1/sweep_freq);
                                        %obj.tabor.awg_chirp(srs_freq-(awg_center_freq+awg_bw_freq/2),srs_freq-(awg_center_freq-awg_bw_freq/2),awg_amp,0,1/sweep_freq);

                                        % add custom chirp here.
                                        sampleRateDAC = 9000e6;
                                        dacChanInd = 1;
                                        measurementTimeSeconds = 7; %Integer
                                        delay = 0.0000173; % dead time

                                        sweepers_en = 0;
                                        
                                        
                                        bits = 8;
                                        segment = 1;

                                        rampTime = 1/sweep_freq;
                                        fCenter = awg_center_freq - srs_freq;
                                        fStart = fCenter - 0.5*awg_bw_freq;
                                        fStop = fCenter + 0.5*awg_bw_freq;
                     
                                        dt = 1/sampleRateDAC;
                                        fprintf(1, 'INITIALIZING SETTINGS\n');

                                        % The TEPAdmin.dll is installed by WDS Setup in C:\Windows\System32
                                        
                                        % Currently the tested DLL is installed in the following path
                                        asm = NET.addAssembly('C:\Windows\System32\TEPAdmin.dll');
                                        
                                        import TaborElec.Proteus.CLI.*
                                        import TaborElec.Proteus.CLI.Admin.*
                                        import System.*
                                        
                                        admin = CProteusAdmin(@OnLoggerEvent);
                                        admin.Close();
                                        rc = admin.Open();
                                        assert(rc == 0);
                                        try
                                            try
                                            slotIds = admin.GetSlotIds();
                                            numSlots = length(slotIds);
                                            assert(numSlots > 0);
                                            sId = 8;
                                            % Connect to the selected instrument ..
                                            should_reset = true;
                                            inst = admin.OpenInstrument(sId, should_reset);
                                            instId = inst.InstrId;
                                            
                                            catch ME
                                            admin.Close();
                                            rethrow(ME)
                                            end
                                            connect = 1;
                                            % If there are multiple slots, let the user select one ..
%                                             sId = slotIds(1);
%                                             if numSlots > 1
%                                                 fprintf(1, '\n%d slots were found\n', numSlots);
%                                                 for n = 1:numSlots
%                                                     sId = slotIds(n);
%                                                     slotInfo = admin.GetSlotInfo(sId);
%                                                     if ~slotInfo.IsSlotInUse
%                                                         modelName = slotInfo.ModelName;
%                                                         if slotInfo.IsDummySlot
%                                                             fprintf(1, ' * Slot Number: Model %s [Dummy Slot].\n', sId, ModelName);
%                                                         else
%                                                             fprintf(1, ' * Slot Number: Model %s.\n', sId, ModelName);
%                                                         end
%                                                     end
%                                                 end
%                                                 choice = input('Enter SlotId ');
%                                                 fprintf(1, '\n');
%                                                 sId = uint32(choice);
                                             %end

                                            
                                            %sId = 8;
                                            
                                            % Connect to the selected instrument ..
%                                             should_reset = false;
%                                             inst = admin.OpenInstrument(sId);
%                                             instId = inst.InstrId;
                                            
                                            %     In other code...
                                            %     % Connect to the selected instrument ..
                                            %     should_reset = true;
                                            %     inst = admin.OpenInstrument(sId, should_reset);
                                            %     instId = inst.InstrId;
                                            
                                            % ---------------------------------------------------------------------
                                            % Setup instrument
                                            % ---------------------------------------------------------------------
                                            
                                            res = inst.SendScpi('*IDN?');
                                            assert(res.ErrCode == 0);
                                            %fprintf(1, '\nConnected to ''%s''\n', netStrToStr(res.RespStr));
                                            
                                            pause(0.01);
                                            
                                            res = inst.SendScpi('*CLS'); % clear
                                            assert(res.ErrCode == 0);
                                            
                                            res = inst.SendScpi('*RST'); % reset
                                            assert(res.ErrCode == 0);
                                            
                                            res = inst.SendScpi(':FREQ:RAST 9E9'); % set sample clock
                                            assert(res.ErrCode == 0);
                                            
                                            fprintf('Reset complete\n');
                                            
                                            % ---------------------------------------------------------------------
                                            % ADC Config
                                            % ---------------------------------------------------------------------
                                            
%                                             rc = inst.SetAdcDualChanMode(1); %set to dual frame granularity = 48
%                                             assert(rc == 0);
%                                             
%                                             rc = inst.SetAdcSamplingRate(sampleRate);
%                                             assert(rc == 0);
%                                             
%                                             rc = inst.SetAdcFullScaleMilliVolts(0,fullScaleMilliVolts);
%                                             assert(rc == 0);
%                                             
%                                             fprintf('ADC Configured\n');
%                                             segLen = 40960;
%                                             segLenDC = 50048;
%                                             cycles = 800;
%                                             
                                            
                                       
                                            res = inst.SendScpi('INST:CHAN 1');% num2str(dacChanInd)]); % 
                                            assert(res.ErrCode == 0);
                                            
                                           
                                            
                                            rampTime = 1/sweep_freq;
                                            fCenter = awg_center_freq - srs_freq;
                                            fStart = fCenter - 0.5*awg_bw_freq;
                                            fStop = fCenter + 0.5*awg_bw_freq;
                                            dt = 1/sampleRateDAC;
                                            
                                            % dacSignalMod = sine(cycles, 0, segLen, bits); % sclk, cycles, phase, segLen, amp, bits, onTime(%)
                                            
                                            %                 dacSignalDC = [];
                                            %                 for i = 1 : segLenDC
                                            %                   dacSignalDC(i) = 127;
                                            %                 end
                                            %
                                            %  dacSignal = [dacSignalMod];% dacSignalDC];
                                            % plot(dacSignal)
                                            
                                            %dacSignal = makeChirp(sampleRateDAC, rampTime, dt, fStart, fStop, bits);
                                            t =  0:1/sampleRateDAC:rampTime;
                                            dacWave = chirp(t,fStart,rampTime,fStop);
                                            seglenTrunk = (floor(length(dacWave)/64))*64;
                                            dacWave = dacWave(1:seglenTrunk);
                                            maxSig = max(dacWave);
                                            verticalScale = ((2^bits/2)-1);
                                            vertScaled = (dacWave/ maxSig) * verticalScale;
                                            dacSignal = uint8(vertScaled + verticalScale);
                                            
                                            fprintf('waveform length - ');
                                            fprintf(num2str(length(dacSignal)));
                                            fprintf('\n') ;
                                            
                                            % Define segment 1
                                            res = inst.SendScpi(strcat(':TRAC:DEF 1,',num2str(length(dacSignal)))); % define memory location 1 of length dacSignal
                                            assert(res.ErrCode == 0);
                                            
                                            % select segmen 1 as the the programmable segment
                                            res = inst.SendScpi(':TRAC:SEL 1');
                                            assert(res.ErrCode == 0);
                                            
                                            % Download the binary data to segment 1
                                            res = inst.WriteBinaryData(':TRAC:DATA 0,#', dacSignal);
                                            assert(res.ErrCode == 0);
                                            
                                            srs_freq_str = [':SOUR:NCO:CFR1  ' sprintf('%0.2e', srs_freq)];
                                            res = inst.SendScpi(srs_freq_str);
                                            assert(res.ErrCode == 0);
                                            
                                            srs_freq_str = [':SOUR:NCO:CFR2 ' sprintf('%0.2e', srs_freq)];
                                            res = inst.SendScpi(srs_freq_str);
                                            assert(res.ErrCode == 0);
                
                                            
                                            res = inst.SendScpi(':SOUR:MODE DUC'); % IQ MODULATOR --
                                            %                 THINK OF A MIXER, BUT DIGITAL
                                            %fff=inst.SendScpi(':SOUR:MODE?');
                                            %print(fff.RespStr);
                                            assert(res.ErrCode == 0);
                                            
                                            %                 try
                                            %                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                                            %                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                                            %                 assert(res.ErrCode == 0);
                                            %                 catch
                                            %                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                                            %                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                                            %                 assert(res.ErrCode == 0);
                                            %                 end
                                            
                                            %                 sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                                            %                 res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                                            %                 while (res.ErrCode ~= 0)
                                            %                     sampleRateDAC_str = [':FREQ:RAST ' sprintf('%0.2e', sampleRateDAC)];
                                            %                     res = inst.SendScpi(sampleRateDAC_str); % set sample clock
                                            %                 end
                                            %                 assert(res.ErrCode == 0);
                                            
                                            
                                            
                                            
                                            % Play MW chirp waveform
                                            
                                            % ---------------------------------------------------------------------
                                            % Play segment 1 in channel 1
                                            % ---------------------------------------------------------------------
                                            
                                            res = inst.SendScpi('INST:CHAN 1'); % plays MW out of DAC channel 1
                                            assert(res.ErrCode == 0);
                                            
                                            res = inst.SendScpi(':SOUR:FUNC:MODE:SEG 1');
                                            assert(res.ErrCode == 0);
                                            
                                            amp_str = [':SOUR:VOLT ' sprintf('%0.2f', awg_amp)];
                                            res = inst.SendScpi(amp_str);
                                            assert(res.ErrCode == 0);
                                            
                                            res = inst.SendScpi(':OUTP ON');
                                            assert(res.ErrCode == 0);
                                            
                                            fprintf('Waveform generated and playing\n');
                                            %
                                            %    Disable MW chirp output
                                            %res = inst.SendScpi(':OUTP OFF');
                                            %assert(res.ErrCode == 0);
                                            
                                            %res = inst.SendScpi(':SYST:ERR?');
                                            %fprintf(1, '\nEnd of Example - %s\n', netStrToStr(res.RespStr));
                                            %close all % Close all figures
                                            % It is recommended to disconnect from instrumet at the end
                                            %rc = admin.CloseInstrument(instId);
                                            
                                            % Close the administrator at the end ..
                                            % admin.Close();
                                        end
                                        
                                    end
                                    
                                end

                                       
                                        
                               
                                
 %% SETUP NMR pulse parameters  DM edit 3/14/22 , KAH edit 4/19/22
                                %KAH start of initialization for aquire
                                %The following four vars are all set later
                                %numberOfPulses = 1;
                                %loops = 1;
                                %tacq = 32; % acquisition time as in pulse sequence
                                %readLen = round2((tacq+2)*1e-6/1e-9,96)-96; % must be divisible by 96, 
                                    %number of samples in a given acquisition window
                              
%                                 rc = inst.SetAdcCaptureTrigSource(adcChanInd, trigSource); %adcChenInd here should be index 0 - receives from ADC channel 1
%                                 assert(rc == 0);
% 
%                                 rc = inst.SetAdcExternTrigPattern(0);
%                                 assert(rc==0)
% 
%                                 rc = inst.SetAdcExternTrigGateModeEn(1);
%                                 assert(rc==0);
% 
%                                 rc = inst.SetAdcExternTrigPolarity(1);
%                                 assert(rc==0);
% 
%                                 rc = inst.SetAdcExternTrigThresh(adcChanInd,0.3); % AWG will record anything above 0.3V
%                                 assert(rc==0);
% 
%                                 rc = inst.SetAdcExternTrigDelay(73e-6); % 300 value is 4.1e-6, test for 400 system and re-enter correct val
%                                 assert(rc==0);
% 
%                                 rc = inst.SetAdcAcquisitionEn(1,0);
%                                 assert(rc == 0);
% 
                                 sampleRate = 1000e6;
                                 adcDualChanMode = 1;
                                 fullScaleMilliVolts =1000;
                                 adcChanInd = 0; % ADC Channel 1
                                 trigSource = 1; % 1 = external-trigger
                                 
                                 res = inst.SendScpi(':DIG:MODE DUAL');
                                 assert(res.ErrCode == 0);
                                 
                                 fprintf(strcat([':DIG:FREQ ',num2str(sampleRate), '\n']));
                                 cmd = [':DIG:FREQ ' num2str(sampleRate)];
                                 res = inst.SendScpi(cmd);
                                 assert(res.ErrCode == 0);
                                 
                                 % Enable capturing data from channel 1
                                 %Does this command need to be
                                 %:DIG:CHAN CH1
                                 res = inst.SendScpi(':DIG:CHAN:SEL 1');
                                 assert(res.ErrCode == 0);
                                 res = inst.SendScpi(':DIG:CHAN:STATE ENAB');
                                 % Select internal or external as start-capturing trigger:
                                 %res = inst.SendScpi(':DIG:TRIG:SOURCE CPU');
                                 res = inst.SendScpi(':DIG:TRIG:SOURCE EXT');
                                 assert(res.ErrCode == 0);
                                 
                                 %more external capture commands?
                                 %Set type to edge trigger
                                 res = inst.SendScpi(':DIG:TRIG:TYPE EDGE');
                                 assert(res.ErrCode == 0);
                                 
                                 %Set trigger to falling edge
                                 res = inst.SendScpi(':DIG:TRIG:SLOP NEG');
                                 assert(res.ErrCode == 0);
                                 
                                 %Set trigger threshold to 0.3 V
                                 %Check that LEV1 vs LEV2 is correct and
                                 %that 0.3 is pos/neg
                                 res = inst.SendScpi('DIG:TRIG:LEV1 0.3');
                                 assert(res.ErrCode == 0);
                                 
                                 %Set external trigger delay
                                 %Is this the right command to do this?
                                 res = inst.SendScpi('DIG:TRIG:DEL:EXT 4e-06');
                                 assert(res.ErrCode == 0);
                                 
                                 fprintf('Instrument setup complete and ready to aquire\n');
                                
                                  if length(handles.Array_PSeq{1}.Channels)>=38
                                      
                                      %Sage_write('2,3'); %write to Sage for initializing readout
%                                       Sage_write(2);
                                if handles.Array_PSeq{1}.Channels(38).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    if aux<handles.ExperimentalScan.vary_points(1)
                                        pw=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Frequency;
                                        tacq=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Phase;
                                        %loop_num=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Amplitude;
                                        sequence_type=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).PhaseQ;
                                        gain=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).FreqIQ;
                                    else
                                            pw= 60;
                                            sequence_type=2;
%                                             sequence_type=handles.Array_PSeq{helper_scan,aux}.Channels(38).PhaseQ;
                                            tacq=8;
                                            gain=30;
                                    end

%                                     if sequence_type == 0
%                                         make_pw_nmr(pw,d3,loop_num);
%                                     elseif sequence_type == 1
%                                         make_pw_nmr_2(pw);
                                    if sequence_type == 2  %spin lock sequence type, can uncomment others later
                                       pw_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Frequency;
                                       tacq_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Phase;
                                       gain_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).FreqIQ;
                                       [nc,Tmax]= make_pw_nmr_8(pw_current,tacq_current,gain_current);
                                        pause(0.1);
                                        %for next cycle
                                        make_pw_nmr_8(pw,tacq,gain);
                                        %write data to Sage
%                                        Tmax=Tmax*12*1e-3;
%                                        nc=nc*12;
                                       Tmax=Tmax*2*1e-3;
                                       nc=nc*2;
                                      
                                       %Sage_write(['2,',num2str(pw_current),',',num2str(nc),',',num2str(Tmax),',',num2str(tacq_current)]); %write to Sage for initializing readout
                                       %Insted of sage_write, do following
                                       pw = pw_current*1e-6;
                                       numberOfPulses_total = nc;
                                       tacq = tacq_current;
                                       numberOfPulses= floor(numberOfPulses_total/Tmax); %in 1 second %will be 1 for FID
                                       loops=Tmax;
                                       readLen = round2((tacq+2)*1e-6/1e-9,96)-96; %must be divisible by 96, # of samples in acq window (?)
                                       
                                       netArray = NET.createArray('System.UInt16', readLen*numberOfPulses); %total array -- all memory needed
%                                        rc = inst.SetAdcAcquisitionEn(1,0);
%                                        assert(rc == 0);

%                                        rc = inst.SetAdcFramesLayout(numberOfPulses*loops, readLen); %set memory of the AWG
%                                        assert(rc == 0);
                                       % sets the memory size of Proteus
                                       cmd = [':DIG:ACQuire:FRAM:DEF ' num2str(numberOfPulses*loops) ',' num2str(readLen)];
                                       res = inst.SendScpi(cmd);
                                       assert(res.ErrCode == 0);
                                       
%                                        % Set this to capture all data
%                                        res = inst.SendScpi('DIG:ACQ:CAPT:ALL');
%                                        assert(res.ErrCode == 0);
%                                        % Starts the digitizer to wait for
%                                        % capture
%                                        res = inst.SendScpi(':DIG:INIT ON');
%                                        assert(res.ErrCode == 0);
%                                        % Tells proteus to capture
%                                        % immediately on trig
%                                        res = inst.SendScpi(':DIG:TRIG:IMM');
%                                        assert(res.ErrCode == 0);

                                       fprintf('Waiting for Shuttle\n');
%                                        rc = inst.SetAdcCaptureEnable(1);
%                                        assert(rc == 0);

                                       %disp('writing sage parameters');
%                                           make_pw_nmr_3_rof(pw,d3);
%                                           make_pw_nmr_3_rof(pw,2);
       

%                                     elseif sequence_type == 3
%                                         make_pw_nmr_4(pw);
%                                     elseif sequence_type == 4
%                                         %make_pw_nmr_5(pw,tpwr);
%                                          make_pw_nmr_5(79.4,pw);
%                                     elseif sequence_type == 5
%                                         tof=loop_num;
%                                         make_pw_nmr_6(pw,tof);
%                                     elseif sequence_type == 6
%                                         rof=d3;
%                                         make_pw_nmr_7(pw,rof);
                                        
%                                    Choose this sequence (type 7) for running FID.
%                                     Remember to use make_pw_nmr_9 to
%                                     populate these (initial) values.
%                                     elseif sequence_type == 7
%                                        pw_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Frequency;
%                                        tacq_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Phase;
%                                        gain_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).FreqIQ;
%                                        [nc,Tmax]= make_pw_nmr_9(pw_current,tacq_current,gain_current);
%                                         pause(0.1);
%                                         %for next cycle
%                                         make_pw_nmr_9(pw,tacq,gain);
%                                         %write data to Sage
% %                                        Tmax=Tmax*12*1e-3;
% %                                        nc=nc*12;
%                                        Tmax=tacq;
%                                        nc=1;
%                                       
%                                        Sage_write(['2,',num2str(pw_current),',',num2str(nc),',',num2str(Tmax),',',num2str(tacq_current)]); %write to Sage for initializing readout
%                                        disp('writing sage parameters');
%                                           make_pw_nmr_3_rof(pw,d3);
%                                           make_pw_nmr_3_rof(pw,2);
%                                     elseif sequence_type == 8
%                                        pw_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Frequency;
%                                        tacq_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Phase;
%                                        gain_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).FreqIQ;
%                                        [nc,Tmax]= make_pw_nmr_7(pw_current,tacq_current,gain_current);
%                                         pause(0.1);
%                                         for next cycle
%                                         make_pw_nmr_7(pw,tacq,gain);
%                                         write data to Sage
%                                        Tmax=Tmax*12*1e-3;
%                                        nc=nc*12;
%                                        Tmax=Tmax*192*1e-3;
%                                        nc=nc*192;
%                                       
%                                        Sage_write(['2,',num2str(pw_current),',',num2str(nc),',',num2str(Tmax),',',num2str(tacq_current)]); %write to Sage for initializing readout
%                                        disp('writing sage parameters');
%                                           make_pw_nmr_3_rof(pw,d3);
%                                           make_pw_nmr_3_rof(pw,2);
                                    else
                                        fprintf('Sequence type not accepted\n')
                                    end

                                    pause(0.2);
                                end

                                  end
 %%               case 3,4                   
%                     % Wait to see if AWG is ready to start capturing (?)
%                                   status = inst.ReadAdcCaptureStatus();
%                                   for i = 1 : 250
%                                       if status ~= 0
%                                           break;
%                                       end
%                                       pause(0.01);
%                                       status = inst.ReadAdcCaptureStatus();
%                                   end
%                                   
%                                   rc = inst.SetAdcCaptureEnable(1);
%                                   assert(rc == 0);
%                                   
%                                   rc = inst.ReadAdcCaptureStatus();
%                                   
%                                   %                 % Wait until the capture completes
%                                   %                 status = inst.ReadAdcCompleteFramesCount();
%                                   %                 while status ~= numberOfPulses_total
%                                   %                     pause(0.01);
%                                   %                     status = inst.ReadAdcCompleteFramesCount();
%                                   %                 end
%                                   
%                                   %                 readSize = uint64(readLen);
%                                   %                 readOffset = uint64(offLen);
%                                   
%                                   chanIndex = 0;
%                                   pulseAmp = [];
%                                   relPhase = [];
%                                   
%                                   power_of_2 = floor(log2(readLen)); % this is normally 15 for 32us captures
%                                   padded_len= 2^(power_of_2) ;%2^15;
%                                   dF = sampleRate/padded_len; %set the discretization of freq in terms of sampleRate
%                                   f = -sampleRate/2:dF:sampleRate/2-dF; %sampleRate sets the 'bandwidth'
%                                   
%                                   [v,b1]=min(abs(f-20.00706e6)); %picks out the 20MHz component
%                                   [v,b2]=min(abs(f+20.00706e6));
%                                   
%                                   eff_read=100:readLen-100;
%                                   cyclesPoints = 50;
%                                   fprintf('Shuttle complete\n')
%                                   fprintf('Transfering aquired data to computer....\n')
%                                   for n = 1:loops
%                                       fprintf('Start Read %d .... ', n);
%                                       firstIndex = ((n-1)*numberOfPulses)+1;
%                                       tic
%                                       rc = inst.ReadMultipleAdcFrames(chanIndex, firstIndex, numberOfPulses, netArray); %this is where the device reads
%                                       assert(rc == 0);
%                                       samples = double(netArray); %get the data (1s chunk)
%                                       fprintf('Read %d Complete\n', n);
%                                       toc
%                                       
%                                       tic
%                                       %delete mem
%                                       fprintf('Clear mem %d .... ', n);
%                                       rc =inst.WipeMultipleAdcFrames(chanIndex, ((n-1)*numberOfPulses)+1, numberOfPulses, 0);
%                                       assert(rc == 0);
%                                       fprintf('Clear mem %d Complete\n', n);
%                                       toc
%                                       
%                                       tic
%                                       fprintf('Starting iteration %d data processing....', n);
%                                       pulses = reshape(samples, [], numberOfPulses); % reshape samples into a more useful array (2 dimensions)
%                                       
%                                       if savealldata
%                                           pulsechunk = int16(pulses);
%                                           a = datestr(now,'yyyy-mm-dd-HHMMSS');
%                                           fn = sprintf([a,'_Proteus','_chunk', num2str(n)]);
%                                           % Save data
%                                           fprintf('Writing data to Z:.....\n');
%                                           save(['Z:\' fn],'pulsechunk');
%                                           %writematrix(pulses);
%                                       end
%                                       
%                                       if savesinglechunk
%                                           if  n==1 %determines which chunk will be saved
%                                               pulsechunk = int16(pulses);
%                                               a = datestr(now,'yyyy-mm-dd-HHMMSS');
%                                               fn = sprintf([a,'_Proteus_chunk', num2str(n)]);
%                                               % Save data
%                                               fprintf('Writing data to Z:.....\n');
%                                               save(['Z:\' fn],'pulsechunk');
%                                               %writematrix(pulses);
%                                           end
%                                       end
%                                       
%                                       clear samples;
%                                       for i = 1:numberOfPulses
%                                           pulse = pulses(:, i);
%                                           %                         pulse = pulse(1024:readLen);
%                                           %                         readLen=length(pulse);
%                                           if savemultwind %save multiple consecutive windows of raw data if true
%                                               if n==2 & i<=8
%                                                   pulsechunk = int16(pulse);
%                                                   a = datestr(now,'yyyy-mm-dd-HHMMSS');
%                                                   fn = sprintf([a,'_Proteus_chunk', num2str(n) '_' num2str(i)]);
%                                                   % Save data
%                                                   fprintf('Writing data to Z:.....\n');
%                                                   save(['Z:\' fn],'pulsechunk');
%                                               end
%                                           end
%                                           
%                                           %                         if n == 1
%                                           %                             if i == 1
%                                           %                                 figure(2);clf;
%                                           %                                 plot(pulse);
%                                           %                                 figure(3);clf;
%                                           %                                 bandwidth=1/2/1e-9;
%                                           %                                 Ttot=readLen*1e-9;
%                                           %                                 F=linspace(-bandwidth,bandwidth,readLen);
%                                           %                                 plot(F,abs(fftshift(fft(pulse))));
%                                           %                                 hold on;
%                                           %                                 yline(2048);
%                                           %                             end
%                                           %                         end
%                                           if n == 1
%                                               if i == 2
%                                                   figure(4);clf;
%                                                   plot(pulse);
%                                                   %                                 figure(5);clf;
%                                                   %                                 plot(F,abs(fftshift(fft(pulse))));
%                                                   %                                 hold on;
%                                                   %                                 yline(2048);
%                                               end
%                                           end
%                                           %                         if n == 1
%                                           %                             if i == 3
%                                           %                                 figure(6);clf;
%                                           %                                 plot(pulse);
%                                           %                                 figure(7);clf;
%                                           %                                 plot(F,abs(fftshift(fft(pulse))));
%                                           %                                 hold on;
%                                           %                                 yline(2048);
%                                           %                             end
%                                           %                         end
%                                           % %                         pulse(1:41800)=[];
%                                           pulseMean = mean(pulse);
%                                           pulseDC = pulse - pulseMean; % remove DC
%                                           X = fftshift(fft(pulseDC,padded_len)); % perform FFT and zero-pad to the padded_len
%                                           linFFT = (abs(X)/readLen);
%                                           %                         [amp, loc] = max(linFFT);
%                                           amp=(linFFT(b1) + linFFT(b2));
%                                           phase1=angle(X(b1));
%                                           phase2=angle(X(b2));
%                                           phase=phase1-phase2;
%                                           %             linFFT_vec(:,i)=linFFT;
%                                           pulseAmp(i+(numberOfPulses*(n-1))) = amp;
%                                           relPhase(i+(numberOfPulses*(n-1))) = phase1;
%                                       end
%                                       %                     if n == 1
%                                       %                         figure(8);clf;
%                                       %                         plot(pulse);
%                                       %                         hold on;
%                                       %                         yline(2048);
%                                       %                     end
%                                       clear pulses;
%                                       fprintf('Data processing iteration %d complete!\n', n);
%                                       toc
%                                   end
%                                   
%                                   %ivec=1:numberOfPulses*loops;
%                                   ivec=1:length(pulseAmp);
%                                   delay2 = 0.000003; % dead time the unknown one, this is actually rof3 -Ozgur
%                                   
%                                   %time_cycle=pw+96+(tacq+2+4+2+delay2)*1e-6;
%                                   time_cycle=pw+delay2+(tacq+2+4+2)*1e-6
%                                   %time_cycle=pw+extraDelay+(4+2+2+tacq+17)*1e-6;
%                                   time_axis=time_cycle.*ivec;
%                                   %drop first point
%                                   time_axis(1)=[];pulseAmp(1)=[];relPhase(1)=[];
%                                   try
%                                       figure(1);clf;
%                                       %                plot(time_axis,(pulseAmp),'b-');hold on;
%                                       plot(time_axis,pulseAmp,'r-');
%                                       %plot(1:1:length(pulseAmp),pulseAmp,'r-');
%                                       set(gca,'ylim',[0 max(pulseAmp)*1.1]);
%                                       
%                                       figure(12);clf;
%                                       plot(time_axis,relPhase);
%                                       %plot(1:1:length(relPhase),relPhase);
%                                       
%                                       %                 figure(3);clf;
%                                       %                 plot(pulse);
%                                       %                 hold on;
%                                       %                 yline(2048);
%                                   catch
%                                       disp('Plot error occured');
%                                   end
%                                   
%                                   %fn=dataBytes; %filename
%                                   a = datestr(now,'yyyy-mm-dd-HHMMSS');
%                                   fn = sprintf([a,'_Proteus']);
%                                   % Save data
%                                   fprintf('Writing data to Z:.....\n');
%                                   save(['Z:\' fn],'pulseAmp','time_axis','relPhase');
%                                   fprintf('Save complete\n');
%                                   
%                                   case 4 % Cleanup, save and prepare for next experiment
%                                       
%                                       rc = inst.SetAdcCaptureEnable(off);
%                                       assert(rc == 0);
%                                       % Free the memory space that was allocated for ADC capture
%                                       rc = inst.FreeAdcReservedSpace();
%                                       assert(rc == 0);
%                                       
%                                       %                 clear pulseAmp time_axis;
%                                       fprintf('Complete ready for next aquisition!\n');
                                %% SETUP Helmholtz Coil
                                if length(handles.Array_PSeq{1}.Channels)>=34
                                if handles.Array_PSeq{1}.Channels(34).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                             helmholtz_current=handles.Array_PSeq{helper_scan,aux}.Channels(34).Frequency;
                                obj.psu.PS_CurrSet(abs(helmholtz_current));
                                obj.psu.PS_OUTOff();
    %                              obj.psu.PS_OUTOn();
                                end
                                end

                                pause(0.5);%added
                                %Loop over repetitions
                                for rep_count=1:1:Repetitions
                                    disp(['... Running repitition number:' num2str(rep_count)])
                                    %pause(rep_count*2);
    %                                 pause(120);
    
                                    

                                    %% TURN ON HELMHOLTZ
                                    if length(handles.Array_PSeq{1}.Channels)>=34 && ~(length(handles.Array_PSeq{1}.Channels)==35) &&  handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==0
                                        if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
                                            obj.psu.PS_OUTOn();
                                            % obj.psu.PS_OUTOff();
                                        end
                                    end


                                      %% TURN ON TABOR AWG and SRS
                                      if length(handles.Array_PSeq{1}.Channels)>=39
                                          if handles.Array_PSeq{1}.Channels(39).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                              %obj.srs.set_MWon();
                                              %obj.tabor.awg_start();
                                          end
                                      end

                                 
                                    %%EXTRA PAUSE
                                    pause(0.5);

                                if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1

                                   obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7); obj.com.StopBuffer(6); obj.com.StopBuffer(9);
                                    obj.com.KillAll();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                    if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                        if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
                                            obj.psu.PS_OUTOff();
                                        end
                                    
                                    end
                                    %obj.mw.MW_Close();
                                    break;
                                else 
    %                                 if aux>1 && rep_count>1
    %                                     pause(1); %recycle delay
    %                                 end
                               %% Initialize acutator position for very first motion
                               if handles.Array_PSeq{1}.Channels(12).Enable && rep_count ==1 && aux==1 && ~isempty(handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency)
                                    start_pos=obj.com.GetFPosition(obj.com.ACSC_AXIS_0);
                                     Position=handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency;
                                     obj.com.SetVelocity(obj.com.ACSC_AXIS_0,50);
                                     obj.com.SetAcceleration(obj.com.ACSC_AXIS_0,500);
                                     obj.com.SetDeceleration(obj.com.ACSC_AXIS_0,500);
                                     obj.com.SetJerk(obj.com.ACSC_AXIS_0,5000);

                                     obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0, -Position); %MOVE
                                     obj.com.Go(obj.com.ACSC_AXIS_0);
                                     displacement=abs(abs(start_pos)-abs(Position));
                                     if displacement>2
                                      obj.com.WaitMotionEnd (obj.com.ACSC_AXIS_0, 1000*10*displacement/50);
                                     else
                                       %obj.com.WaitMotionEnd (obj.com.ACSC_AXIS_0, 5000);  
                                     end
                               end


                                %%% SET actuator position
                                %Actuator wait time and pos for T1(B) experiments
                                if handles.Array_PSeq{1}.Channels(12).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted

                                    waitpos = handles.Array_PSeq{helper_scan,aux}.Channels(24).Frequency;
                                    postime = handles.Array_PSeq{helper_scan,aux}.Channels(24).Phase;
                                elseif handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    waitpos = handles.Array_PSeq{helper_scan,aux}.Channels(9).Frequency; %change back to 9 for not T1
                                    postime = handles.Array_PSeq{helper_scan,aux}.Channels(9).Phase; %change back to 9 for not T1
                                end

                                
                               
                                
                                if handles.Array_PSeq{1}.Channels(12).Enable
                                    if ~isempty(handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency)
                                        Position=handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency;
                                        Velocity=handles.Array_PSeq{helper_scan,aux}.Channels(12).Amplitude;
                                        Accn=handles.Array_PSeq{helper_scan,aux}.Channels(12).Phase;
                                        Jerk=handles.Array_PSeq{helper_scan,aux}.Channels(12).AmpIQ;
                                        c_position=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqIQ;
                                        Wait_time=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqmodQ;
                                        tt2=handles.Array_PSeq{helper_scan,aux}.Channels(10).Frequency;
                                        delta_time=handles.Array_PSeq{helper_scan,aux}.Channels(8).Frequency;


                                        %% Used for acquistion delay
    %                                     if handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                     acq_time=handles.Array_PSeq{helper_scan,aux}.Channels(9).Frequency;
    %                                     end

                                        obj.com.SetVelocity(obj.com.ACSC_AXIS_0,Velocity);
                                        obj.com.SetAcceleration(obj.com.ACSC_AXIS_0,Accn);
                                        obj.com.SetDeceleration(obj.com.ACSC_AXIS_0,Accn);
                                        obj.com.SetJerk(obj.com.ACSC_AXIS_0,Jerk);

                                        %this line for having sample wait at
                                        %bottom position before moving up
    %                                    obj.com.WriteVariable(Wait_time*1e3+tt2, 'V1', obj.com.ACSC_NONE);%need to do 1e3 because ACS times are in ms
                                        %normal 
                                       obj.com.WriteVariable(Wait_time*1e3, 'V1', obj.com.ACSC_NONE); %need to do 1e3 because ACS times are in ms
                                       obj.com.WriteVariable(-Position, 'V0', obj.com.ACSC_NONE);


    %                                    if 6.Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                      obj.com.WriteVariable(top_time*1e3, 'V91', obj.com.ACSC_NONE); %need to do 1e3 because ACS times are in ms
    %                                      obj.com.WriteVariable(loop_time*1e3, 'V92', obj.com.ACSC_NONE); %need to do 1e3 because ACS times are in ms
    %                                     end
    %                                     
                                        %top position after moving up
                                        %obj.com.WriteVariable(tt2, 'V91', obj.com.ACSC_NONE);



                                        %For T1 time experiments only
    %                                     if handles.Array_PSeq{1}.Channels(24).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                         obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-waitpos);   %go up to coil position %wait position instead?
    %                                         obj.com.WriteVariable(postime*1e3,'V2', obj.com.ACSC_NONE);
    %                                         obj.com.RunBuffer(3); 


                                       % For 2 shuttles only                                
                                        if handles.Array_PSeq{1}.Channels(8).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                        obj.com.WriteVariable(delta_time*1e3, 'V8', obj.com.ACSC_NONE);
                                            obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);   %go up to coil position. won't start until fire 'GO'
                                            obj.com.RunBuffer(5); 
                                        % For T1(B) experiment
%                                         elseif handles.Array_PSeq{1}.Channels(24).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                             obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-waitpos);   %go up to coil position %wait position instead?
%                                             obj.com.WriteVariable(postime*1e3,'V2', obj.com.ACSC_NONE);
%                                             obj.com.RunBuffer(3); 
    %                                    % For Pyruvic Acid Sample, UNCOMMENT
    %                                     elseif handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %             
    %                                         obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);
    %                                         %go to wait position
    % %                                         obj.com.WriteVariable(postime*1e3,'V1', obj.com.ACSC_NONE);
    %                                         obj.com.RunBuffer(2);

                                        % For acq delay experiments
    %                                     elseif handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                         obj.com.WriteVariable(acq_time*1e3,'V2', obj.com.ACSC_NONE);
    %                                         obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);   %go up to coil position
    %                                         obj.com.RunBuffer(6);
                                        % For acq delay at pos 617 7T T1(B)experiments
%                                         elseif handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                             obj.com.WriteVariable(postime*1e3,'V2', obj.com.ACSC_NONE);
%                                             obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);   %go up to coil position
%                                             obj.com.RunBuffer(6);
                                       %Thermal Channel 35 script:
                                       %test_pines_powder_thermal_master.xml
                                        elseif length(handles.Array_PSeq{1}.Channels) == 35
                                            if handles.Array_PSeq{1}.Channels(35).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                             obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);   %go up to coil position
                                                obj.com.RunBuffer(7);
                                            end
                                       %MULTI-LASER shuttle
                                        elseif length(handles.Array_PSeq{1}.Channels) > 12 %&& length(handles.Array_PSeq{1}.Channels) ~= 40 
                                            if handles.Array_PSeq{1}.Channels(12).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                                %obj.com.WriteVariable(postime,'V2', obj.com.ACSC_NONE);
                                                obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);  %go up to coil position
                                                obj.com.RunBuffer(1);
%                                                 obj.com.RunBuffer(9);
                                            end
                                            %THERMAL
                                        elseif length(handles.Array_PSeq{1}.Channels) == 40
                                            if handles.Array_PSeq{1}.Channels(40).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                                obj.com.RunBuffer(9);
                                            end
                                        else
                                            obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);   %go up to coil position
                                            obj.com.RunBuffer(1);
                                        end
                                end
                                end
                             


                                %%%% Main sequence                  
                                if ~err & ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    [stPB,durPB,err] = obj.ListOfStatesAndDurationsPB(handles.Array_PSeq{helper_scan,aux},handles);
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.sendSequence(stPB,durPB,1);
                                    %%%%%%%%%%% add for new PB  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart();
                                end


                                if err
                                    handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted = 1;
                                    break;
                                end

                                if err_latency==1
                                   break;
                                end


                                % END Load Sequence %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                                % Experiment routine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                                   obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);

                                    obj.com.KillAll();
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%% add for new PB
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();

                                    % turn OFF AWG and SRS (also occurs
                                    % later ~line 1100)
%                                     if length(handles.Array_PSeq{1}.Channels)>=39 && ~length(handles.Array_PSeq{1}.Channels)==39
%                                         if handles.Array_PSeq{1}.Channels(39).Enable 
%                                             obj.srs.set_MWoff();
%                                             obj.tabor.awg_stop();
%                                         end
%                                     end

                                    if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                        if handles.Array_PSeq{1}.Channels(34).Enable
                                            obj.psu.PS_OUTOff();
                                        end
                             
                                    end
    %                                 break;
                                else 
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart(); %will fire one single sequence Repetitions number of times
                                    %handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();

                                    %%%% NO NEED PAUSE FOR NEW PB %%%%%%%%%%%%
                                    if handles.Array_PSeq{1}.Channels(12).Enable % For motion
                                        Position=handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency;
                                        Velocity=handles.Array_PSeq{helper_scan,aux}.Channels(12).Amplitude;
                                        c_position=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqIQ;
                                        Wait_time=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqmodQ;

                                        %THIS IS THE ORIGINAL LINE
                                        if handles.Array_PSeq{1}.Channels(8).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                            pause(1.03*sum(durPB)+4*abs(abs(Position)-abs(c_position))/Velocity+30+tt2/1000); %3 sec between reps
                                        else    
                                            total_delay = 1.03*sum(durPB)+2*abs(abs(Position)-abs(c_position))/Velocity+3+30+tt2/1000;
                                            pause(1.03*Wait_time);
                                            if length(handles.Array_PSeq{1}.Channels)>=34
                                                if handles.Array_PSeq{1}.Channels(34).Enable
                                                    obj.psu.PS_OUTOff();
                                                end
                                            end     
                                            pause(total_delay-1.03*Wait_time); %3 sec between reps
                                        end

                                        %READ data from Sage and save
%                                         add this pause for measuring T1:
%                                         pause(postime*1e-3);
                                       % Sage_write('3');
                                       
                                       %KAH 4/19/22 insert case 3
                                       % Wait to see if AWG is ready to start capturing (?)
%                                        status = inst.ReadAdcCaptureStatus();
%                                        for i = 1 : 250
%                                            if status ~= 0
%                                                break;
%                                            end
%                                            pause(0.01);
%                                            status = inst.ReadAdcCaptureStatus();
%                                        end
% %                                        
%                                        rc = inst.SetAdcCaptureEnable(1);
%                                        assert(rc == 0);
% 
%                                        rc = inst.ReadAdcCaptureStatus();
                                       %assert(rc == 0);

%                                         disp('Press a key !')    
%                                         pause;

                                       % Set this to capture all data
                                       res = inst.SendScpi('DIG:ACQ:CAPT:ALL');
                                       assert(res.ErrCode == 0);
                                       % Starts the digitizer to wait for
                                       % capture
                                       res = inst.SendScpi(':DIG:INIT ON');
                                       assert(res.ErrCode == 0);
                                       % Tells proteus to capture
                                       % immediately on trig
                                       res = inst.SendScpi(':DIG:TRIG:IMM');
                                       assert(res.ErrCode == 0);
                                       % Turn proteus acquisition off
                                       % before sending data to computer
                                       res = inst.SendScpi(':DIG:INIT OFF');
                                       assert(res.ErrCode == 0);
                                       
                                       % Choose what to read 
                                       % (only the frame-data without the header in this example)
                                       res = inst.SendScpi(':DIG:DATA:TYPE FRAM');
                                       assert(res.ErrCode == 0);

                                       fprintf('Transfering acquired data to computer....\n')

                                        for n = 1:loops
                                            fprintf('Start Read %d .... ', n);
                                            firstIndex = ((n-1)*numberOfPulses)+1;
                                            tic
                                            % Select frames starting at
                                            % next index
                                            cmd = [':DIG:DATA:SEL ' num2str(firstIndex) ',' num2str(numberOfPulses)];
                                            res = inst.SendScpi(cmd);
                                            assert(res.ErrCode == 0);
                                            
                                            rc = inst.ReadMultipleAdcFrames(adcChanInd, firstIndex, numberOfPulses, netArray); %this is where the device reads
                                            assert(rc == 0);
                                            samples = double(netArray); %get the data 
                                            fprintf('Read %d Complete\n', n);
                                            toc

                                            tic
                                            %delete mem
                                            fprintf('Clear mem %d .... ', n);
                                            rc =inst.WipeMultipleAdcFrames(adcChanInd, firstIndex, numberOfPulses, 0);
                                            assert(rc == 0);
                                            fprintf('Clear mem %d Complete\n', n);
                                            toc
                                            
                                            tic
                                            fprintf('Starting iteration %d data processing....', n);
                                            pulses = reshape(samples, [], numberOfPulses); % reshape samples into a more useful array (2 dimensions)
                                            clear samples;
                                            
                                            pulseAmp = [];
                                            relPhase = [];

                                            power_of_2 = floor(log2(readLen)); % this is normally 15 for 32us captures
                                            padded_len= 2^(power_of_2) ;%2^15;
                                            dF = sampleRate/padded_len; %set the discretization of freq in terms of sampleRate
                                            f = -sampleRate/2:dF:sampleRate/2-dF; %sampleRate sets the 'bandwidth'

                                            [v,b1]=min(abs(f-20.00706e6)); %picks out the 20MHz component
                                            [v,b2]=min(abs(f+20.00706e6));

                                            eff_read=100:readLen-100;
                                            cyclesPoints = 50;
                                            
                                            for i = 1:numberOfPulses
                                                 pulse = pulses(:, i);
                                                 if n == 1
                                                    if i == 2
                                                        figure(4);clf;
                                                        plot(pulse);
                                                    end
                                                 end
                                                pulseMean = mean(pulse);
                                                pulseDC = pulse - pulseMean; % remove DC
                                                X = fftshift(fft(pulseDC,padded_len)); % perform FFT and zero-pad to the padded_len
                                                linFFT = (abs(X)/readLen);
                                                amp=(linFFT(b1) + linFFT(b2));
                                                phase1=angle(X(b1));
                                                phase2=angle(X(b2));
                                                %phase=phase1-phase2; %why does this exist?
                                                pulseAmp(i+(numberOfPulses*(n-1))) = amp;
                                                relPhase(i+(numberOfPulses*(n-1))) = phase1;
                                            end
                                            clear pulses;
                                            fprintf('Data processing iteration %d complete!\n', n);
                                            toc
                                        end
                                        
                                        ivec=1:length(pulseAmp);
                                        delay2 = 0.000003; % dead time the unknown one, this is actually rof3 -Ozgur aka this is probably something we have to change?
                                        time_cycle = pw+delay2+(tacq+2+4+2)*1e-6 %this may be set differently as we plan to trigger on falling edge, time to do a pulse-acquire
                                        time_axis=time_cycle.*ivec;
                                        %drop first point
                                        time_axis(1)=[];pulseAmp(1)=[];relPhase(1)=[]; %why only drop the first point? why drop it at all?
                                        try
                                            figure(1);clf;
                                             plot(time_axis,pulseAmp,'r-');
                                            set(gca,'ylim',[0 max(pulseAmp)*1.1]);
                                            figure(12);clf;
                                             plot(time_axis,relPhase);
                                        catch
                                            disp('Plot error occured');
                                        end
                                        a = datestr(now,'yyyy-mm-dd-HHMMSS');
                                        fn = sprintf([a,'_Proteus']);
                                        % Save data
                                        fprintf('Writing data to Quantum Stream:.....\n');
                                        %save(['Z:\' fn],'pulseAmp','time_axis','relPhase'); %this doesn't work yet
                                        fprintf('Save complete\n');
                                        
                                        % Cleanup, save and prepare for next experiment
                                        rc = inst.SetAdcCaptureEnable(0);
                                        assert(rc == 0);
                                        % Free the memory space that was allocated for ADC capture
                                        rc = inst.FreeAdcReservedSpace();
                                        assert(rc == 0);
                                        fprintf('Complete ready for next aquisition!\n');
                                        
                                        %KAH edit end case 3/4

                                        %for relay expts/T1(B)
                                        %pause(40); %40 sec laser pumping

                                        %Original Line
                                        % Turn off/on Helhmholtz PSU 1
                                        if length(handles.Array_PSeq{1}.Channels)>=34
                                        if handles.Array_PSeq{1}.Channels(34).Enable
                                        obj.psu.PS_OUTOff();
                                        %obj.psu.PS_OUTOn();
                                        end

                                        end

                                    
                                         % Turn OFF AWG and SRS
                                         if length(handles.Array_PSeq{1}.Channels)>=39
                                             if handles.Array_PSeq{1}.Channels(39).Enable
                                                 res = inst.SendScpi(':OUTP OFF');
                                                 assert(res.ErrCode == 0);
                                                 rc = admin.CloseInstrument(instId);
                                                 admin.Close();
                                                      fprintf(1, 'END\n');
                                             end
                                         end
                                        pause(2);
                                    else
                                         pause(abs(1.1*sum(durPB)));
                                    end


                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%important%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                                 waitfor(handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop())
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                                end

                                if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                                    obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7); obj.com.StopBuffer(6);
                                     obj.com.KillAll();
                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                     break;
                                end                            
                                end

                                      
                                %% Turn off Helhmholtz
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
                                obj.psu.PS_OUTOff();
                                end
                                end 

%                                 Turn OFF AWG and SRS
%                                 if length(handles.Array_PSeq{1}.Channels)>=39
%                                     if handles.Array_PSeq{1}.Channels(39).Enable
%                                          obj.srs.set_MWoff();
%                                          obj.tabor.awg_stop();
%                                     end
%                                 end
                                
                        
                            if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                               obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);
                                obj.com.KillAll();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                    if handles.Array_PSeq{1}.Channels(34).Enable
                                        obj.psu.PS_OUTOff();
                                    end
                                end
                                break;
                            end
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
                          %Sage_write('4');
                          
%                           pause(60);

                                end

                            if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                               obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);
                                obj.com.KillAll();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                    if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
                                        obj.psu.PS_OUTOff();
                                    end
                                    if handles.Array_PSeq{1}.Channels(21).Enable 
                                        obj.arb2.MW_RFOff();
                                    end
                                     if handles.Array_PSeq{1}.Channels(22).Enable 
                                            obj.arb3.MW_RFOff();
                                    end
                                    if length(handles.Array_PSeq{1}.Channels)>=37 && handles.Array_PSeq{1}.Channels(37).Enable
                                            obj.psu2.PS_OUTOff();
                                    end
                                end
                                break;
                            end
                            end

                         if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted~=1

%                              disp(['Wait time for Experiment No.' num2str(aux) ': ' num2str(Wait_time)]);
                             %pause(300);
                         end


                         %% Saving log of dc_level and Vpp and freq range


                        pause(0.5);
                        fprintf('waiting for shuttler to finish moving \n');
                        pause(420);
                        serialObj = instrfind;
                        s=size(serialObj);
                        for i=1:s(1,2)
                            if strcmp(serialObj(i).Status,'closed')
                                delete(serialObj(i));
                            end
                        end



                        %aux = aux +1;

                        end %END loop over first scan dimension end aux
                        catch err_aux_loop
                            disp('Failure in main loop ... turning off power supplies, displaying error below:')
                            fprintf(2,'The error message was: \n%s \n',err_aux_loop.message);
                        end
                        %% Close matching saving file
%                       fclose(fmatch);
                 end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             end % end loop Averages

%                  
            profile off
            %obj.mw.MW_Close();
            handles.ExperimentFinished=1;
            
            %% PAUSE FOR SLOW DOWN!!!
%            pause(30);
       
        end
                 
        function AbortRun(obj,handles)
            
            obj.com.KillAll();
           obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6)
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();

            
            handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted = 1;
            handles.Tracker.hasAborted=1;
            
        end
        
        %%%%% Sequencing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
       
        function [err] = LoadSequenceToExperimentPB(obj,PS,rep,handles)
            
            [stPB,durPB,err] = obj.ListOfStatesAndDurationsPB(PS,handles);
            if ~err
                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.sendSequence(stPB,durPB,rep);
            else
                return;
            end
            
        end
       
        %%%%% Results handling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function UpdateAvgDataPlot(obj,handles,is_first)
            
            cla(handles.axes_AvgData);
            colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
             if isfield(handles,'scan_nonlinear') && handles.scan_nonlinear==1
                x=handles.nonlinear_data.x;
            else    
                x = linspace(handles.ExperimentalScan.vary_begin(1),handles.ExperimentalScan.vary_end(1),handles.ExperimentalScan.vary_points(1));
             end
            
            for j=1:1:length(obj.AvgData)
                y = obj.AvgData{j};
                hold(handles.axes_AvgData,'on');
                line(j)=plot(x,y,['.-' colors(j)],'Parent',handles.axes_AvgData,'MarkerSize',15,'LineWidth',0.5);
                hold(handles.axes_AvgData,'on');
                plot(x,smooth(y),['-' colors(j)],'Parent',handles.axes_AvgData,'LineWidth',1.5);
                
                title(handles.axes_AvgData,datestr(now,'yyyy-mm-dd-HHMMSS'));
                if get(handles.checkbox_errorbar,'Value')
                    errorbar(x, y, obj.Std_dev{j}, '.','Parent',handles.axes_AvgData)
                end
            end
             grid(handles.axes_AvgData, 'on');
            hold(handles.axes_AvgData,'off');
            
            if is_first == 1
                
                a = {'Rise 1', 'Rise 2', 'Rise 3', 'Rise 4', 'Rise 5', 'Rise 6'};
                legend(handles.axes_AvgData,line,a(1:1:length(obj.AvgData)));
                xlabel(handles.axes_AvgData,handles.ExperimentalScan.vary_prop{1});
                ylabel(handles.axes_AvgData,'kcps');
                title(handles.axes_AvgData,datestr(now,'yyyy-mm-dd-HHMMSS'));
            end
            grid(handles.axes_AvgData, 'on');
            drawnow();
            
        end
        
        
         function PinesDataPlot(obj,handles,is_first)
            
            cla(handles.axes_AvgData); %clear axis
            colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
            x = linspace(handles.ExperimentalScan.vary_begin(1),handles.ExperimentalScan.vary_end(1),handles.ExperimentalScan.vary_points(1));
            set(handles.axes_AvgData,'xlim',[min(x) max(x)]);
           diff_x=diff(x);
           delta_x=diff_x(1);
            for j=1:1:length(obj.AvgData)
                y = obj.AvgData{j};
                hold(handles.axes_AvgData,'on');
                line(1)=plot(x(1:2:end)+delta_x,y(1:2:end),['.-' colors(1)],'Parent',handles.axes_AvgData,'MarkerSize',15,'LineWidth',0.5);
                line(2)=plot(x(2:2:end),y(2:2:end),['.-' colors(2)],'Parent',handles.axes_AvgData,'MarkerSize',15,'LineWidth',0.5);
            end
             grid(handles.axes_AvgData, 'on');
            hold(handles.axes_AvgData,'off');
            
            if is_first == 1
                
                a = {'Rise 1', 'Rise 2', 'Rise 3', 'Rise 4', 'Rise 5', 'Rise 6'};
                legend(handles.axes_AvgData,line,a(1:1:length(obj.AvgData)));
                xlabel(handles.axes_AvgData,handles.ExperimentalScan.vary_prop{1});
                ylabel(handles.axes_AvgData,'kcps');
                title(handles.axes_AvgData,datestr(now,'yyyy-mm-dd-HHMMSS'));
            end
            grid(handles.axes_AvgData, 'on');
            drawnow();
            
        end
        
        
        function UpdateSingleDataPlot(obj,handles,is_first)
            
            cla(handles.axes_RawData);
            colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
            if isfield(handles,'scan_nonlinear') && handles.scan_nonlinear==1
                x=handles.nonlinear_data.x;
            else    
                x = linspace(handles.ExperimentalScan.vary_begin(1),handles.ExperimentalScan.vary_end(1),handles.ExperimentalScan.vary_points(1));
            end
            for j=1:1:length(obj.RawData)
                y = obj.RawData{j};
                hold(handles.axes_RawData,'on');
                plot(x,y,['.-' colors(j)],'Parent',handles.axes_RawData);
                title(handles.axes_AvgData,datestr(now,'yyyy-mm-dd-HHMMSS'));
            end
            hold(handles.axes_RawData,'off');
            
            if is_first == 1
                a = {'Rise 1', 'Rise 2', 'Rise 3', 'Rise 4', 'Rise 5', 'Rise 6'};
                legend(handles.axes_RawData,a(1:1:length(obj.RawData)));
                xlabel(handles.axes_AvgData,{handles.ExperimentalScan.vary_prop{1}});
                ylabel(handles.axes_AvgData,'kcps');
                title(handles.axes_AvgData,datestr(now,'yyyy-mm-dd-HHMMSS'));
            end
            grid(handles.axes_AvgData,'on');
            drawnow();
            
        end
        
        function LoadExpFromScan(obj,handles)
               
            
            
            set(handles.sliderExpScan,'Visible','off');
            set(handles.text_vary2_param,'Visible','off');
            set(handles.slider_each_avg,'Visible','off');
            set(handles.avg_nb,'Visible','off');    
            exps = get(handles.popup_experiments,'String');
            selectedExp= exps{get(handles.popup_experiments,'Value')};
            
            if length(exps)>1
               
                fp = getpref('nv','SavedExpDirectory');
                if strcmp(selectedExp,'Current Experiment')
                    selectedExp= exps{get(handles.popup_experiments,'Value')+1}; %loads the first exp in the list, that corresponds to the displayed 'Current Experiment'
                end
                
                SavedExp = load(fullfile(fp,selectedExp));
                
                
                handles.ExperimentalScanDisplayed = SavedExp.Scan;
                set(handles.edit_NoteExp, 'String', handles.ExperimentalScanDisplayed.Notes)
                set(handles.edit_NoteExp,'Enable','on');
                set(handles.button_NoteExp,'Enable','on');
                
                if length(handles.ExperimentalScanDisplayed.vary_points) == 2 %2d scan
                    set(handles.sliderExpScan,'Visible','on');
                    set(handles.text_vary2_param,'Visible','on');
                    set(handles.sliderExpScan,'Max', handles.ExperimentalScanDisplayed.vary_points(2));
                    set(handles.sliderExpScan,'Min', 1);
                    set(handles.sliderExpScan,'Value', 1);
                    set(handles.text_vary2_param,'String',sprintf('%s = %s',handles.ExperimentalScanDisplayed.vary_prop{2},num2str(handles.ExperimentalScanDisplayed.vary_begin(2))));
                end
                
                if ~isempty(handles.ExperimentalScanDisplayed.scan_nonlinear) 
                    if handles.ExperimentalScanDisplayed.scan_nonlinear~=0
                    handles.scan_nonlinear=handles.ExperimentalScanDisplayed.scan_nonlinear;
                    handles.nonlinear_data=handles.ExperimentalScanDisplayed.nonlinear_data;
                    set(handles.checkbox18,'Value',1);
                    else
                        set(handles.checkbox18,'Value',0);
                    
                    end
                
                    
                end
                
                
                set(handles.uipanel90,'Visible','on');
                
                set(handles.text_scan_avg, 'String', handles.ExperimentalScanDisplayed.Averages);
                set(handles.text_scan_reps, 'String', handles.ExperimentalScanDisplayed.Repetitions);
                set(handles.text_sequence,'String',handles.ExperimentalScanDisplayed.Sequence);
                set(handles.displayed_power,'String',sprintf('Power = %0.3f +- %0.3f mW',handles.ExperimentalScanDisplayed.Laserpower(1),handles.ExperimentalScanDisplayed.Laserpower(2)));
                set(handles.text_name_displayed_seq,'String',handles.ExperimentalScanDisplayed.SequenceName);
                
               
                obj.ExpPlot(handles,handles.ExperimentalScanDisplayed,1);
                obj.EachAvgPlot(handles,handles.ExperimentalScanDisplayed,1,1);
                
                
                %load veriable data to table_show_float
                a = size(handles.ExperimentalScanDisplayed.Variable_values);
                tabledata = cell(a(2), 6);
                
                for p=1:1:a(2)  %number of lines in matrix
                    tabledata{p,1} = handles.ExperimentalScanDisplayed.Variable_values{p}.name;
                    
                    %needs something here to display correctly
                    if length(handles.ExperimentalScanDisplayed.vary_prop) == 2
                        j_end = 2;
                    else
                        j_end = 1;
                    end
                    
                    
                    for j=1:1:j_end
                        if strcmp(handles.ExperimentalScanDisplayed.Variable_values{p}.name, handles.ExperimentalScanDisplayed.vary_prop{j})
                            tabledata{p,3} = true;
                            tabledata{p,4} = handles.ExperimentalScanDisplayed.vary_begin(j);
                            tabledata{p,5} = handles.ExperimentalScanDisplayed.vary_step_size(j);
                            tabledata{p,6} = handles.ExperimentalScanDisplayed.vary_end(j);
                        else
                            tabledata{p,2} = handles.ExperimentalScanDisplayed.Variable_values{p}.value;
                        end
                    end
                end
                
                set(handles.table_show_float,'data',tabledata);
                
                %load variable data to table_show_float
                a = size(handles.ExperimentalScanDisplayed.Bool_values);
                
                if a(2) ~= 0
                    tabledata = cell(a(2), 2);
                    for p=1:1:a(2)  %number of lines in matrix
                        tabledata{p,2} = handles.ExperimentalScanDisplayed.Bool_values{p}.name;
                        if handles.ExperimentalScanDisplayed.Bool_values{p}.value
                            tabledata{p,1} = true;
                        else
                            tabledata{p,1} = false;
                        end
                    end
                    
                    set(handles.table_show_bool,'data',tabledata);
                    
                end
                
                set(handles.button_NoteExp, 'Enable','on');
                set(handles.edit_NoteExp, 'Enable','on');
                
                %plot single averages
                if handles.ExperimentalScanDisplayed.Averages > 1
                set(handles.slider_each_avg,'Max', handles.ExperimentalScanDisplayed.Averages);
                set(handles.slider_each_avg,'Min', 1);
                set(handles.slider_each_avg,'Value', 1);
                set(handles.avg_nb,'String','1');
                set(handles.slider_each_avg,'Visible','on');
                set(handles.avg_nb,'Visible','on');    
                end
                
            
                % Update handles structure
                gobj = findall(0, 'Name', 'Experiment');
                guidata(gobj, handles);
                
            end
            
        end
        
    end
    
    methods (Static)
        
        function UpdateExpScanList(handles)
            
            fp = getpref('nv','SavedExpDirectory');
            files = dir(fp);
            
            datenums = [];
            found_filenames = {};
            % sort files by modifying date desc
            for k=1:length(files)
                % takes the date from the filename
                r = regexp(files(k).name, '(\d{4}-\d{2}-\d{2}-\d{6})','tokens');
                if ~isempty(r) %remove dirs '.' and '..', and other files
                    datenums(end+1) = datenum(r{1}, 'yyyy-mm-dd-HHMMSS');
                    found_filenames{end+1} = files(k).name;
                end
                
            end
            if ~isempty(datenums)
                [~,dind] = sort(datenums,'descend');
            end;
            
            fn{1} = 'Current Experiment';
            
            for k=1:length(datenums),
                
                
                fn{end+1} = found_filenames{dind(k)};
                
                
            end
            set(handles.popup_experiments,'String',fn);
            
            gobj = findall(0,'Name','Experiment');
            guidata(gobj,handles);
            
        end
        
        function SaveExp(handles)
            
            fp = getpref('nv','SavedExpDirectory');
            
            if length(handles.ExperimentalScan.vary_prop) == 2 %2d scan
                handles.num = 2;
                text = ['-vary-',handles.ExperimentalScan.vary_prop{1}, '-',handles.ExperimentalScan.vary_prop{2},'-'];
                
            else %1d scan
                handles.num = 1;
                text = ['-vary-' handles.ExperimentalScan.vary_prop{1} '-'];
            end
            
            a = datestr(now,'yyyy-mm-dd-HHMMSS');
            fn = [num2str(handles.num),'DExp-seq-' handles.ExperimentalScan.SequenceName(1:1:end-4),text,a];
            
            fullFN = fullfile(fp,fn);
            
            Scan = handles.ExperimentalScan;
            
            Scan.DateTime = a;
            
            if ~isempty(Scan.ExperimentData),
                save(fullFN,'Scan');
            else
                uiwait(warndlg({'No data found for current experiment. Saving aborted.'}));
                return;
            end
            
            %send_email(fn,'',[fullFN '.mat']);
            
            gobj = findall(0,'Name','Experiment');
            guidata(gobj,handles);
            handles = guidata(gobj);
            
        end
        
        function ExpPlot(handles,scan,sliderValue)
            
            cla(handles.axes_AvgData,'reset')
            colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
            if ~isempty(scan.scan_nonlinear) && scan.scan_nonlinear==1
                x=scan.nonlinear_data.x;
            else    
                x = linspace(scan.vary_begin(1),scan.vary_end(1),scan.vary_points(1));
            end
            %x = linspace(scan.vary_begin(1),scan.vary_end(1),scan.vary_points(1));
            for j=1:1:length(scan.ExperimentData{sliderValue})
                y = scan.ExperimentData{sliderValue}{j};
                %plot(x,y,['.-' colors(j)],'Parent',handles.axes_AvgData,'MarkerSize',15);
                line(j)=plot(x,y,['.-' colors(j)],'Parent',handles.axes_AvgData,'MarkerSize',15,'LineWidth',0.5);
                hold(handles.axes_AvgData,'on');
                plot(x,smooth(y),['-' colors(j)],'Parent',handles.axes_AvgData,'LineWidth',1.5);
                if get(handles.checkbox_errorbar, 'Value')
                    errorbar(x, y, scan.ExperimentDataError{sliderValue}{j}, '.','Parent',handles.axes_AvgData)
                end
            end
            hold(handles.axes_AvgData,'off');
            a = {'Rise 1', 'Rise 2', 'Rise 3', 'Rise 4', 'Rise 5', 'Rise 6'};
            legend(handles.axes_AvgData,line,a(1:1:length(scan.ExperimentData{sliderValue})));
            xlabel(handles.axes_AvgData,scan.vary_prop{1});
            ylabel(handles.axes_AvgData,'kcps');
            title(handles.axes_AvgData,scan.DateTime);
            grid(handles.axes_AvgData, 'on');
            drawnow();
        end
        
%         function ExpPlot_spectrum(handles,fidname,FTtype)
%             fname=fidname;
%             [y, SizeTD2, SizeTD1] = Qfidread(fname, 17000 ,1, 5, 1);
%             MatrixOut = matNMRFT1D(y, FTtype);
%             cla(handles.axes_AvgData,'reset')
%             %colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
%                 plot(abs(MatrixOut),['.-' 'b'],'Parent',handles.axes_AvgData,'MarkerSize',15,'LineWidth',0.5);
%                 hold(handles.axes_AvgData,'on');
%             hold(handles.axes_AvgData,'off');
%             xlabel(handles.axes_AvgData,'frequency');
%             ylabel(handles.axes_AvgData,'A');
%             title(handles.axes_AvgData,scan.DateTime);
%             grid(handles.axes_AvgData, 'on');
%             drawnow();
%              %plot(abs(MatrixOut));
%         end
        
        function EachAvgPlot(handles,scan,sliderValue,twodsliderValue)
            
            colors = ['k' 'r' 'b' 'g' 'm' 'y']; % enough for 6 rises of SPD Acq
             if ~isempty(scan.scan_nonlinear) && scan.scan_nonlinear==1
                x=scan.nonlinear_data.x; 
            else    
                x = linspace(scan.vary_begin(1),scan.vary_end(1),scan.vary_points(1));
            end
            %x = linspace(scan.vary_begin(1),scan.vary_end(1),scan.vary_points(1));
            for j=1:1:length(scan.ExperimentDataEachAvg{twodsliderValue}{sliderValue})
                y = scan.ExperimentDataEachAvg{twodsliderValue}{sliderValue}{j};
                plot(x,y,['.-' colors(j)],'Parent',handles.axes_RawData);
                hold(handles.axes_RawData,'on');
                 if get(handles.checkbox_errorbar_each_avg, 'Value')
                     errorbar(x, y, scan.ExperimentDataErrorEachAvg{twodsliderValue}{sliderValue}{j}, '.','Parent',handles.axes_RawData)
                 end
            end
            hold(handles.axes_RawData,'off');
            a = {'Rise 1', 'Rise 2', 'Rise 3', 'Rise 4', 'Rise 5', 'Rise 6'};
            legend(handles.axes_RawData,a(1:1:length(scan.ExperimentDataEachAvg{twodsliderValue}{sliderValue})));
            xlabel(handles.axes_RawData,scan.vary_prop{1});
            ylabel(handles.axes_RawData,'kcps');
            title(handles.axes_RawData,datestr(now,'yyyy-mm-dd-HHMMSS'));
            grid(handles.axes_RawData, 'on');
            drawnow();
        end
        
        
        
        function [IShape,AOMShape,MWShape,QShape,SPDShape,CShape,NShape,NullShape,err] = ListOfStatesAndDurationsAWG(PulseSequence,handles)
            
            err = 0;
            % This function takes the PulseSequence and transforms it into a format
            % that is readable by the AWG (exclusively)
            
            % get max and min time for this sequence
            mintime = PulseSequence.GetMinRiseTime();
            maxtime = PulseSequence.time_pointer;
            
            num_points = int64((maxtime-mintime)*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate);
            
            NullShape = zeros(1,num_points);
            IShape = zeros(1,num_points);
            AOMShape = zeros(1,num_points);
            MWShape = zeros(1,num_points);
            QShape = zeros(1,num_points);
            SPDShape = zeros(1,num_points);
            CShape = zeros(1,num_points);
            NShape = zeros(1,num_points);
            
            %AWG states must be a multiple of the clock frequency
            for hlp=1:1:length(PulseSequence.Channels)
                if PulseSequence.Channels(hlp).Enable
                    
                    if ~isequal(mod(round(PulseSequence.Channels(hlp).RiseDurations*1e11),round(1e11/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate)),zeros(1,length(PulseSequence.Channels(hlp).RiseDurations)))
                        % without round won't work; multiplying by 1e11
                        err = 1;
                        uiwait(warndlg('Sequence durations not a multiple of AWG sample rate. Abort. (Or: you enabled a channel that you are not using)'));
                        return;
                    end
                end
            end
            
            if PulseSequence.Channels(1).Enable  %pulsed mode for laser
                
                for p=1:1:length(PulseSequence.Channels(1).RiseTimes)
                    AOMShape(int32(1+(PulseSequence.Channels(1).RiseTimes(p)+mintime)*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate):1:int32((PulseSequence.Channels(1).RiseTimes(p)+mintime+PulseSequence.Channels(1).RiseDurations(p))*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate)) = 1;
                end
            end
            
            if PulseSequence.Channels(2).Enable  %pulsed mode for mw
                
                for p=1:1:length(PulseSequence.Channels(2).RiseTimes)
                    MWShape(int32(1+(PulseSequence.Channels(2).RiseTimes(p)+mintime)*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate):1:int32((PulseSequence.Channels(2).RiseTimes(p)+mintime+PulseSequence.Channels(2).RiseDurations(p))*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate)) = 1;
                end
                
                n = round(100e9*(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2))/100e9:round(100e9*(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate))/100e9:round(100e9*((maxtime-mintime)-(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2)))/100e9;
                IShape =  sin(2*pi*PulseSequence.Channels(2).FreqIQ*n + PulseSequence.Channels(2).Phasemod).*PulseSequence.Channels(2).Ampmod + PulseSequence.Channels(2).FreqmodI;
                QShape =  cos(2*pi*PulseSequence.Channels(2).FreqIQ*n + PulseSequence.Channels(2).Phasemod).*PulseSequence.Channels(2).Ampmod + PulseSequence.Channels(2).FreqmodQ; %or sin(x + pi/2)
                
            end
            
            if PulseSequence.Channels(3).Enable  %pulsed mode for SPD
                
                for p=1:1:length(PulseSequence.Channels(3).RiseTimes)
                    SPDShape(int32(1+(PulseSequence.Channels(3).RiseTimes(p)+mintime)*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate):1:int32((PulseSequence.Channels(3).RiseTimes(p)+mintime+PulseSequence.Channels(3).RiseDurations(p))*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate)) = 1;
                end
                
            end
            
            if PulseSequence.Channels(4).Enable  %pulsed mode for C
                
                n = (1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2):(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate):((maxtime-mintime)-(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2));
                CShape = sin(2*pi*PulseSequence.Channels(4).Frequency*n + PulseSequence.Channels(4).Phasemod).*PulseSequence.Channels(4).Ampmod + PulseSequence.Channels(4).FreqmodI;
            end
            
            if PulseSequence.Channels(5).Enable %pulsed mode for N
                %Masashi commented 20130409;
                %n = (1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2):(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate):((maxtime-mintime)-(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2));
                n = round(100e9*(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2))/100e9:round(100e9*(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate))/100e9:round(100e9*((maxtime-mintime)-(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate/2)))/100e9;
                NShape = sin(2*pi*PulseSequence.Channels(5).Frequency*n + PulseSequence.Channels(5).Phasemod).*PulseSequence.Channels(5).Ampmod + PulseSequence.Channels(5).FreqmodI;
            end
            
            %Make sure first and last states of the array are 0, otherwise markers will be "on"
            %at undesirable places
            
            %put a zero-shape in the beginning and end
            additional_zeros = handles.ExperimentFunctions.delay_init_and_end_seq*handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate; %ALWAYS integer bc min sampl rate 1e7
            
            NullShape = [zeros(1,additional_zeros) NullShape zeros(1,additional_zeros)];
            IShape = [zeros(1,additional_zeros) IShape zeros(1,additional_zeros)];
            AOMShape =  [zeros(1,additional_zeros) AOMShape zeros(1,additional_zeros)];
            MWShape =  [zeros(1,additional_zeros) MWShape zeros(1,additional_zeros)];
            QShape =  [zeros(1,additional_zeros) QShape zeros(1,additional_zeros)];
            SPDShape =  [zeros(1,additional_zeros) SPDShape zeros(1,additional_zeros)];
            CShape =  [zeros(1,additional_zeros) CShape zeros(1,additional_zeros)];
            NShape = [zeros(1,additional_zeros) NShape zeros(1,additional_zeros)];
            
%             figure();
%             subplot(2,2,1);
%             plot(MWShape);
%             subplot(2,2,2);
%             plot(QShape);
%             subplot(2,2,3);
%             plot(CShape);
%             subplot(2,2,4);
%             plot(NShape);
        end
        
        function [statesPB,durationsPB,err] = ListOfStatesAndDurationsPB(PulseSequence,handles)
            
            err = 0;
            
            % This function takes the PulseSequence and transforms it into a format
            % that is readable by the Pulse Blaster. For the Pulse Blaster,
            % this format consists of the binary value representing the states of the four lines, plus
            % the duration of each state in s.
            
            %Start all channels at off
            %Everytime there is an event related to a channel, bitflip operation
            
            %initialize to sth
            Big_matrix_times = [];
            Big_matrix_indices = [];
            
            current_state = 0;
            
            for k=1:1:length(PulseSequence.Channels)
                
                if PulseSequence.Channels(k).Enable  %pulsed mode
                    
                    Final_times = PulseSequence.Channels(k).RiseTimes + PulseSequence.Channels(k).RiseDurations;
                    
                    Unsorted_times = [PulseSequence.Channels(k).RiseTimes Final_times];
                    %Times = [to^1, tf^1, to^2, tf^2, ... to^last, tf^last]
                    Times = sort(Unsorted_times);
                    Channel_ind = k*ones(1,length(Times));
                    
                    Big_matrix_times = [Big_matrix_times Times];
                    Big_matrix_indices = [Big_matrix_indices Channel_ind];
                    
                    
                    
                    %else, or off, does not need to do anything
                    
                end
                
            end
            
            % Treat PB data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            [Sorted_big_matrix_times, Ind] = sort(Big_matrix_times);
            Sorted_big_matrix_indices = Big_matrix_indices(Ind);
            
            Sorted_list_states = [];
            
            for k=1:1:(length(Sorted_big_matrix_times)-1)
                
                new_state = SingleBitFlip(current_state, Sorted_big_matrix_indices(k));
                
                Sorted_list_states = [Sorted_list_states new_state];
                
                current_state = new_state;
                
            end
            
            Final_sorted_big_matrix_times = diff(Sorted_big_matrix_times);
            Final_sorted_list_states = Sorted_list_states;
            
            A = find(Final_sorted_big_matrix_times > 1e-12);    %~= 0 gives a numerical bug
            Final_sorted_list_states = Final_sorted_list_states(A);
            Final_sorted_big_matrix_times = Final_sorted_big_matrix_times(A);
            
            % first and last states are 0
            Final_sorted_big_matrix_times = [handles.ExperimentFunctions.delay_init_and_end_seq Final_sorted_big_matrix_times handles.ExperimentFunctions.delay_init_and_end_seq];
            Final_sorted_list_states = [0 Final_sorted_list_states 0];
            
            durationsPB = Final_sorted_big_matrix_times;
            statesPB = Final_sorted_list_states;
            
            %PB states must be a multiple of the clock frequency
            if ~isequal(mod(round(durationsPB*1e11),round(1e11/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate)),zeros(1,length(durationsPB)))
                % without round won't work; multiplying by 1e11 as in
                % send_sequence in pulse blaster class
                err = 1;
                uiwait(warndlg('Sequence durations not a multiple of Pulse Blaster sample rate. Abort.'));
                return;
            end
            
            %PB has a latency of 5 clock cycles;
            latency = 5*(1/handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SampleRate);
            if ~isempty(find(durationsPB<latency-10*eps, 1)) %10eps for numerical value
                %err = 1;
                err_latency=1
               % uiwait(warndlg('Pulse Blaster latency critera not met. Abort.'));
                return;
            end
            
            
            % END Treat PB data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
        end
        
        function TrackCenterPB(handles)
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.StartProgramming();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBInstruction(1,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.INST_CONTINUE, 0, 750,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.ON);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBInstruction(1,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.INST_BRANCH, 0, 150,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.ON);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.StopProgramming();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart();
            handles.Imaginghandles.ImagingFunctions.TrackCenter(handles.Imaginghandles);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
        end
        
        function TrackCenterAWG(handles)
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.writeToSocket('AWGCONTROL:RMODE CONTINUOUS');
            
            NullShape = zeros(6*1e4,1); %length here is arbitrary
            OnShape = [zeros(1,1)' ones(6*1e4-2,1)' zeros(1,1)']';
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.clear_waveforms();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.create_waveform('POWMEAS',NullShape,OnShape,NullShape);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.setSourceWaveForm(1,'POWMEAS');
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SetChannelOn(1);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.AWGStart();
            go_on = 0;
            while ~go_on
                go_on = handles.Imaginghandles.ImagingFunctions.interfacePulseGen.writeReadToSocket('AWGControl:RSTate?');
            end
            
             handles.Imaginghandles.ImagingFunctions.TrackCenter(handles.Imaginghandles);
             
             handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SetChannelOff(1);
             handles.Imaginghandles.ImagingFunctions.interfacePulseGen.AWGStop();
        end
        
        function [power_array_in_V] = PowerMeasurementPB(handles)
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.StartProgramming();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBInstruction(1,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.INST_CONTINUE, 0, 750,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.ON);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBInstruction(1,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.INST_BRANCH, 0, 150,handles.Imaginghandles.ImagingFunctions.interfacePulseGen.ON);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.StopProgramming();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart();
            [laser_power_in_V,std_laser_power_in_V,power_array_in_V] = handles.Imaginghandles.ImagingFunctions.MonitorPower();
            pause(1);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
            
            [laser_power,std_laser_power] = PhotodiodeConversionVtomW(laser_power_in_V,std_laser_power_in_V);
            set(handles.text_power,'String',sprintf('Power = %0.3f +- %0.3f mW',laser_power,std_laser_power));
            
        end
        
        function [power_array_in_V] = PowerMeasurementAWG(handles)
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.writeToSocket('AWGCONTROL:RMODE CONTINUOUS');
            
            NullShape = zeros(6*1e4,1); %length here is arbitrary
            OnShape = [zeros(1,1)' ones(6*1e4-2,1)' zeros(1,1)']';
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.clear_waveforms();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.create_waveform('POWMEAS',NullShape,OnShape,NullShape);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.setSourceWaveForm(1,'POWMEAS');
            
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SetChannelOn(1);
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.AWGStart();
            while ~go_on
                go_on = handles.Imaginghandles.ImagingFunctions.interfacePulseGen.writeReadToSocket('AWGControl:RSTate?');
            end
            
            [laser_power_in_V,std_laser_power_in_V,power_array_in_V] = handles.Imaginghandles.ImagingFunctions.MonitorPower();
            handles.Imaginghandles.ImagingFunctions.interfacePulseGen.SetChannelOff(1);
            
            [laser_power,std_laser_power] = PhotodiodeConversionVtomW(laser_power_in_V,std_laser_power_in_V);
            set(handles.text_power,'String',sprintf('Power = %0.3f +- %0.3f mW',laser_power,std_laser_power));
        end
        
        
        
       
    end
    
end