import PulseStreamer.*;
ip = '169.254.8.2';
ps=PulseStreamer(ip);
ps.reset(); 

stPB=[0 2 5 0];
durPB=[ 0.0000    0.0200    0.1000    0.0000];

[pattern0, pattern1, pattern2] = make_swabian_pattern (stPB, durPB);

sequence = Sequence();

sequence.setDigital(0, pattern0);
sequence.setDigital(1, pattern1);
sequence.setDigital(2, pattern2);

sequence = sequence.repeat(1); 

n_runs =1;

finalState = OutputState([],0,0);

ps.stream(sequence, n_runs, finalState);

pause(1.1*sum(durPB));

ps.reset();
