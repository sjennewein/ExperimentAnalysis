clear all;
close all;

addpath('..\functions\WinSpec\');
addpath('..\functions\fitting\');
addpath('..\functions\Visualize\');
addpath('..\functions\Analysis\');
tic
header = speread_header('C:\Users\stephan\Documents\data\Atoms_Micro_tof_40µs_651µW_90seq.SPE');
frame = speread_frame(header,1);
[dimX, dimY] = size(frame);
ROI = [140 140; 270 270];
% ShowROI(frame, ROI);
% image(frame/128);
[backgroundFit, backCorrection] = FitBackground(frame,ROI);

flatImage = frame - backCorrection;
cloud = FitCloud(flatImage, ROI);
% plot(backgroundFit,[x,y],frame);
% image(flatImage/128);
toc