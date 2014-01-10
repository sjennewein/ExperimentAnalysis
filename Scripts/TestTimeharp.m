clear all;

addpath('..\functions');
addpath('..\functions\TimeHarp');

pause on;

InitializeStandard(1000,20,20,-100,0,0);
StartStandard();
pause(1);
[hist, resolution] = ReadStandard();
plot(hist);




