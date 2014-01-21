clear all;

addpath('D:/Matlab/functions');

folder = 'D:/Manipe/2014/Janvier/2014121/Exp2/';

files = dir(strcat(folder,'*.mat'));

finalHistogram = zeros(1,4096,'uint32');

for i = 1:numel(files)
    load(strcat(folder,files(i).name));
    finalHistogram = finalHistogram + summedHistogram;
end
    
binFactor = 10;

binnedHisto = binning(finalHistogram,binFactor);
xAxis = (1:numel(binnedHisto)) * resolution * binFactor;
plot(xAxis, binnedHisto);