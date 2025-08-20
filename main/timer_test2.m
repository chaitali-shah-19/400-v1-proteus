clear;
t = createErgoTimer;
start(t)

function t = createErgoTimer()
t = timer;
t.StartFcn = @(~,~) disp('Starting timer');
t.TimerFcn = @(~,~) disp('Shuttler should have moved up');
t.StopFcn = @ergoTimerCleanup;

t.StartDelay = 5;
t.ExecutionMode = 'singleshot';

end

function ergoTimerStart(mTimer,~)
str1 = 'Starting Ergonomic Break Timer.  ';
disp(str1)
end

function timer_execute(mTimer,~)
disp('Doing stuff')
end

function ergoTimerCleanup(mTimer,~)
disp('Stopping Ergonomic Break Timer.')
delete(mTimer)
end
