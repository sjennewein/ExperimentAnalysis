clear all;
close all;

addpath('../../functions');
addpath('../../classes');
addpath('../../functions/ccd');
addpath('../../functions/ccd/pvcam');

folder = 'C:\Temp\Exp4\';

files = dir(strcat(folder,'*.mat'));
roi = [80 80;310 310];
adu = 238;
saturation = 1.6;
sequences = 100;

finalHistogram = zeros(1,4096,'uint32');
nrAtoms = zeros(1,numel(files));
for i = 1:numel(files)
    load(strcat(folder,files(i).name));    
       result = ImageResult(cast(summedPicture,'double'),roi,adu,saturation,sequences,files(i).name);
%      disp(result.AtomsFromPicture);
%     nrAtoms(i) = result.AtomsFromPicture;
       if(result.AtomsFromPicture >= 18 )
        finalHistogram = finalHistogram + summedHistogram;
       end
%     atom = ImageResult(cast(summedPicture,'double'), [150 150;300 300], 238, 0.1);
%     atom.AtomsFromPicture
end


%%
binFactor = 20;

binnedHisto = binning(finalHistogram,binFactor);
xAxis = (1:numel(binnedHisto)) * resolution * binFactor;
plot(xAxis, binnedHisto);
figure
semilogy(xAxis,binnedHisto,'x');