clear all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');

baseFolder = FolderOfTheDay();
MeasurementFolder = 'Exp1\';
RunName = 'Sat_Macro_tof_40µs_566µW_80seq';

time = 100000;

h_cam  = pvcamopen(0);
x_size = pvcamgetvalue(h_cam,'PARAM_SER_SIZE');
y_size = pvcamgetvalue(h_cam,'PARAM_PAR_SIZE');
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);

image_data = pvcamacq(h_cam,1,roi_struct,time,'timed');

pvcamclose(h_cam);
image_data = roiparse(image_data,roi_struct);

%Write data to file
currentFolder = strcat(baseFolder, MeasurementFolder);
currentFile = strcat(currentFolder, RunName);

csvFile = strcat(currentFile, '.csv');
matlabFile = strcat(currentFile, '.mat');

csvwrite(csvFile,image_data);
save(matlabFile, 'image_data');

%Visualize data
rescaleFactor = max(max(image_data))/64;
image(image_data/rescaleFactor);