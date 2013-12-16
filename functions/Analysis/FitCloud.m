function [ fitResult ] = FitCloud( picture, ROI )
%FITCLOUD Summary of this function goes here
%   Detailed explanation goes here
    [dimX, dimY] = size(picture);
    mask = NaN(dimX,dimY);
    roiX = (ROI(2,1)-ROI(1,1))+1;
    roiY = (ROI(2,2)-ROI(1,2))+1;
    cloudMask = ones(roiX,roiY);
    mask(ROI(1,1):ROI(2,1),ROI(1,2):ROI(2,2)) = cloudMask;
    
    cloud = picture .* mask;
    [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, cloud);
    
    ft = fittype(['z0' ...
                  ,'+ a * exp ( -1/(2 * (1 - cor^2))' ...
                  ,'* (((x-x0) / xWidth)^2' ...
                  ,'+ ((y-y0) / yWidth)^2' ...
                  ,'- (2 * cor * (x-x0) * (y-y0)) / (xWidth * yWidth)))'], ...
                  'independent',{'x', 'y'}, 'dependent', 'z');
    opts = fitoptions( ft );
    opts.Algorithm = 'Levenberg-Marquardt';
    opts.Display = 'Off';
    opts.Lower = [-Inf -Inf -Inf -Inf -Inf -Inf];
    opts.MaxFunEvals = 600;
    opts.MaxIter = 1000;
    
    
    a_start = 3000;
    cor_start = 0;
    x0_start = 200;
    xWidth_start = 10;
    y0_start = 200;
    yWidth_start = 10;
    z0_start = -3;
    
    opts.StartPoint = [ a_start cor_start x0_start xWidth_start ...
                       y0_start yWidth_start z0_start];
    opts.Upper = [Inf Inf Inf Inf Inf Inf];
    
    [fitResult, gof] = fit( [x, y], z, ft, opts )
    [x1, y1, z1] = prepareSurfaceData(1:dimX, 1:dimY, picture);
    
   1+1;
end

