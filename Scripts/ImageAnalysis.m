clear all;
close all;

singleAtomFluoresence = 238;

addpath('..\functions\WinSpec\');
addpath('..\functions\fitting\');
addpath('..\functions\Visualize\');
addpath('..\functions\Analysis\');

tic
header = speread_header('C:\Users\stephan\Documents\data\Atoms_Micro_tof_40µs_651µW_90seq.SPE');
frame = speread_frame(header,1);
frame = frame ./ singleAtomFluoresence;
frame = frame ./ 90;

ROI = [140 140; 270 270];

[backgroundFit, backCorrection] = FitBackground(frame,ROI);

flatImage = frame - backCorrection;
cloud = FitCloud(flatImage, ROI);
ShowROI(flatImage, ROI);

[x1, y1, z1] = prepareSurfaceData(1:400, 1:400, flatImage);
plot(cloud,[x1,y1],z1);
sum(sum(flatImage(140:270,140:270)))
toc