function [ ] = ShowROI( picture, ROI )
%SHOWROI Shows the ccd picture and draws ROI
%   Shows the renormalized picture and draws the ROI
          
    imagesc(flipud( picture ));
    hold on;
    
     plot(ROI(1,1),ROI(1,2):ROI(2,2),'linewidth',1.5,'Color','black'); %plot lower x boundary
     plot(ROI(2,1),ROI(1,2):ROI(2,2),'linewidth',1.5,'Color','black'); %plot upper x boundary
    
     plot(ROI(1,1):ROI(2,1),ROI(1,2),'linewidth',1.5,'Color','black');
     plot(ROI(1,1):ROI(2,1),ROI(2,2),'linewidth',1.5,'Color','black');
    
    set(gca,'ydir','normal');
    hold off;
    

end

