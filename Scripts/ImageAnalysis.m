clear all;
close all;

singleAtomFluoresence = 238 * 10;

addpath('..\functions\WinSpec\');
addpath('..\functions\fitting\');
addpath('..\functions\Visualize\');
addpath('..\functions\Analysis\');
addpath('..\classes\');


folder = 'C:\Temp\Exp2\';
files = dir(strcat(folder,'*.SPE'));

nrOfFiles = numel(files);
analyzed = cell(1,nrOfFiles);
roi = [80 80;310 310];
adu = 238;
saturation = 1;
sequences = 100;

for i=1:nrOfFiles
    header = speread_header(strcat(folder,files(i).name));
    picture = speread_frame(header,1);
    analyzed{i} = ImageResult(picture, roi, adu, saturation, sequences, files(i).name);    
end


atomsPicture = zeros(1,nrOfFiles);
atomsFit = zeros(1,nrOfFiles);

for i = 1:nrOfFiles
    atomsPicture(i) = analyzed{i}.AtomsFromPicture;
    atomsFit(i) = analyzed{i}.AtomsFromFit;
end

% result.original = speread_frame(header,1);
% frame = frame ./ singleAtomFluoresence;
% frame = frame ./ 90;
% 
% ROI = [140 140; 270 270];
% 
% [backgroundFit, backCorrection] = FitBackground(frame,ROI);
% 
% flatImage = frame - backCorrection;
% cloud = FitCloud(flatImage, ROI);
% ShowROI(flatImage, ROI);
% 
% [x1, y1, z1] = prepareSurfaceData(140:270, 140:270, flatImage(140:270,140:270));
% plot(cloud,[x1,y1],z1);
% sum(sum(flatImage(140:270,140:270)))
% quad2d(cloud,140,270,140,270)
% toc