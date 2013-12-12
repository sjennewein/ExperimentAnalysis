function [ F ] = Gaussian2D( x,y,p )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    yOffset = p(1);
    amplitude = p(2);
    cor = p(3);
    
    x0 = p(4);
    xWidth = p(5);
    
    y0 = p(6);
    yWidth = p(7);
    
    F =   yOffset ...
        + amplitude * exp ( -1/(2 * (1 - cor^2)) ...
        * (((x-x0) / xWidth)^2 ...
        + ((y-y0) / yWidth)^2 ...
        - (2 * cor * (x-x0) * (y-y0)) / (xWidth * yWidth)));
        
end

