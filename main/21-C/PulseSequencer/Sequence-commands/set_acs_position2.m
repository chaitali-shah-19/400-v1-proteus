function result_seq = set_acs_position2(seq, g_position, vel,accn,jerk,coil,wait_time,downtime,uptime)

mw_channel_no = 12;

% it's a ttl pulsed channel
seq.Channels(mw_channel_no).Frequency = g_position;
seq.Channels(mw_channel_no).Amplitude = vel;
seq.Channels(mw_channel_no).Phase = accn;
seq.Channels(mw_channel_no).AmpIQ = jerk;
seq.Channels(mw_channel_no).FreqIQ =coil;
seq.Channels(mw_channel_no).FreqmodQ =wait_time;
seq.Channels(mw_channel_no).Parameter1 =downtime;
seq.Channels(mw_channel_no).Parameter2 =uptime;
result_seq = seq;




