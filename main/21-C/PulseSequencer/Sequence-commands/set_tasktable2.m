function result_seq=set_tasktable(seq,poltime,starting_pol_sign, LR_mirrorpos, UD_mirrorpos)

mw_channel_no = 46;
seq.Channels(mw_channel_no).FreqmodI = poltime;
seq.Channels(mw_channel_no).Amplitude = starting_pol_sign;
seq.Channels(mw_channel_no).Parameter1 = LR_mirrorpos;
seq.Channels(mw_channel_no).Parameter2 = UD_mirrorpos;

result_seq = seq;
end