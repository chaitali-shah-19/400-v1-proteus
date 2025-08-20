function result_seq=set_srs(seq,srs_freq)
mw_channel_no = 39;
seq.Channels(mw_channel_no).FreqmodI = srs_freq;
result_seq = seq;
end