% Data processing for data coming from OVJ as .dx file

clear; clc;

% Read files in (from Data folder)

% Try to make a new fxn similar to agilent_read_proteus
% Working 4/13/22
    % create the limits of which files to grab
    explimits{1}='2022-04-13_11.45.08_fidecay';
    explimits{2}='2022-04-13_13.50.00_fidecay';
    % tells you what experiment it is
    % varied center freq of microwave sweep:
    inputArray=2.20:0.01:2.35;
    % use OVJ_read_dx to bring files in
    selected_files= transpose(OVJ_read_dx(explimits));

inputArray=inputArray(1:size(selected_files,1)); % truncate inputArray to size of selected_files
clear IX
[inputArray,IX]=sort(inputArray); % sort inputArray from low to high
selected_files=selected_files(IX); % sort selected_files in the same way inputArray got re-sorted

% Extract data
for j = 1:length(inputArray)

[X2{j},Y2{j},S(j)] = process_data_OVJ(selected_files{j},inputArray(j));

% figures for troubleshooting
%figure(3);clf;plot(X2{1}/1e3,abs(Y2{1}),'r-');plot_labels('Frequency[kHz]','FT Signal')
%set(gca,'xlim',[0,20]);

end

% Plot results
start_fig(1,[3,2]); % what does this do???
p = plot_preliminaries(inputArray,S,2); set(p,'markersize',5);
plot_labels('microwave center freq [GHz]','Total Signal [au]');
set(gca,...
    'xlim',[2.2,2.35],...
    'ylim',[0,2E4],...
    'yscale','linear')

%% FUNCTIONS
function [X2,Y2,S] = process_data_OVJ(selected_files1,input)

% read file into structure format
jcampStruct = jcampread(['C:\Users\Anika\Documents\MATLAB\Data\' selected_files1]);

% Extract time data vs signal
x = jcampStruct.Blocks.XData; % time data
y = jcampStruct.Blocks.YData; % raw signal
% plotting these against each other gives us the FID raw signal/noisy
% damped sine

% Calculate variables that are useful to us
dt=x(2)-x(1); % length of time between points/ step size in time
T=x(end); % Total length of time of experiment
df=1/T; % step size in frequency
T2=2e-3; % 2 ms - length of time that we expect signal to last, used for appodization

% Prepare our time domain signal
y_app=y.*exp(-x/T2); % appodization - weighting the good signal that we get at the start more heavily

% Fast Fourier transform data and reorder it so that negative freq on LHS
Y=fft(y_app);
%Y=real(fftshift(Y)); % do we need to only do the real part? Compare later
Y = fftshift(Y);

% More calculated variables that are useful to us
n=length(Y); % number of points - should be conserved before and after fft
X=(-n/2:n/2-1)*(1/dt)*1/n; % Calculating frequency axis
X2=X(1,floor(n/2):end); % Truncate so that we only get the positive freqs
Y2=Y(1,floor(n/2):end);

% Plots to help troubleshoot
% figure(2);clf;plot( X(1,floor(n/2):end),abs(Y(1,floor(n/2):end)),'r-');plot_labels('Frequency[Hz]','FT Signal')
% figure(2);clf;plot( X2/1e3,abs(Y2),'r-');plot_labels('Frequency[kHz]','FT Signal')
% set(gca,'xlim',[0,20]);

% First time that this was run (and any time we change parameters), we need
% to check what frequency (and what index) our signal is at!
% On 4/13/22, max signal was at index 37
%[v,b]=max(abs(Y2));
%freq_max=X2(b);
S=abs(Y2(37)); % S is the signal maximum

end