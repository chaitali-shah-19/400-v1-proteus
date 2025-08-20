function result_seq=set_nmr_parameters(seq,pw,PW2,tacq,tof,gain,sequence_type)

mw_channel_no = 38;
seq.Channels(mw_channel_no).Frequency = pw;
seq.Channels(mw_channel_no).FreqmodQ = PW2;
seq.Channels(mw_channel_no).Phase = tacq;
%seq.Channels(mw_channel_no).Amplitude = nc1T;
seq.Channels(mw_channel_no).AmpIQ = tof;
seq.Channels(mw_channel_no).PhaseQ = sequence_type;
seq.Channels(mw_channel_no).FreqIQ = gain;

result_seq = seq;
end




