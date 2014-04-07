close all;
clear all;

addpath(genpath('C:\Users\stephan\Documents\FrenchyMatlab'))

folder = 'C:\tmp\friday\';
files = dir(strcat(folder,'*.spe'));
roi = [80 80; 205 235];
adu = 238;
exposure = 10;

analyzed = cell(1,numel(files));
for i=1:numel(files)
    picture = speread_header(strcat(folder,files(i).name));
    picture = speread_frame(picture,1);
%     load(strcat(folder,files(i).name));
    [pName, pValue, pUnit] = parameterFromFilename(files(i).name);
    indexSequences = getIndexOfParameter('nseq',pName);
    indexSaturation = getIndexOfParameter('sat',pName);
    saturation = pValue(indexSaturation);
    sequences = pValue(indexSequences);
    analyzed{i} = ImageResult(cast(picture(5:end-5,5:end-5),'double'),roi,adu,saturation,exposure,sequences,pName,pValue,pUnit);
end