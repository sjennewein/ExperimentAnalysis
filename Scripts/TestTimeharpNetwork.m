clear all;

import java.net.Socket
import jave.io.*

addpath('..\functions');
addpath('..\functions\Networking');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
addpath('..\functions\TimeHarp');

baseFolder = FolderOfTheDay();
MeasurementFolder = 'Exp1\';
RunName = 'Test';

%Set network parameters
host = '10.117.50.202';
port = 9898;

%Picture parameter
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
expTime = 1;
background = load('readOutNoiseCCD.mat');
h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1); %sets the ADC to 2MHz
disp('Initialized Camera');

%Initialize Timeharp
InitializeStandard(1000,20,20,-100,0,0);
disp('Intialized Timeharp');

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
run = 0;
while(1==1)
    disp('Waiting for trigger');
    TcpWrite(outgoingStream, 'Trigger');
    disp('wait');
    disp(TcpRead(incomingStream));
    disp(TcpRead(incomingStream));
    TcpWrite(outgoingStream, 'BLABLA');
    disp('Run started');
    %acquire data for one run
    for i = 1:cyclesPerRun
        StartStandard();
        pictures{i} = pvcamacq(h_cam,1,roi_struct,expTime,'strobe');
        [hist, resolution] = ReadStandard();
        timeharp{i} = hist;
        disp(i);
    end
       
    filename = strcat(RunName,'_',num2str(run),'.mat');
    mkdir(strcat(baseFolder,MeasurementFolder));
    fileLocation = strcat(baseFolder,MeasurementFolder,filename);
    save(fileLocation,'pictures','hist','resolution');
    disp('Data saved');
    run = run + 1;
end
pvcamclose(h_cam);