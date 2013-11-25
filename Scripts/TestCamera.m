clear all;

import java.net.Socket
import jave.io.*

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');
addpath('..\functions\Networking');

host = '10.117.50.202';
port = 9898;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                        %
%       Variables have to be adjusted    % 
%                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

picturesTaken  = 0;
picturesToTake = 2;
saveFolder     = 'D:\test\';
runName        = 'blind';
time           = 120000; %in ms

connection = Socket(host,port);
incomingStream = connection.getInputStream;
outgoingStream = connection.getOutputStream;
TcpWrite(outgoingStream,'Register');    
TcpRead(incomingStream);

TcpWrite(outgoingStream, 'CCDCamera');
TcpRead(incomingStream);

while(picturesTaken < picturesToTake)
    
%     h_cam  = pvcamopen(0);
%     x_size = pvcamgetvalue(h_cam,'PARAM_SER_SIZE');
%     y_size = pvcamgetvalue(h_cam,'PARAM_PAR_SIZE');
    roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
    disp('waiting for trigger');
    TcpWrite(outgoingStream, 'WaitingForTrigger');
    TcpRead(incomingStream);
   
    TcpRead(incomingStream);
    TcpWrite(outgoingStream, 'Ack');
    disp('trigger ack');
    
    tic;
%     image_data = pvcamacq(h_cam,1,roi_struct,time,'timed');
    pause(30);
    disp(toc);    
%     pvcamclose(h_cam);
%     currentFile = strcat(saveFolder, runName, int2str(picturesTaken));
%     image_data = roiparse(image_data,roi_struct);
%     save(currentFile, 'image_data');    
    disp('next round');
end

TcpWrite(outgoingStream,'UnRegister');    
TcpRead(incomingStream);

TcpWrite(outgoingStream, 'CCDCamera');
TcpRead(incomingStream);
     
TcpWrite(outgoingStream, 'Disconnect');     
% 
                       
% 

% 
% image(image_data/16);
