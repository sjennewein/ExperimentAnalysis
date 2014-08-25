function [ ] = EncircledEnergy( data )
%ENCIRCLEDENERGY Summary of this function goes here
%   Detailed explanation goes here
if(~iscell(data))
    error('Data must be a cell array!');
end

[dimY, dimX] = size(data{1}.flat);
[rr, cc] = meshgrid(1:dimX,1:dimY);

sigma = [0.1 0.5 1 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10];

for iData = 1:numel(data)
    encircled = zeros(1,numel(sigma));
    x0Index = getIndexOfParameter('x0',coeffnames(data{iData}.cloudFit));
    y0Index = getIndexOfParameter('y0',coeffnames(data{iData}.cloudFit));
    xWidthIndex = getIndexOfParameter('xWidth',coeffnames(data{iData}.cloudFit));
    yWidthIndex = getIndexOfParameter('yWidth',coeffnames(data{iData}.cloudFit));
    coeff = coeffvalues(data{iData}.cloudFit);
    x0 = round(coeff(x0Index));
    y0 = round(coeff(y0Index));

    for iSigma = 1:numel(sigma)        
        xWidth = coeff(xWidthIndex);
        yWidth = coeff(yWidthIndex);
        radius = round(mean([xWidth yWidth])/2);
        mask = ((rr-x0).^2+(cc-y0).^2)<= (sigma(iSigma)*radius)^2;    
        figure;
        imagesc(mask);
        encircled(iSigma) = sum(sum(data{iData}.flat .* mask));
    end
    figure;
    plot(sigma, encircled,'x-');
    hold on;
    xlabel('n x width');
    ylabel('Encircled Energy');
    limits = ylim;
    if(limits(1) < 0)
        ylim([limits(1) - 10 0]);
    else
        ylim([0 limits(2) + 10]);
    end
    hold off;
    
end
end