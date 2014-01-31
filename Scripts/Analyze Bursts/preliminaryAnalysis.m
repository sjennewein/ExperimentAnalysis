clear all;

addpath('../../functions');
addpath('../../classes');

folder = 'C:\Users\stephan\Documents\Measurements\1412014\Exp2\Exp2\';

files = dir(strcat(folder,'*.mat'));

finalHistogram = zeros(1,4096,'uint32');

for i = 1:numel(files)
    load(strcat(folder,files(i).name));
    finalHistogram = finalHistogram + summedHistogram;
%     atom = ImageResult(cast(summedPicture,'double'), [150 150;300 300], 238, 0.1);
%     atom.AtomsFromPicture
end

%%
binFactor = 20;

binnedHisto = binning(finalHistogram,binFactor);
xAxis = (1:numel(binnedHisto)) * resolution * binFactor;
plot(xAxis, binnedHisto);