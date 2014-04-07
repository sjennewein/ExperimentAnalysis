function XSlice( data )
%XSlice(data) Plots a slice of the 2d picture along the x-axis going
%through the maximum of the fit

if(~iscell(data))
    error('Data must be a cell array!');
end

for iData = 1:numel(data)
    figureTitle = '';
    for iParameter = 1:numel(data{iData}.pName)
        figureTitle = strcat(figureTitle, ...
            data{iData}.pName{iParameter}, '_', ...
            num2str(data{iData}.pValue(iParameter)), ...
            data{iData}.pUnit{iParameter}, '_');
    end
    y0Index = getIndexOfParameter('y0',coeffnames(data{iData}.cloudFit));
    coeff = coeffvalues(data{iData}.cloudFit);
    y0 = coeff(y0Index);
    y = round(y0)
    
    
    figure('name', figureTitle);
    hold on;
    [dimY, dimX] = size(data{iData}.flat);
    plot(feval(data{iData}.cloudFit,1:dimX,y),'b');
    plot(data{iData}.flat(y,1:dimX),'x-r');
    hold off;
end

end