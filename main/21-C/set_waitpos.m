function result_seq=set_waitpos(seq,wait_pos,wait_time)

mw_channel_no = 24;
seq.Channels(mw_channel_no).Frequency = wait_pos;
seq.Channels(mw_channel_no).Phase = wait_time;
% seq.Channels(mw_channel_no).AmpIQ = sweep_time;
% seq.Channels(mw_channel_no).Amplitude = amp;
result_seq = seq;
end