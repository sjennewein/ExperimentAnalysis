clear all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
% 
% baseFolder = FolderOfTheDay();
% MeasurementFolder = 'Exp1\';
% RunName = 'Sat_Macro_tof_40µs_566µW_80seq';

time = 1;
pictures = 20;
images_data = cell(1,pictures);

h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1)

% x_size = pvcamgetvalue(h_cam,'PARAM_SER_SIZE');
% y_size = pvcamgetvalue(h_cam,'PARAM_PAR_SIZE');
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);                                      
for i = 1:pictures
tic;     
images_data{i} = pvcamacq(h_cam,1,roi_struct,time,'strobe');
toc
end
pvcamclose(h_cam);
% images = roiparse(image_data,roi_struct);

%Write data to file
% currentFolder = strcat(baseFolder, MeasurementFolder);
% currentFile = strcat(currentFolder, RunName);
% 
% csvFile = strcat(currentFile, '.csv');
% matlabFile = strcat(currentFile, '.mat');
% 
% csvwrite(csvFile,image_data);
% save(matlabFile, 'image_data');

%Visualize data
% imagesc(images(:,:,1));