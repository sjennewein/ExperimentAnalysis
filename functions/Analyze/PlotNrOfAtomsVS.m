function PlotNrOfAtomsVS( parameter, data )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    if(~iscell(data))
        error('Data must be a cell array!');
    end
    
    for iData = 1:numel(data)
        if(~isa(data{iData},'ImageResult'))
            error('Only data of type ImageResult can be processed');
        end            
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

