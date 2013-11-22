clear all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');

time   = 240000; %in ms
h_cam  = pvcamopen(0);
x_size = pvcamgetvalue(h_cam,'PARAM_SER_SIZE');
y_size = pvcamgetvalue(h_cam,'PARAM_PAR_SIZE');

roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
tic;                         
image_data = pvcamacq(h_cam,1,roi_struct,time,'timed');
disp(toc);
pvcamclose(h_cam);
image_data = roiparse(image_data,roi_struct);
image(image_data/16);
