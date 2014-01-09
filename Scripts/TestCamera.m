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
picturesToTake = 100;
saveFolder     = 'D:\test\';
runName        = 'blind';
time           = 1; %in ms
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2);
pictures = cell(1,picturesToTake);

h_cam  = pvcamopen(0);
pvcamset(h_cam,'PARAM_SPDTAB_INDEX',1)

% connection = Socket(host,port);
% incomingStream = connection.getInputStream;
% outgoingStream = connection.getOutputStream;
% TcpWrite(outgoingStream,'Register');    
% TcpRead(incomingStream);
% 
% TcpWrite(outgoingStream, 'CCDCamera');
% TcpRead(incomingStream);

for i=1:picturesToTake        
%     TcpWrite(outgoingStream, 'WaitingForTrigger');
%     TcpRead(incomingStream);
%    
%     TcpRead(incomingStream);
%     TcpWrite(outgoingStream, 'Ack');
%     disp('trigger ack');
    
    tic;
    pictures{i} = pvcamacq(h_cam,1,roi_struct,time,'strobe');
    toc
%     
%     currentFile = strcat(saveFolder, runName, int2str(picturesTaken));
%     image_data = roiparse(image_data,roi_struct);
%     save(currentFile, 'image_data');    
    disp('next round');
end
pvcamclose(h_cam);

% TcpWrite(outgoingStream,'UnRegister');    
% TcpRead(incomingStream);
% 
% TcpWrite(outgoingStream, 'CCDCamera');
% TcpRead(incomingStream);
%      
% TcpWrite(outgoingStream, 'Disconnect');     
% 
                       
% 

% 
% image(image_data/16);
