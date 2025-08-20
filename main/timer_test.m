clear;
t = createErgoTimer;
start(t)

function t = createErgoTimer()
secondsBreak = 1;
secondsBreakInterval = 1;
secondsPerHour = 1;
secondsWorkTime = secondsPerHour;

t = timer;
t.UserData = secondsBreak;
t.StartFcn = @ergoTimerStart;
t.TimerFcn = @takeBreak;
t.StopFcn = @ergoTimerCleanup;
t.Period = secondsBreakInterval+secondsBreak;
t.StartDelay = t.Period-secondsBreak;
t.TasksToExecute = ceil(secondsWorkTime/t.Period);
t.ExecutionMode = 'fixedSpacing';
end

function ergoTimerStart(mTimer,~)
secondsPerMinute = 60;
secondsPerHour = 60;
str1 = 'Starting Ergonomic Break Timer.  ';
str2 = sprintf('For the next %d hours you will be notified',...
    round(mTimer.TasksToExecute*(mTimer.Period + ...
    mTimer.UserData)/secondsPerHour));
str3 = sprintf(' to take a %d second break every %d minutes.',...
    mTimer.UserData, (mTimer.Period - ...
    mTimer.UserData)/secondsPerMinute);
disp([str1 str2 str3])
end

function takeBreak(mTimer,~)
disp('Take a 30 second break.')
end

function ergoTimerCleanup(mTimer,~)
disp('Stopping Ergonomic Break Timer.')
delete(mTimer)
end
