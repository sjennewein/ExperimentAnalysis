function F = GaussianIgor_width90(x,p)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    yOffset = p(1);
    amplitude = p(2);
    xOffset = p(3);
    width = 90;
    
    F = yOffset + amplitude * exp( - ((x - xOffset)/width).^2);

end

