function [ ] = ShowROI( ccdImage, roiX, roiY )
%SHOWROI Shows the ccd picture and draws ROI
%   Shows the renormalized picture and draws the ROI
    
   
    rescaleFactor = max(max(ccdImage))/64;
    imagesc(flipud( ccdImage/ rescaleFactor ));
    hold on;
    
    plot(roiX(1),roiY(1):roiY(2),'LineWidth',2,'Color','black'); %plot lower x boundary
    plot(roiX(2),roiY(1):roiY(2),'LineWidth',2,'Color','black'); %plot upper x boundary
    
    plot(roiX(1):roiX(2),roiY(1),'LineWidth',2,'Color','black');
    plot(roiX(1):roiX(2),roiY(2),'LineWidth',2,'Color','black');
  
    hold off;
    

end

