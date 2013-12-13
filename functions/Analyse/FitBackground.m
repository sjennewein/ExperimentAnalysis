function [ output_args ] = FitBackground( input_args )
%FITBACKGROUND Summary of this function goes here
%   Detailed explanation goes here
    background = frame .* backgroundROI;
    [x,y,z] = prepareSurfaceData(1:400, 1:400, background);

end

