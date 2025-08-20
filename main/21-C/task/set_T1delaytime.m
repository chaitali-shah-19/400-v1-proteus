function result_seq=set_T1delaytime(seq,T1delay_time)

mw_channel_no = 24;
seq.Channels(mw_channel_no).Phase = T1delay_time;

result_seq = seq;
end