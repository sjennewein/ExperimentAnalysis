function [ ] = EncircledEnergy( data )
%ENCIRCLEDENERGY Summary of this function goes here
%   Detailed explanation goes here
if(~iscell(data))
    error('Data must be a cell array!');
end

[dimY, dimX] = size(data{1}.flat);
[rr, cc] = meshgrid(1:dimX,1:dimY);

sigma = [0.682 0.954 0.997 0.999936 0.999999 0.999999998 0.999999999997];

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
        errorbar = confint(data{iData}.cloudFit,sigma(iSigma));
        xWidth = errorbar(1,xWidthIndex);
        yWidth = errorbar(1,yWidthIndex);
        radius = mean([xWidth yWidth]);
        mask = sqrt((rr-x0).^2+(cc-y0).^2)<=radius;
        encircled(iSigma) = sum(sum(data{iData}.flat .* mask));
    end
    figure;
    plot(encircled,'x-');
    hold on;
    limits = ylim;
    if(limits(1) < 0)
        ylim([limits(1) - 10 0]);
    else
        ylim([0 limits(2) + 10]);
    end
    hold off;
    
end
end

