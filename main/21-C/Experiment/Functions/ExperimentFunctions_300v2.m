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
        arb_mag2
        tektronix_AFG_31000
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
        swabian
        scope
    end
    
    methods
        
        %%%%% Run experiment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function RunExperiment(obj,handles)
            disp('Using 400-magnet ExperimentFunctions file')
            import PulseStreamer.*;
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
            
           
            

        for  avg_count=1:1:Averages
               %%Loop over averages
                  helper_scan=1;  
                 mean_odmr_data = NaN*ones(1,handles.ExperimentalScan.vary_points(1));
                 if avg_count==1
                   
                     odnmr_rawdata=NaN*ones(Averages,handles.ExperimentalScan.vary_points(1));
                 end
                 
                 if ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                  
                    
                        try
                           for aux=1:1:handles.ExperimentalScan.vary_points(1)  %loop over first scan dimension
    %                         pause(3);
                            disp(['Running experiment number:' num2str(aux)])
                            status=1;                        
                            if ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                            tic;
                            %% Set attenuation
                            if handles.Array_PSeq{1}.Channels(29).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                            attenuation=handles.Array_PSeq{helper_scan,aux}.Channels(29).Amplitude;
                            if attenuation <11
                                disp(['attenuation value = ' num2str(attenuation) 'is too low'])
                                break
                            end
                            dat1 = NET.addAssembly('C:\400-magnet\21-C\mcl_RUDAT64.dll');
                            obj.att = mcl_RUDAT64.USB_RUDAT; 
                            obj.att.Connect();
                            obj.att.SetAttenuation(attenuation);
                            %obj.att.Read_Att();
                            end

                             n_cyc=100;
                             xD=2870;
                                field = 450;
                                      

                                %% ---------------------- SETUP AWG + SRS ---------------------------
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
                                        %obj.tabor.awg_chirp(srs_freq-awg_start_freq,srs_freq-awg_stop_freq,awg_amp,0,1/sweep_freq);
                                        %obj.tabor.awg_chirp(srs_freq-(awg_center_freq+awg_bw_freq/2),srs_freq-(awg_center_freq-awg_bw_freq/2),awg_amp,0,1/sweep_freq);

                                        % add custom chirp here.

                                        sweepers_en = 0;

                                        
                                        if length(handles.Array_PSeq{1}.Channels)>=46
                                            if handles.Array_PSeq{1}.Channels(46).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                                poltime1=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqmodI;
                                                poltime2=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqmodQ;
                                                poltime3=handles.Array_PSeq{helper_scan,aux}.Channels(46).SymmTime1;
                                                poltime4=handles.Array_PSeq{helper_scan,aux}.Channels(46).Phase;
                                                poltime5=handles.Array_PSeq{helper_scan,aux}.Channels(46).Frequency;
                                                poltime6=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqIQ;
                                                starting_pol_sign=handles.Array_PSeq{helper_scan,aux}.Channels(46).Amplitude;

                                                tic
                                                Sage_write(['6,',num2str(awg_center_freq),',',num2str(awg_bw_freq),',',num2str(awg_amp),...
                                                    ',',num2str(sweep_freq),',',num2str(sweep_sigma),',',num2str(symm),',',num2str(srs_freq),',',...
                                                    num2str(srs_amp),',',num2str(poltime1),',',num2str(poltime2),',',num2str(poltime3),',',...
                                                    num2str(poltime4),',',num2str(poltime5),',',num2str(poltime6),',',num2str(starting_pol_sign)]);         
                                                disp('writing sage parameters');
                                                toc
                                                Pines_wait(2021,'6');
                                                tic
                                                Sage_write('7')
                                                Pines_wait(2022,'7');
                                                toc
                                            else
                                                tic
                                                Sage_write(['6,',num2str(awg_center_freq),',',num2str(awg_bw_freq),',',num2str(awg_amp),',',num2str(sweep_freq),',',num2str(sweep_sigma),',',num2str(symm),',',num2str(srs_freq),',',num2str(srs_amp)]);         
                                                disp('writing sage parameters');
                                                toc
                                                pause(25)
                                                tic
                                                Sage_write('7')
                                                toc
                                            end
                                        end

                                    end
                                end

                                %% Initialize Proteus on Sage
                                %Sage_write('1');
%                                 Sage_write('1');
                                pause(1);
                                
                                %% SETUP LASER DOME ARDUINO: SET CONFIGURATION
                                if length(handles.Array_PSeq{1}.Channels)>=41
                                     if handles.Array_PSeq{1}.Channels(41).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                        laser_count=handles.Array_PSeq{helper_scan,aux}.Channels(41).Frequency;
                                        laser_sequence=handles.Array_PSeq{helper_scan,aux}.Channels(41).Amplitude;
                                        
                                        if laser_sequence==1
                                            obj.laserdome.orderlasers(laser_count);
                                        elseif laser_sequence==2
                                            obj.laserdome.lasernumber(laser_count);
                                        elseif laser_sequence==3
                                            obj.laserdome.read_laserdomegui(laser_count);
                                        end
                                     end
                                end

                                %% SETUP NMR pulse parameters
                                  if length(handles.Array_PSeq{1}.Channels)>=38
                                      
                                      %Sage_write('2,3'); %write to Sage for initializing readout
%                                       Sage_write(2);
                                if handles.Array_PSeq{1}.Channels(38).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    if aux<handles.ExperimentalScan.vary_points(1)
                                        pw=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Frequency;
                                        tacq=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Phase;
                                        tof=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).Amplitude;
                                        sequence_type=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).PhaseQ;
                                        gain=handles.Array_PSeq{helper_scan,aux+1}.Channels(38).FreqIQ;
                                        if length(handles.Array_PSeq{1}.Channels)>=44 && handles.Array_PSeq{1}.Channels(44).Enable
                                            pw3=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).Frequency;
                                            rigol_time1=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).Ampmod;
                                            rigol_wait1=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).SymmTime1;
                                            rigol_time2=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).Phase;
                                            rigol_wait2=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).AmpIQ;
                                            Tmaxlol=handles.Array_PSeq{helper_scan,aux+1}.Channels(44).Phasemod;
                                            rigol_rep=handles.Array_PSeq{helper_scan,aux+1}.Channels(42).SymmTime1;
                                        end
                                    end
                                    pw_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Frequency;
                                    tacq_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).Phase;
                                    Tmax = handles.Array_PSeq{helper_scan,aux}.Channels(38).Parameter1;
                                    sequence_type=handles.Array_PSeq{helper_scan,aux}.Channels(38).PhaseQ;
                                    gain_current=handles.Array_PSeq{helper_scan,aux}.Channels(38).FreqIQ;
                                    tof=handles.Array_PSeq{helper_scan,aux}.Channels(38).Amplitude;
                                    pi_pulse = handles.Array_PSeq{helper_scan,aux}.Channels(38).Parameter2;
                                    pause(0.2);
                                end

                                  end
                 
                                pause(0.5);%added
                                %Loop over repitions
                                for rep_count=1:1:Repetitions
                                    disp(['... Running repitition number:' num2str(rep_count)])
                                    %pause(rep_count*2);
    %                                 pause(120)

                                      %% TURN ON TABOR AWG and SRS


                                    pause(0.5);


                                if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1

                                   obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7); obj.com.StopBuffer(6); obj.com.StopBuffer(9);
                                    obj.com.KillAll();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                    handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();     
                                    break;
                                else 
    %                                 if aux>1 && rep_count>1
    %                                     pause(1); %recycle delay
    %                                 end

                               %% Initialize actuator position for very first motion
                               if handles.Array_PSeq{1}.Channels(12).Enable && rep_count ==1 && aux==1 && ~isempty(handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency)
                                    start_pos=obj.com.GetFPosition(obj.com.ACSC_AXIS_0);
                                    Position=handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency;
                                    obj.com.SetVelocity(obj.com.ACSC_AXIS_0,5);
                                    obj.com.SetAcceleration(obj.com.ACSC_AXIS_0,500);
                                    obj.com.SetDeceleration(obj.com.ACSC_AXIS_0,500);
                                    obj.com.SetJerk(obj.com.ACSC_AXIS_0,5000);

                                    obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0, -Position); %MOVE
                                    obj.com.Go(obj.com.ACSC_AXIS_0);
                                    displacement=abs(abs(start_pos)-abs(Position));
                                    disp('Setting initial motion parameters');
                                    if displacement>2
                                        disp('Shuttler not in place. MOVING!');
                                        obj.com.WaitMotionEnd (obj.com.ACSC_AXIS_0, 1000*10*displacement/50);
                                    end
                               end

                                %%% SET actuator position
                                %Actuator wait time and pos for T1(B) experiments
                                if handles.Array_PSeq{1}.Channels(24).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    fliptime = handles.Array_PSeq{helper_scan,aux}.Channels(24).AmpIQ;
                                    waitpos = handles.Array_PSeq{helper_scan,aux}.Channels(24).Frequency;
                                    T1_wait_time = handles.Array_PSeq{helper_scan,aux}.Channels(24).Phase;
                                elseif handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    waitpos = handles.Array_PSeq{helper_scan,aux}.Channels(9).Frequency; %change back to 9 for not T1
                                    postime = handles.Array_PSeq{helper_scan,aux}.Channels(9).Phase; %change back to 9 for not T1
                                end
                                        
                                if handles.Array_PSeq{1}.Channels(12).Enable
                                    if ~isempty(handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency)
                                        disp('Getting motion parameters from NVautomizer');
                                        Position=handles.Array_PSeq{helper_scan,aux}.Channels(12).Frequency;
                                        Velocity=handles.Array_PSeq{helper_scan,aux}.Channels(12).Amplitude;
                                        Accn=handles.Array_PSeq{helper_scan,aux}.Channels(12).Phase;
                                        Jerk=handles.Array_PSeq{helper_scan,aux}.Channels(12).AmpIQ;
                                        c_position=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqIQ;
                                        Wait_time=handles.Array_PSeq{helper_scan,aux}.Channels(12).FreqmodQ;
                                        tt2=handles.Array_PSeq{helper_scan,aux}.Channels(10).Frequency;
                                        delta_time=handles.Array_PSeq{helper_scan,aux}.Channels(8).Frequency;
                                        T1delay_time=handles.Array_PSeq{helper_scan,aux}.Channels(20).Frequency; %for wait time experiments

                                         if length(handles.Array_PSeq{1}.Channels)>=46
                                            if handles.Array_PSeq{1}.Channels(46).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                                poltime1=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqmodI;
                                                poltime2=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqmodQ;
                                                poltime3=handles.Array_PSeq{helper_scan,aux}.Channels(46).SymmTime1;
                                                poltime4=handles.Array_PSeq{helper_scan,aux}.Channels(46).Phase;
                                                poltime5=handles.Array_PSeq{helper_scan,aux}.Channels(46).Frequency;
                                                poltime6=handles.Array_PSeq{helper_scan,aux}.Channels(46).FreqIQ;
                                                Wait_time=poltime1+poltime2+poltime3+poltime4+poltime5+poltime6;
                                                disp(['task table mode on, new wait_time value is' num2str(Wait_time)])
                                            end
                                         end

                                        %% Used for acquistion delay
    %                                     if handles.Array_PSeq{1}.Channels(9).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                                     acq_time=handles.Array_PSeq{helper_scan,aux}.Channels(9).Frequency;
    %                                     end
   
                                        disp('Writing motion parameters from NVautomizer');
                                        obj.com.SetVelocity(obj.com.ACSC_AXIS_0,Velocity);
                                        obj.com.SetAcceleration(obj.com.ACSC_AXIS_0,Accn);
                                        obj.com.SetDeceleration(obj.com.ACSC_AXIS_0,Accn);
                                        obj.com.SetJerk(obj.com.ACSC_AXIS_0,Jerk);

                                        %this line for having sample wait at
                                        %bottom position before moving up
    %                                    obj.com.WriteVariable(Wait_time*1e3+tt2, 'V1', obj.com.ACSC_NONE);%need to do 1e3 because ACS times are in ms
                                        %normal 
                                        obj.com.WriteVariable(T1delay_time*1e3, 'V2', obj.com.ACSC_NONE); %write delay time to Motion Manager
                                        obj.com.WriteVariable(Wait_time*1e3, 'V1', obj.com.ACSC_NONE); %need to do 1e3 because ACS times are in ms
                                        obj.com.WriteVariable(-Position, 'V0', obj.com.ACSC_NONE);

                                        %% turn laser on during exp. %%
                                        if handles.Array_PSeq{1}.Channels(10).Enable
                                            if ~isempty(handles.Array_PSeq{helper_scan,aux}.Channels(10).Frequency)
                                                disp('Getting laser times from NVautomizer');
                                                laser_on_time=handles.Array_PSeq{helper_scan,aux}.Channels(10).Frequency;
                                                laser_delay_time=handles.Array_PSeq{helper_scan,aux}.Channels(10).Phase;
                                                laserPower=handles.Array_PSeq{helper_scan,aux}.Channels(10).Amplitude;
                                            end
                                        end

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
%                           THIS IS WHAT WE ACTUALLY USE (7/14)
%                           DON'T USE BUFFER 9
%                           JUST USE POS_TIME IN BUFFER 8
%                           WHICH IS T1_wait_time IN AUTOMIZER
%                           (and 'postime' in this file)
                                        elseif length(handles.Array_PSeq{1}.Channels) > 38 && length(handles.Array_PSeq{1}.Channels) ~= 40 
                                            if handles.Array_PSeq{1}.Channels(38).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                                obj.com.WriteVariable(T1_wait_time*1e3,'V2', obj.com.ACSC_NONE);
                                                obj.com.WriteVariable(fliptime,'V3', obj.com.ACSC_NONE);
                                                obj.com.ToPoint(obj.com.ACSC_AMF_WAIT, obj.com.ACSC_AXIS_0,-c_position);  %go up to coil position
                                                %obj.com.RunBuffer(8);
                                                obj.com.RunBuffer(8);
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


                                %%  ------------------------ Main sequence -----------------------------------  

%                                 if ~err & ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                     [stPB,durPB,err] = obj.ListOfStatesAndDurationsPB(handles.Array_PSeq{helper_scan,aux},handles);
%                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.sendSequence(stPB,durPB,1);
%                                     %%%%%%%%%%% add for new PB  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                    % handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart();
%                                 end

                                if ~err && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
                                    disp('Load sequence to Swabian');
                                    [stPB,durPB,err] = obj.ListOfStatesAndDurationsPB(handles.Array_PSeq{helper_scan,aux},handles);
                                    [pattern0, pattern1, pattern2, pattern3, pattern4,...
                                        pattern5, pattern6, pattern7] = make_swabian_pattern (stPB, durPB);
        
                                    sequence = Sequence();
                                    sequence.setDigital(0, pattern0);
                                    sequence.setDigital(1, pattern1);
                                    sequence.setDigital(2, pattern2);
                                    sequence.setDigital(3, pattern3);
                                    sequence.setDigital(4, pattern4);
                                    sequence.setDigital(5, pattern5);
                                    sequence.setDigital(6, pattern6);
                                    sequence.setDigital(7, pattern7);
                                    sequence = sequence.repeat(1);
                                    n_runs =1;
                                    finalState = OutputState([],0,0);
                                end

                                if err
                                    disp('You have aborted!');
                                    handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted = 1;
                                    break;
                                end

                                if err_latency==1
                                   disp('You have aborted!');
                                   break;
                                end

                                % END Load Sequence %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                                % Experiment routine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                                    disp('You have aborted!');
                                    obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);
                                    obj.com.KillAll();
                                    handles.ExperimentFunctions.swabian.reset(); 
%                                     %%%%%%%%%%%%%%%%%%%%%%%%%%%% add for new PB
%                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
%                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();

                                    % turn OFF AWG and SRS
                                    if length(handles.Array_PSeq{1}.Channels)>=39 && ~length(handles.Array_PSeq{1}.Channels)==39
                                        if handles.Array_PSeq{1}.Channels(39).Enable 
%                                             obj.srs.set_MWoff();
%                                             obj.tabor.awg_stop();
                                        end 
                                    end

                                    if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                        if handles.Array_PSeq{1}.Channels(34).Enable
%                                             obj.psu.PS_OUTOff();
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
    %                                 break;
                                else %If not aborted

    %                                 clear odnmr_data1;
    %                                 if rep_count==1nt=1
    %                                     clear odnmr_data;
    %                                     odnmr_data = NaN*ones(1,Repetitions);
    %                                 end
    %                                 obj.ramp.Stop_RampGen();
    %                                 pause(0.5);
    %                                 obj.ramp.Start_RampGen();

%                                     handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStart(); %will fire one single sequence Repetitions number of times
                                    %handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();

                                    %%%% MAIN FIRE %%%%%%%%%%%%
                                    disp('Firing Swabian');
                                    handles.ExperimentFunctions.swabian.stream(sequence, n_runs, finalState); %will fire Swabian

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
                                        pause(1.03*Wait_time-1.03*0.374-0.95);
%                                             pause(1.03*Wait_time);
                                        if length(handles.Array_PSeq{1}.Channels)>=34
                                            if handles.Array_PSeq{1}.Channels(34).Enable
%                                                     obj.psu.PS_OUTOff();
                                            end
                                        end
                                    Sage_write('8') %Stop MW
                                    Sage_write('1') %QRF 
                                    

                                    % FOR NOW hardcode nc value
                                    nc = 0;
                                    if length(handles.Array_PSeq{1}.Channels)>=44 && handles.Array_PSeq{1}.Channels(44).Enable
                                        Sage_write(['2,',num2str(pw_current),',',num2str(pw3_current),',',num2str(nc),',',num2str(nc2),',',num2str(rigol_wait1_current+rigol_time1_current),',',num2str(rigol_wait2_current+rigol_time2_current),',',num2str(tacq_current), ',', num2str(nc3),',',num2str(rigol_rep_current),',',num2str(Tmaxlol)]); %write to Sage for initializing readout
                                    elseif sequence_type == 10 % WHH-4 plus pulsed spin-lock
                                        Sage_write(['2,',num2str(pw_current),',',num2str(nc+nc2),',',num2str(Tmax),',',num2str(tacq_current)]); %write to Sage for initializing readout
                                    else
                                        Sage_write(['2,',num2str(pw_current),',',num2str(pi_pulse),',',num2str(Tmax),',',num2str(tacq_current),',',num2str(tof)]); %write to Sage for initializing readout
                                    end
                                    disp('writing sage parameters');
%                                           2/13 we decided to comment this out:  
%                                         pause(total_delay-1.03*Wait_time); %3 sec between reps
% %                                             and replace it with this:
                                     pause(15);
                                        end

                                        Sage_write('3'); 
                                        disp('Initializing Sage for measurement')

                                        %for relay expts/T1(B)
                                        %pause(40); %40 sec laser pumping



                                        %Original Line
                                        % Turn off/on Helhmholtz PSU 1
                                        if length(handles.Array_PSeq{1}.Channels)>=34
                                        if handles.Array_PSeq{1}.Channels(34).Enable
%                                         obj.psu.PS_OUTOff();
                                        %obj.psu.PS_OUTOn();
                                        end

                                        end

                                        % Turn off/on Helhmholtz PSU 2
                                        if length(handles.Array_PSeq{1}.Channels)>=37
                                            if handles.Array_PSeq{1}.Channels(37).Enable
                                                obj.psu2.PS_OUTOff();
    %                                             obj.psu2.PS_OUTOn();
                                            end

                                        end
                                         % Turn OFF AWG and SRS
                                         if length(handles.Array_PSeq{1}.Channels)>=39
                                             if handles.Array_PSeq{1}.Channels(39).Enable
%                                                  obj.srs.set_MWoff();
%                                                  obj.tabor.awg_stop();
                                             end
                                         end

                                        if length(handles.Array_PSeq{1}.Channels)>=45 && handles.Array_PSeq{1}.Channels(45).Enable
                                            % THIS 15 seconds pause is to have the pulseblaster ON, so
                                            % that PB can trigger the pulse-sequence and the tektronix simultaneously
                                            % Currently hardcoded to 15 seconds but shouldn't be the case.
                                            % we may need this to be elongated so that we can reaout properly 
                                            pause(15);
                                        else
                                            % This limit as well.. ==> we
                                            % do not want to go to 
                                            pause(2);
                                        end

                                    else
                                         pause(abs(1.1*sum(durPB)));
                                    end


                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%important%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %waitfor(handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop())
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

                                %% Wait for shuttler to return up
                                pause(0.5);
                                t2 = timer;
                                t2.StartFcn = @(~,~) disp('Wait for the shuttler to move back up');
                                t2.TimerFcn = @(~,~) disp('Shuttler should be up');
                                t2.StopFcn =  @(~,~) stop(t2);
                                t2.StartDelay = 10; % (put 200s here to match when shuttler reaches top - 20240427) shuttle time is 130s for velocity 5 plus additional 600s wait time to accomodate temperature stabilization of 5 min experiments
                                t2.ExecutionMode = 'singleshot';
                                start(t2);
                                wait(t2);

                                %% TURN Off RIGOL FOR MAG
                                if length(handles.Array_PSeq{1}.Channels)>=42
                                    if handles.Array_PSeq{1}.Channels(42).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                         obj.arb_mag.MW_RFOff();
%                                         pause(0.1);
%                                         obj.arb_mag.MW_RFOff();
%                                         pause(0.1);
%                                         obj.arb_mag.MW_RFOff();
%                                         pause(0.1);
                                        if length(handles.Array_PSeq{1}.Channels)>=42 
                                                   if handles.Array_PSeq{1}.Channels(42).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                                         obj.arb_mag2.MW_RFOff();
%                                                         pause(0.1);
%                                                         obj.arb_mag2.MW_RFOff();
%                                                         pause(0.1);
%                                                         obj.arb_mag2.MW_RFOff();
%                                                         pause(0.1);
                                                   end
                                        end
                                    end
                                end

                                      
                                %% Turn off Helhmholtz
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
%                                 obj.psu.PS_OUTOff();
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

                                % Turn OFF AWG and SRS
                                if length(handles.Array_PSeq{1}.Channels)>=39
                                    if handles.Array_PSeq{1}.Channels(39).Enable
%                                         obj.srs.set_MWoff();
%                                         obj.tabor.awg_stop();
                                    end
                                end
                                
                                %% LASER DOME ARDUINO: TURN OFF
                                if length(handles.Array_PSeq{1}.Channels)>=41
                                     if handles.Array_PSeq{1}.Channels(41).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                         for i = 1:10
%                                             fprintf(['Close no: ' num2str(i) '\n'])
                                            obj.laserdome.all_lasers_off();
%                                             pause(1)
%                                         end
                                     end
                                end

                            if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                               obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);
                                obj.com.KillAll();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                    if handles.Array_PSeq{1}.Channels(34).Enable
%                                         obj.psu.PS_OUTOff();
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
                                     if length(handles.Array_PSeq{1}.Channels)>=45 && handles.Array_PSeq{1}.Channels(45).Enable
                                    %% turn off output of AFG 31000 and reset when aborted.
                                       obj.tektronix_AFG_31000.output_off();
                                     end
                                end
                                break;
                            end
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          %  stopwatch(0);
                          % obj.mw.MW_RFOff();
                          %obj.arb4.MW_RFOff();
                          %pause(waittime/1000);   %bring this back if you want
                          %to do normal T1 exp

    %                       try
    %                           email_recent;
    %                       catch
    %                           disp('error_happened');
    %                       end
                  
                          
                          %Sage_write('4'); %close communication to Sage
                          pause(15);
                          Sage_write('4');
                          
                            %% READ SCOPE
%                             if length(handles.Array_PSeq{1}.Channels)>=42
%                                 if handles.Array_PSeq{1}.Channels(42).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                                     [timeaxis,data1]=obj.scope.Acquire();
%                                     a = datestr(now,'yyyy-mm-dd-HHMMSS');
%                                     fn = sprintf([a,'_Scope_chunk']);
%                                     % Save data
%                                     fprintf('Writing data to Z:.....\n');
%                                     save(['Z:\' fn],'timeaxis','data1');
%                                 end
%                             end

                        %pause(390);

                          total_wait_time = 180+T1_wait_time;
                          fprintf("This is total wait time %.3f \n", total_wait_time);
                          pause(total_wait_time); 
                          %pause(500);

                          if length(handles.Array_PSeq{1}.Channels)>=45 && handles.Array_PSeq{1}.Channels(45).Enable
                            %% turn off output of AFG 31000 and reset when experiment is finished.
                            obj.tektronix_AFG_31000.output_off();
                          end
                            end %%%End Rep


    %                             if handles.Array_PSeq{1}.Channels(24).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                             fclose(fp1);
    %                             fclose(fp2);
    %                             fclose(fp3);
    % %                             else
    % %                             fclose(fp1);
    % %                             fclose(fp2);
    %                             end

                        %    if handles.Array_PSeq{1}.Channels(16).Enable
                             %   obj.mw.MW_RFOff();
                                %handles.ExperimentFunctions.mw.AM0();
    %                         odnmr_data(rep_count)=mean(odnmr_data1,2);
    %                         odnmr_rawdata(avg_count,aux)=mean(odnmr_data,2); %mean over reps                         Number_nnan=find(~isnan(odnmr_rawdata));
    %                         mean_odmr_data=nanmean(odnmr_rawdata,1);
    %                         handles.ExperimentFunctions.AvgData{1} = mean_odmr_data;
    %                         if aux==1
    %                         obj.PinesDataPlot(handles,1);
    %                         else
    %                             obj.PinesDataPlot(handles,0);
    %                         end
                           % end

                            if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted==1
                               obj.com.StopBuffer(1); obj.com.StopBuffer(3); obj.com.StopBuffer(7);obj.com.StopBuffer(6);
                                obj.com.KillAll();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBStop();
                                handles.Imaginghandles.ImagingFunctions.interfacePulseGen.PBReset();
                                if length(handles.Array_PSeq{1}.Channels)>=34 && ~length(handles.Array_PSeq{1}.Channels)==35
                                    if handles.Array_PSeq{1}.Channels(34).Enable || handles.Array_PSeq{1}.Channels(36).Enable
%                                         obj.psu.PS_OUTOff();
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
                                if length(handles.Array_PSeq{1}.Channels)>=45 && handles.Array_PSeq{1}.Channels(45).Enable
                                    %% turn off AFG 31000 when aborted.
                                       obj.tektronix_AFG_31000.output_off();
                                end
                                break;
                            end
                            end

    %                         if handles.Array_PSeq{1}.Channels(21).Enable && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
    %                             
    %                             % stop the task
    %                             [status]=calllib(  handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.LibraryName,'DAQmxStopTask',  handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.TaskHandles);
    %                             
    %                             % Error Check
    %                             handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.CheckErrorStatus(status);
    %                             
    %                             % clear the task
    %                             [status]=calllib(  handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.LibraryName,'DAQmxClearTask',  handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.TaskHandles);
    %                             
    %                         end
    %                         
                         %vp

                         if handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted~=1

                             disp(['Wait time for Experiment No.' num2str(aux) ': ' num2str(Wait_time)]);
                             %pause(300);
                         end


                         %% Saving log of dc_level and Vpp and freq range

    %                      [myyr, mymonth, mydy, myhr, mymin, mysecond] = datevec(now);
    %                      mfilename=sprintf(', Time:%d-%02d-%02d_%02d.%02d.%02d',myyr, mymonth, mydy, myhr, mymin, round(mysecond));
    %                      fprintf(fmatch,'%d',aux);
    %                      if agilent_on
    %                      fprintf(fmatch,', %f, %f',dc_level,Vpp);
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on2
    %                      fprintf(fmatch,', %f, %f',dc_level2,Vpp2);
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on3
    %                      fprintf(fmatch,', %f, %f',dc_level3,Vpp3);
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on4
    %                      fprintf(fmatch,', %f, %f',dc_level4,Vpp4); 
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on9
    %                      fprintf(fmatch,', %f, %f',dc_level9,Vpp9); 
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on10
    %                      fprintf(fmatch,', %f, %f',dc_level10,Vpp10); 
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on11
    %                      fprintf(fmatch,', %f, %f',dc_level11,Vpp11); 
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      if rigol_on12
    %                      fprintf(fmatch,', %f, %f',dc_level12,Vpp12); 
    %                      else
    %                      fprintf(fmatch,', , ');
    %                      end
    %                      fprintf(fmatch,[mfilename, '\n']);
                         %%
% 
%                          try
%                              email_recent;
%                          catch
%                              try
%                              email_recent;
%                              catch
%                              disp('error_happened');
%                              end
%                          end
                        pause(0.5);
                        %pause(210); % important pause!!
                        pause(30);
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
%              obj.mw.MW_RFOff();
% Close_spike();

%         % update average



            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Saving result and finishing
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
       
            
%               if handles.Array_PSeq{1}.Channels(16).Enable && ~err && ~handles.Imaginghandles.ImagingFunctions.interfaceDataAcq.hasAborted
%                 handles.ExperimentalScan.ExperimentData = handles.ExperimentFunctions.AvgData;
% %                 handles.ExperimentalScan.ExperimentDataEachAvg = odnmr_rawdata;
% %                 handles.ExperimentalScan.ExperimentDataErrorEachAvg = ErrorEachAvg;
%                 obj.SaveExp(handles);
%                 obj.UpdateExpScanList(handles);
%               end
            
                 toc;
            
%             email_recent;
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