clear all;

import java.net.Socket
import jave.io.*

addpath('..\functions');
addpath('..\functions\Networking');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
addpath('..\functions\TimeHarp');

baseFolder = FolderOfTheDay();
MeasurementFolder = 'Exp3\';
RunName = 'Burst340Atoms_Sat_0.1S_nseq_1000seq_bursts_1burst'; %S = 0.1 for the timeharp and S=1.5 for the picture
parameter = csvread('D:\Manipe\2014\Avril\20140411\Exp4\frequency.txt');
%Set network parameters
host = '10.117.50.202';
port = 9898;

%Picture parameter
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
expTime = 6;
% load('readOutNoiseCCD14117.mat');

h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1); %sets the ADC to 2MHz
pvcamset(h_cam,'PARAM_EXP_RES_INDEX',0); %sets the timebase to millisecond
pvcamset(h_cam,'PARAM_GAIN_INDEX',3); %sets the gain to max

disp('Initialized Camera');

% %Initialize Timeharp
% InitializeStandard(1000000,20,20,-100,0,2);
% disp('Intialized Timeharp');

%Initialize Network
connection = Socket(host,port);
incomingStream = connection.getInputStream;
outgoingStream = connection.getOutputStream;

TcpWrite(outgoingStream,'Register');    
TcpRead(incomingStream);
TcpWrite(outgoingStream, 'CCDCamera');
TcpRead(incomingStream);

TcpWrite(outgoingStream, 'CyclesPerRun');
TcpRead(incomingStream);
cyclesPerRun = str2num(TcpRead(incomingStream));
TcpWrite(outgoingStream, 'ACK');
disp('Initialized Network');

pictures = cell(1,cyclesPerRun);
timeharp = cell(1,cyclesPerRun);

pause(2);
%enter data acquisition
run = 1;
while(1==1)
    disp('Waiting for trigger');
    TcpWrite(outgoingStream, 'Trigger');
    disp('wait');
    disp(TcpRead(incomingStream));
    trigger = TcpRead(incomingStream);          
    TcpWrite(outgoingStream, 'BLABLA');
    
    if(strcmp(trigger,'Finished') == 1)
        disp('Measurement finished');
        break;
    end
    
    disp('Run started');
%     StartStandard();
    %acquire data for one run
    for i = 1:cyclesPerRun
        
        pictures{i} = pvcamacq(h_cam,1,roi_struct,expTime,'strobe');
        disp(i);
    end
%     [hist, resolution] = ReadStandard();  
    bckg = pvcamacq(h_cam,1,roi_struct,expTime,'timed');
    background = cast(roiparse(bckg,roi_struct),'int32');
    background(background>1.1*mean(mean(background))) = mean(mean(background)); %set spikes (spurious photons) to the average value
    summedPicture = zeros(400,400,'int32');    
    for i = 1:cyclesPerRun
        summedPicture = summedPicture + cast(roiparse(pictures{i},roi_struct),'int32');% - background; %no background subtraction it screws up our picture
    end
    
    filename = strcat(RunName,'_freq_',num2str(parameter(run)),'MHz_nr_',num2str(run),'run.mat');
    mkdir(strcat(baseFolder,MeasurementFolder));
    fileLocation = strcat(baseFolder,MeasurementFolder,filename);
    save(fileLocation,'summedPicture', 'roi_struct', 'cyclesPerRun', 'background');
    disp('Data saved');
    run = run + 1;
end
pvcamclose(h_cam);