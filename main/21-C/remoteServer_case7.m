%             case 7 % Play MW chirp waveform             
% ---------------------------------------------------------------------
% Play segment 1 in channel 1
% ---------------------------------------------------------------------

% res = inst.SendScpi(['INST:CHAN ' num2str(dacChanInd)]); % select channel 2
% assert(res.ErrCode == 0);

%                 res = inst.SendScpi(':SOUR:FUNC:MODE TASK');
%                 assert(res.ErrCode == 0);

% res = inst.SendScpi(':SOUR:FUNC:MODE:SEG 1');
% assert(res.ErrCode == 0);
% 
% amp_str = [':SOUR:VOLT ' sprintf('%0.2f', awg_amp)];
% res = inst.SendScpi(amp_str);
% assert(res.ErrCode == 0);

res = inst.SendScpi(':OUTP ON');
assert(res.ErrCode == 0);

fprintf('Waveform generated and playing\n');



     
                

                