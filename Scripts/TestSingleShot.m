clear all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
% 
% baseFolder = FolderOfTheDay();
% MeasurementFolder = 'Exp1\';
% RunName = 'Sat_Macro_tof_40µs_566µW_80seq';
load('readOutNoiseCCD.mat');

expTime = 1;
pictures = 100;
images_data = cell(1,pictures);

h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1)

roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);                                      
for i = 1:pictures
tic;     
images_data{i} = pvcamacq(h_cam,1,roi_struct,expTime,'strobe');
toc
disp(i);
end
pvcamclose(h_cam);

%% postprocessing
processedImage = cell(1,pictures);  
finalImage = zeros(400,400,'uint32');

for i= 1:pictures
    processedImage{i} = roiparse(images_data{i},roi_struct);    
    finalImage =  finalImage + cast(processedImage{i} - bckg,'uint32');
end

imagesc(finalImage);