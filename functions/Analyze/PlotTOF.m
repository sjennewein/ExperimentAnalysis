function [time, xWidth, yWidth] = PlotTOF( data )
%[time, xWidth, yWidth] = PlotTOF(data)
%plots the width vs time-of-flight and returns the fit data
if(~iscell(data))
    unc('Data must be a cell array!');
end

xWidth = zeros(1,numel(data));
yWidth = zeros(1,numel(data));
time   = zeros(1,numel(data));

for iData = 1:numel(data)
    tofIndex = getIndexOfParameter('tof', data{iData}.pName);
    time(iData) = data{iData}.pValue(tofIndex);
    coeff = coeffvalues(data{iData}.cloudFit);
    xWidth(iData) = coeff(4);
    yWidth(iData) = coeff(6);
end

pixelsize = 0.5; %each pixel corresponds to 0.5 micrometer at the atoms
xWidth = xWidth * pixelsize;
yWidth = yWidth * pixelsize;

%fit options
ft = fittype( 'sqrt(sigma0^2+((temp*(1.38E-23))/(1.44E-25))*time^2)', 'independent', 'time', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.StartPoint = [2.3 1e-06];

[xData, yData] = prepareCurveData( time, xWidth );
[xWidthFitResult, xWidthGof] = fit( xData, yData, ft, opts );

[xData, yData] = prepareCurveData( time, yWidth );
[yWidthFitResult, yWidthGof] = fit( xData, yData, ft, opts );

xcoeffname = coeffnames(xWidthFitResult);
xcoeff     = coeffvalues(xWidthFitResult);
xconfint   = confint(xWidthFitResult,0.68);

ycoeffname = coeffnames(yWidthFitResult);
ycoeff     = coeffvalues(yWidthFitResult);
yconfint   = confint(yWidthFitResult,0.68);


output = '';
unit = {' µm', ' K'};
for iCoeff = 1:numel(xcoeffname)
    unc = abs(xcoeff(iCoeff) - xconfint(1,iCoeff));
    output = [output, 'X', xcoeffname{iCoeff},' = ', ...
        num2str(xcoeff(iCoeff)), char(177), ...
        num2str(unc), unit{iCoeff}, char(10)];
    
    unc = abs(ycoeff(iCoeff) - yconfint(1,iCoeff));
    output = [output, 'Y', ycoeffname{iCoeff},' = ', ...
        num2str(ycoeff(iCoeff)), char(177),...
        num2str(unc), unit{iCoeff}, char(10), char(10)];
end


output = output(1:end-2);
figure('name','Time of flight');
hold on;
plot(feval(xWidthFitResult,0:max(xData)),'b');
plot(xData,xWidth,'Ob');
plot(feval(yWidthFitResult,0:max(xData)),'r');
plot(xData,yWidth,'*r');
title('Time of flight');
annotation('Textbox', [0.15 0.8 0.1 0.1], 'String', output);
legend('xWidth', 'xWidthFit', 'yWidth', 'yWidthFit', 'Location', 'Best');
xlabel(strcat('Time [', data{1}.pUnit(tofIndex),']'));
ylabel('Width [µm]');
hold off;
end

