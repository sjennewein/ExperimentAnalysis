clear all;
close all;

addpath('..\functions');
addpath('..\functions\ccd');
addpath('..\functions\ccd\pvcam');

foldername = 'C:\Documents and Settings\Joseph\Bureau\Aspherix\Data\2014\Janvier\20140117\';
files = dir(strcat(foldername,'*.mat'));
roi_struct = cell2struct({466 ,865 , 1    , 178,577 , 1}, ...
                         {'s1','s2','sbin','p1','p2','pbin'},2); 
threshold=450;
processedImage = cell(1,100);  
finalImage = zeros(400,400,'uint32');
finalHistogram = zeros(1,4096,'uint32');

for j=1:numel(files)
finalImage = zeros(400,400,'uint32');
load(strcat(foldername,files(j).name));
    for i=1:100
        processedImage{i} = roiparse(pictures{i},roi_struct);    
        P=processedImage{i};
        P(P<threshold)=0;
        finalImage =  finalImage + cast(P,'uint32');
    end;
finalHistogram = finalHistogram + summedHistogram;

%figure;
%imagesc(finalImage);
%colorbar;

end;

figure;
plot(finalHistogram);



