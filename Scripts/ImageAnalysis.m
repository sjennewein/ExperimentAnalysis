clear all;
close all;

singleAtomFluoresence = 238 * 10;

addpath('..\functions\WinSpec\');
addpath('..\functions\fitting\');
addpath('..\functions\Visualize\');
addpath('..\functions\Analysis\');
addpath('..\classes\');

tic
result = ImageResult;
header = speread_header('C:\Users\stephan\Documents\data\Atoms_Micro_tof_40µs_651µW_90seq.SPE');
result.original = speread_frame(header,1);
frame = frame ./ singleAtomFluoresence;
frame = frame ./ 90;

ROI = [140 140; 270 270];

[backgroundFit, backCorrection] = FitBackground(frame,ROI);

flatImage = frame - backCorrection;
cloud = FitCloud(flatImage, ROI);
ShowROI(flatImage, ROI);

[x1, y1, z1] = prepareSurfaceData(140:270, 140:270, flatImage(140:270,140:270));
plot(cloud,[x1,y1],z1);
sum(sum(flatImage(140:270,140:270)))
quad2d(cloud,140,270,140,270)
toc