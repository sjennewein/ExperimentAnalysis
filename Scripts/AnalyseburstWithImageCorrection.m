close all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');

foldername = 'C:\Documents and Settings\Joseph\Bureau\Aspherix\Data\2014\Janvier\20140117\';
files = dir(strcat(foldername,'*.mat'));

load('readOutNoiseCCD.mat');
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2); 

Images = cell(1,100);  
CorrImages = cell(1,100);
finalImage = zeros(400,400,'uint32');
CorrfinalImage = zeros(400,400,'uint32');

edges=0:20:3000;
Imagehistogram=zeros(1,length(edges));

finalTHhistogram = zeros(1,4096,'uint32');

threshold=0;

h = waitbar(0,'Please wait...');
steps=10; %numel(files);
for j=1:10 %numel(files)
    waitbar(j/steps)
    load(strcat(foldername,files(j).name));

    for i= 1:100
        Images{i} = roiparse(pictures{i},roi_struct); % no correction
        finalImage =  finalImage + cast(Images{i},'uint32');
        
        Imagehistogram=Imagehistogram+histc(reshape(Images{i},1,[]),edges);
        
        CorrImages{i} = roiparse(pictures{i},roi_struct);  % with correction
        CorrImages{i}(CorrImages{i}<threshold)=0;
        CorrfinalImage =  CorrfinalImage + cast(CorrImages{i},'uint32');
        
        finalTHhistogram = finalTHhistogram + summedHistogram;
    end
end
close(h)

xaxis=1:400;
yaxis=1:400;
[Xout,Yout,Zout]=prepareSurfaceData(xaxis,yaxis,CorrfinalImage);
csvwrite('test_thres_0.csv',[Xout,Yout,Zout]);

%figure;
%plot(finalHistogram);
%figure;
%imagesc(finalImage);
%title('Without correction');
%colorbar;
%figure;
%imagesc(CorrfinalImage);
%colorbar;
%title('With correction');
%colorbar;

bar(edges,Imagehistogram,'BarWidth',1)

