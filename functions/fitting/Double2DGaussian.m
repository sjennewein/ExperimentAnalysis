function [ F ] = Double2DGaussian( x, y, p )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    yOffset    = p(1);
    
    amplitude1 = p(2);    
    x1Offset   = p(3);
    y1Offset   = p(4);
    x1Width    = p(5);
    y1Width    = p(6);
    
    amplitude2 = p(7);
    x2Offset   = p(8);
    y2Offset   = p(9);
    x2Width    = p(10);
    y2Width    = p(11);
    
    F = yOffset ...
        + amplitude1 * exp(- 1/2 * (((x - x1Offset)/x1Width)^2 + ((y - y1Offset)/y1Width)^2)) ...
        + amplitude2 * exp(- 1/2 * (((x - x2Offset)/x2Width)^2 + ((y - y2Offset)/y2Width)^2));
end

