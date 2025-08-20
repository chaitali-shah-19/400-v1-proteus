function result_seq=set_waits_lasers(seq,wait_time,laser_delay_time,laser_on_time)

mw_channel_no = 36;
seq.Channels(mw_channel_no).Frequency = wait_time;
seq.Channels(mw_channel_no).Phase = laser_delay_time;
seq.Channels(mw_channel_no).Amplitude = laser_on_time;
result_seq = seq;
end