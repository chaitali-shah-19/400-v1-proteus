% NV freq. swept sim
clear; clc;

Sys.S = 1;
Sys.g = 2;
Sys.D = 2870; % in MHz
Sys.Nucs = '13C'; %arb nuc
Sys.A = 1; % arb HFI
Sys.lw = 30; 
Exp.Field = 70;
Exp.CenterSweep = [2.1 4]; % [center freq   bandwidth] in ghz
Exp.nPoints = 5024; %arb
Exp.Harmonic = 0; %Abs spectrum
Opt.Verbosity  = 1;
%Exp.CrystalSymmetry = 47; % 227 for diamond
Exp.MolFrame = [0 0 0];
Exp.CrystalOrientation = [0 54 0]*pi/180; %[alpha beta gamma]
Opt.Method = 'matrix';
Opt.nKnots = [65 6];
%Opt.Sites = [1 3]; %24 magnetically distinct sites in unit cell
[fa,fb] = pepper(Sys,Exp,Opt);

plot(fa,fb);