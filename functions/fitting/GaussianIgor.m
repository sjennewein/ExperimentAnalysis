function F = GaussianIgor( x,p )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    yOffset = p(1);
    amplitude = p(2);
    xOffset = p(3);
    width = p(4);
    
    F = yOffset + amplitude * exp( - (x - xOffset).^2/(2*width^2));

end

