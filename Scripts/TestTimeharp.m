clear all;

addpath('..\functions');
addpath('..\functions\TimeHarp');

pause on;

InitializeStandard(120000,20,20,-100,0,2);
StartStandard();
pause(120);
[hist, resolution] = ReadStandard();
plot(hist);




