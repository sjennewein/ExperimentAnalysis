function YSlice( data )
%YSlice(data) Plots a slice of the 2d picture along the y-axis going
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
        coeff = coeffvalues(data{iData}.cloudFit);
        x0 = coeff(3);
        x = round(x0);
        
        
        figure('name', figureTitle);
        hold on;
        [dimY, dimX] = size(data{iData}.flat);
        plot(feval(data{iData}.cloudFit,x,1:dimY),'b');
        plot(data{iData}.flat(1:dimY,x),'x-r');
        hold off;       
    end

end