clear all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
addpath('..\functions\Networking');

picturesTaken  = 0;
picturesToTake = 200;
saveFolder     = 'D:\Manipe\';
runName        = 'blind';
time           = 1; %in ms
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
pictures = cell(1,picturesToTake);

h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1)
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1); %sets the ADC to 2MHz
pvcamset(h_cam,'PARAM_EXP_RES_INDEX',0); %sets the timebase to millisecond
pvcamset(h_cam,'PARAM_GAIN_INDEX',3); %sets the gain to max

for i=1:picturesToTake            
    tic;
    pictures{i} = roiparse(pvcamacq(h_cam,1,roi_struct,time,'strobe'),roi_struct);
    toc    
end

disp('waiting')
pause on;
pause(10);

background = roiparse(pvcamacq(h_cam,1,roi_struct,time,'timed'),roi_struct);

pvcamclose(h_cam);