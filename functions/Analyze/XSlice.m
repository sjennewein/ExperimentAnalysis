function XSlice( data )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
     if(~iscell(data))
        error('Data must be a cell array!');
    end
    
    for iData = 1:numel(data)
        if(~(isa(data{iData},'ImageResult') || isa(data{iData},'SmallImage')))
            error('Only data of type ImageResult can be processed');
        end            
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
        y0 = coeff(5);
        y = round(y0);
        
        
        figure('name', figureTitle);
        hold on;
        [dimY, dimX] = size(data{iData}.flat);
        plot(feval(data{iData}.cloudFit,1:dimX,y),'b');
        plot(data{iData}.flat(y,1:dimX),'x-r');
        hold off;       
    end

end