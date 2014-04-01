function PlotWidthVS( parameter, data )
%PlotWidthVS(parameter,data) plots the width from the fit vs the given
%parameter
%parameter is the name of the parameter
%data is a cell array 
    if(~iscell(data))
        error('Data must be a cell array!');
    end
    
    if(~ischar(parameter))
        error('Parameter name must be a character.');
    end

    xAxis  = zeros(1,numel(data));
    xWidth = zeros(1,numel(data));
    yWidth = zeros(1,numel(data));
    
    for iData = 1:numel(data)        
        paramIndex = getIndexOfParameter(parameter, data{iData}.pName);
        xAxis(iData) = data{iData}.pValue(paramIndex);
        coeff = coeffvalues(data{iData}.cloudFit);
        xWidth(iData) = coeff(4);
        yWidth(iData) = coeff(6);
    end
    pixelsize = 0.5; %each pixel corresponds to 0.5 micrometer at the atoms
    yWidth = yWidth * pixelsize;
    xWidth = xWidth * pixelsize;

    title = strcat('WidthVS',lower(parameter));
    figure('Name',title);
    hold on;
    plot(xAxis,xWidth,'Or');
    plot(xAxis,yWidth,'Xb');
    ylabel('Width of Cloud');
    xlabel(strcat(data{1}.pName{paramIndex}, ' [',data{1}.pUnit{paramIndex}, ']'));
    legend('xWidth','yWidth','Location','Best');
    hold off;
end

