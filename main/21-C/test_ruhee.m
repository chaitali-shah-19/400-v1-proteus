function result_seq=test_ruhee(seq,test_pulse,wait_time)

mw_channel_no = 47;
seq.Channels(mw_channel_no).Frequency = test_pulse;
seq.Channels(mw_channel_no).Phase = wait_time;
% seq.Channels(mw_channel_no).AmpIQ = sweep_time;
% seq.Channels(mw_channel_no).Amplitude = amp;
result_seq = seq;
end