clear;
t = createErgoTimer;
start(t);
wait(t)
disp('end');

R= get(t, 'Running');
if isequal(R ,'on')
    pause(1);
end

function t = createErgoTimer()
t = timer;
t.StartFcn = @(~,~) disp('Starting timer');
t.TimerFcn = @(~,~) disp('Shuttler should have moved up');
t.StopFcn = @ergoTimerCleanup;
% t.StopFcn = @(~,~) [flag=1; delete(t)];
t.StartDelay = 5;
t.ExecutionMode = 'singleshot';

end

function flag=ergoTimerCleanup(mTimer,~)
flag=1
disp('Stopping Ergonomic Break Timer.')
% delete(mTimer)
end


