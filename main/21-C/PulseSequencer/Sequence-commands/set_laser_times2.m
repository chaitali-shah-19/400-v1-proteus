function result_seq=set_laser_times(seq,LR_mirrorpos, UD_mirrorpos, laser_on_duration,laser_on_time,laserPower,laserPower_pol, T1_exp)

laser_channel_no = 10;
seq.Channels(laser_channel_no).Parameter1 = LR_mirrorpos;
seq.Channels(laser_channel_no).Parameter2 = UD_mirrorpos;
seq.Channels(laser_channel_no).Frequency = laser_on_duration;
seq.Channels(laser_channel_no).Phase = laser_on_time;
seq.Channels(laser_channel_no).Amplitude = laserPower;
seq.Channels(laser_channel_no).FreqIQ = laserPower_pol;
seq.Channels(laser_channel_no).PhaseQ = T1_exp;

result_seq = seq;

end