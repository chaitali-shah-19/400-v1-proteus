function result_seq = rotary_pulse(seq,sample_rate,length_rotary_pulse,flip_angle_rad,ch_on)

seq = ttl_pulse(seq, 2, length_rotary_pulse);

seq.Channels(2).Ampmod = [seq.Channels(2).Ampmod ones(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(2).FreqmodI = [seq.Channels(2).FreqmodI zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(2).FreqmodQ = [seq.Channels(2).FreqmodQ zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(2).Phasemod = [seq.Channels(2).Phasemod flip_angle_rad*ones(1,int64(sample_rate*length_rotary_pulse))];

if ch_on(4)
seq.Channels(4).Ampmod = [seq.Channels(4).Ampmod zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(4).FreqmodI = [seq.Channels(4).FreqmodI zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(4).Phasemod = [seq.Channels(4).Phasemod zeros(1,int64(sample_rate*length_rotary_pulse))];
end

if ch_on(5)
seq.Channels(5).Ampmod = [seq.Channels(5).Ampmod zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(5).FreqmodI = [seq.Channels(5).FreqmodI zeros(1,int64(sample_rate*length_rotary_pulse))];
seq.Channels(5).Phasemod = [seq.Channels(5).Phasemod zeros(1,int64(sample_rate*length_rotary_pulse))];
end

result_seq = seq;
