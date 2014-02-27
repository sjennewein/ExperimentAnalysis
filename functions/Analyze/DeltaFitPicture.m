function  DeltaFitPicture( data )
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
        figure('name', figureTitle);
        
        [dimX, dimY] = size(data{iData}.flat);
        [x,y,~] = prepareSurfaceData(1:dimX,1:dimY,data{iData}.flat);
        fit = feval(data{iData}.cloudFit,x,y);
        delta = data{iData}.flat - reshape(fit,dimX,dimY);
        imagesc(delta);        
        colorbar;
        hold off;
    end
    
    

end