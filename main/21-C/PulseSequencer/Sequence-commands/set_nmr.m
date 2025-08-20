function result_seq = set_nmr_parameters(seq, tref, tof, pw1, pw2, pulse_delay, tacq, num_loops)

mw_channel_no = 38;

% it's a ttl pulsed channel
seq.Channels(mw_channel_no).Frequency = pw2;
seq.Channels(mw_channel_no).Amplitude = tof;
seq.Channels(mw_channel_no).Phase =  tacq;
seq.Channels(mw_channel_no).PhaseQ = pulse_delay;
seq.Channels(mw_channel_no).FreqIQ = tref;
seq.Channels(mw_channel_no).Parameter1 = num_loops;
seq.Channels(mw_channel_no).Parameter2 = pw1;
result_seq = seq;