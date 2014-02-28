function delta =  Residual( data )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    if(~iscell(data))
        error('Data must be a cell array!');
    end
    
    for iData = 1:numel(data)
        if(~isa(data{iData},'ImageResult'))
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
        figureTitle = strcat(figureTitle,'Residual');
        figure('name', figureTitle);        
        
        [dimX, dimY] = size(data{iData}.flat);
        [x,y,~] = prepareSurfaceData(1:dimX,1:dimY,data{iData}.flat);
        fit = feval(data{iData}.cloudFit,x,y);
        delta = data{iData}.flat - reshape(fit,dimX,dimY);
        subplot(2,1,1);
        imagesc(delta);        
        colorbar;
         hold on;
        title(figureTitle,'Interpreter','None');
        hold off;
        subplot(2,1,2);
        hist(delta(:),500);
        figureTitle = strcat(figureTitle, '_Histogram');
        hold on;
        title(figureTitle,'Interpreter','None');
        hold off;
    end
    
    

end