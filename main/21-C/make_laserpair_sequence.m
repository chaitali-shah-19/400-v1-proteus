function make_laserpair_sequence(filenum,laser1, laser2)

    [fid, msg] = fopen(['C:/code/SavedSequences/laser_pairs' num2str(filenum) '.xml'], 'w');
    if fid == 1
        error(msg);
    end
    fprintf(fid, '%s \n');
    str = verbatim;
    %{
    
   <sequence>

        <variables>
            % these are the variables that can be scanned or switched from the GUI
            d1=float(2,0,1000)
            coil_position = float(617, 10, 1600)
            wait_time= float(20, 0.02, 1000)
            velocity=float(10, 1, 2000)
            accn=float(100, 10, 30000)
            jerk=float(1000, 100, 800000)
            g_position=float(1440, 600, 1600)
            attenuation=float(0,0,30)
            nitro_fill=float(1,-100,100)

           sweep_freq=float(0.015,0,20000);

           ramp1_on=float(1,0,30);
            Vpp1 = float(12.7628,0,20)
            dc_level1=float(7.9218,0,30);

           ramp2_on=float(1,0,30);
            Vpp2 = float(12.7628,0,20)
            dc_level2=float(7.9218,0,30);
            phase2 = float(0,0,359);

            ramp3_on=float(1,0,30);
            Vpp3 = float(12.7628,0,20)
            dc_level3=float(7.9218,0,30);
            phase3 = float(0,0,359);

           ramp4_on=float(1,0,30);
            Vpp4 = float(12.7628,0,20)
            dc_level4=float(7.9218,0,30);
            phase4 = float(0,0,359);

            laser=float(100,0,100);
            symmetry=float(0,0,1);
            T1_wait_pos = float(1000,617,1447);
            T1_wait_time = float(1000,0,120000);

            loop_time = float(15,0,3000);   %loop time for hyperpolarization wave
            tt1= float(0,0,3000000);    
            bw_center=float(2.8,0.001,5.5);
            bw_range=float(0.7,0.001,5.5)

            Match_on_arb1=float(0,0,1);
            Match_on_arb2=float(0,0,1);
            Match_on_arb3=float(0,0,1);
            Match_on_arb4=float(0,0,1);

            current=float(0,-5,5);

        </variables>

        <shaped_pulses>

        </shaped_pulses>

        <instructions>
            PSeq = enable_channels(PSeq, 1:36, [1 0 0 0 1 0 1 0 0 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0]);


            %CHANNEL 14: MW SWITCH
            %CHANNEL 34: HELMHOLTZ COIL PSU


            %CHANNEL 7: GREEN LASER FIBER 1
            %CHANNEL 10: GREEN LASER FIBER 2
            %CHANNEL 11: GREEN LASER FIBER 3
            %CHANNEL 13: GREEN LASER FIBER 4
            %CHANNEL 15: GREEN LASER FIBER 5
            %CHANNEL 17: GREEN LASER FIBER 6
            %CHANNEL 18: GREEN LASER FIBER 7
            %CHANNEL 19: GREEN LASER FIBER 8

            PSeq = set_waitpos(PSeq,T1_wait_pos,T1_wait_time);
            PSeq = set_laser(PSeq,laser);
            PSeq = set_acstt1(PSeq, tt1);
            PSeq = set_att(PSeq, attenuation);
            PSeq = set_helmholtz(PSeq,current);

          %sweep_freq=round2(70*0.3/bw_range, 1);
          %best for single crystal
          %sweep_freq=round2(180*0.15/bw_range, 1);
          %for powder (beta)
          %sweep_freq=round2(0.015*bw_range/0.7, 1);
          %sweep_freq=round2(66*0.7/bw_range, 1);

         % for powder (M42-L)
        %sweep_freq=round2(200*0.3/bw_range, 1);



          PSeq = set_ramp1_symm(PSeq,sweep_freq,Vpp1,dc_level1,0,bw_range,bw_center, Match_on_arb1,  ramp1_on,symmetry);
           PSeq = set_ramp2_symm(PSeq,sweep_freq,Vpp2,dc_level2,phase2,bw_range,bw_center, Match_on_arb2,  ramp2_on,symmetry);
           PSeq = set_ramp3_symm(PSeq,sweep_freq,Vpp3,dc_level3,phase3,bw_range,bw_center, Match_on_arb3,  ramp3_on,symmetry);
           PSeq = set_ramp4_symm(PSeq,sweep_freq,Vpp4,dc_level4,phase4,bw_range,bw_center, Match_on_arb4,  ramp4_on,symmetry);



            PSeq = set_acs_position2(PSeq, g_position,velocity, accn,jerk,coil_position,wait_time);

            PSeq = ttl_pulse(PSeq,5, 10e-6);

            PSeq = wait(PSeq,d1);
            PSeq = ttl_pulse(PSeq,12, 20e-3);        %ACS

            PSeq = ttl_pulse(PSeq, 14,wait_time);                   %%MW SWITCH
%}
     fprintf(fid,'%s \n',str);
    
    %% Making list of codes corresponding to individual lasers 
    % Corresonds to the order at clock positions  12, 2, 3, 4, 6, 8, 9, 10,
    % bottom
    str_laser{1} = verbatim;
    %{
  PSeq = ttl_pulse(PSeq, 15,wait_time, -wait_time, 1); %LASER: 12 oclock  
    %}
    
    str_laser{2} = verbatim;
    %{
    PSeq = ttl_pulse(PSeq, 17,wait_time, -wait_time, 1); %LASER: 2 oclock 
    %}
     
    str_laser{3} = verbatim;
    %{
 PSeq = ttl_pulse(PSeq, 16,wait_time, -wait_time, 1); %LASER: 3 oclock  
    %}
    
     str_laser{4} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 13,wait_time, -wait_time, 1); %LASER: 4 oclock 
    %}
     
     str_laser{5} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 7,wait_time, -wait_time, 1); %LASER: 6 oclock   
    %}
    
     str_laser{6} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 19,wait_time, -wait_time, 1); %LASER: 8 oclock 
    %}
    
     str_laser{7} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 11,wait_time, -wait_time, 1); %LASER: 9 oclock 
    %} 
     
     str_laser{8} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 18,wait_time, -wait_time, 1); %LASER: 10 oclock   
    %} 
     
    str_laser{9} = verbatim;
    %{
PSeq = ttl_pulse(PSeq, 10,wait_time, -wait_time, 1); %LASER: 0 oclock   
    %}
    
    j=1;k=2;
    fprintf(fid,'%s \n',str_laser{laser1});
    fprintf(fid,'%s \n',str_laser{laser2});
    
    %% closing
    str = verbatim;
    %{
    PSeq = wait(PSeq,3);
    PSeq = ttl_pulse(PSeq,5, 10e-3); 
    
    </instructions>
    
    </sequence>
    
    %}
    fprintf(fid,'%s \n',str);
    
    fclose(fid);
    
    
    %% Examples
    
%     fprintf(fid,'%s \n',['PSeq = set_BNC2(PSeq, BNC_width + ' num2str(1+2.8*k) 'e-6,BNC_ampl,BNC_delay);']);

end