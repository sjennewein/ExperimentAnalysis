function [ backgroundFit, backgroundCorrection ] = FitBackground( picture, ROI )
%FITBACKGROUND Fits a second order 2D polynomial to a picture background
%   picture = 2D matrix
%   ROI = x1,y1 and x2,y2 for the region of interest
    
    [dimX, dimY] = size(picture);
    
    %generate mask to select the background
    backROI = ones(dimX,dimY);
    
    %exclude cloud
    roiX = (ROI(2,1)-ROI(1,1))+1;
    roiY = (ROI(2,2)-ROI(1,2))+1;
    cloudMask = NaN(roiX,roiY);
    backROI(ROI(1,1):ROI(2,1),ROI(1,2):ROI(2,2)) = cloudMask;
    
    %apply roi mask
    background = picture .* backROI;
    
    %prepare data for fitting and fit
    [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, background);
    backgroundFit = fit([x,y],z,'poly44');
    
    %generate background correction matrix
    [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, picture);
    backgroundCorrection = reshape(feval(backgroundFit,x,y),dimX,dimY);
end

