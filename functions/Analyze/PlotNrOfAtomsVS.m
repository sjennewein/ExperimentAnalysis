function [xAxis,atomsPicture,atomsFit] = PlotNrOfAtomsVS( parameter, data )
%[xAxis,atomsFromPicture,atomsFromFit] = PlotNrOfAtomsVS(parameter,data) 
%   This function takes two parameter one is the parameter name for the
%   x-axis.
%   parameter is the the parameter name used for the X-axis
%   data is an analyzed picture implementing the interface of ImageResult  
    if(~iscell(data))
        error('Data must be a cell array!');
    end  
    
    if(~ischar(parameter))
        error('Parameter name must be a character.');
    end
    
    xAxis  = zeros(1,numel(data));
    atomsPicture = zeros(1,numel(data));
    atomsFit = zeros(1,numel(data));
    paramIndex = 0;
    for iData = 1:numel(data)        
        paramIndex = getIndexOfParameter(parameter, data{iData}.pName);
        xAxis(iData) = data{iData}.pValue(paramIndex);
        atomsPicture(iData) = data{iData}.AtomsFromPicture;
        atomsFit(iData) = data{iData}.AtomsFromFit;
    end
    
    title = strcat('AtomsVS',lower(parameter));
    figure('Name',title);
    hold on;
    plot(xAxis,atomsPicture,'Or');
    plot(xAxis,atomsFit,'Xb');
    ylabel('Nr of Atoms');
    xlabel(strcat(data{1}.pName{paramIndex}, ' [',data{1}.pUnit{paramIndex}, ']'));
    legend('Atoms from Picture','Atoms from Fit','Location','Best');
    hold off;
end

