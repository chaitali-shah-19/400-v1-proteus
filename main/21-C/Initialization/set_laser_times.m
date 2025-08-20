function result_seq=set_laser_times(seq,laser_on_duration,laser_on_time,laserPower)

laser_channel_no = 10;
seq.Channels(laser_channel_no).Frequency = laser_on_duration;
seq.Channels(laser_channel_no).Phase = laser_on_time;
seq.Channels(laser_channel_no).Amplitude = laserPower;
result_seq = seq;

end