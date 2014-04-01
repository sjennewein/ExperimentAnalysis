function ShowROI( data )
%SHOWROI(data) Shows the flattened picture and draws ROI
%   Shows the flattened picture and draws the ROI
      
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
        figure('name', figureTitle);
        
        imagesc(data{iData}.flat );
        axis xy;
        colorbar;
        hold on;
        %Attention we use the x and y values as we read it from the picture
        %not in the weird way we have to do it in the analysis function.
        %for more information have a look in the analysis script
        x1 = data{iData}.ROI(1,1);
        x2 = data{iData}.ROI(2,1);
        y1 = data{iData}.ROI(1,2);
        y2 = data{iData}.ROI(2,2);
    
    
        plot(x1,y1:y2,'+-','linewidth',1.5,'Color','black'); %plot lower x boundary
        plot(x2,y1:y2,'+-','linewidth',1.5,'Color','black'); %plot upper x boundary
    
        plot(x1:x2,y1,'+-','linewidth',1.5,'Color','black');
        plot(x1:x2,y2,'+-','linewidth',1.5,'Color','black');
    
        set(gca,'ydir','normal');
        hold off;
    end

end

