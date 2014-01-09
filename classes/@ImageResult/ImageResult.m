classdef ImageResult < handle
    properties (SetAccess = private)
        Parameters = containers.Map();
        original;   %original ccd picture (rescaled)
        flat;       %picture with subtracted background
        background; %background picture from fit
        cloudFit;   %cloud fit object
        cloudGOF;   %cloud goodness of fit        
        backgroundFit; %background fit object
        backgroundGOF; %background goodness of fit
        ROI;    %region of interest [x1,y1; x2,y2]   
        calibration; %counts(adu) per microsecond
        exposure;    %exposure time in microseconds
        name;
    end
    methods
        function this = ImageResult(picture, roi, calibration, exposure)
            this.ROI = roi;
            this.original = picture ./ (exposure * calibration); %TODO change 90 to automatic
            this.calibration = calibration; % fluoresence of a single atom
            this.exposure = exposure;
            this.process;
        end
        
        function atoms = AtomsFromPicture(this)
            x1 = this.ROI(1,1);
            y1 = this.ROI(1,2);
            x2 = this.ROI(2,1);
            y2 = this.ROI(2,2);           
            atoms = sum(sum(this.flat(x1:x2,y1:y2)));
        end
    end
    
    methods (Access = private)
        function this = process(this)
            this.fitBackground();            
            this.flattenImage();
            this.fitCloud();
        end       
        
        function this = fitCloud(this)
            % create mask from ROI
            [dimX, dimY] = size(this.original);
            x1 = this.ROI(1,1);
            x2 = this.ROI(2,1);
            y1 = this.ROI(1,2);
            y2 = this.ROI(2,2);           
            
            mask = NaN(dimX,dimY);
            roiX = (x2-x1)+1;
            roiY = (y2-y1)+1;
            cloudMask = ones(roiX,roiY);
            mask(x1:x2,y1:y2) = cloudMask;
    
            cloud = this.flat .* mask;
    
            [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, cloud);
    
            %define Bivariate Normal Distribution fit function
            ft = fittype(['z0' ...
                         ,'+ a * exp ( -1/(2 * (1 - cor^2))' ...
                         ,'* (((x-x0) / xWidth)^2' ...
                         ,'+ ((y-y0) / yWidth)^2' ...
                         ,'- (2 * cor * (x-x0) * (y-y0)) / (xWidth * yWidth)))'], ...
                          'independent',{'x', 'y'}, 'dependent', 'z');
            opts = fitoptions( ft );
            opts.Algorithm = 'Levenberg-Marquardt';
            opts.Display = 'Off';
            opts.Lower = [-Inf -Inf -Inf -Inf -Inf -Inf];
            opts.MaxFunEvals = 600;
            opts.MaxIter = 1000;
    
    
            %guess start parameter
            [value, row] = max(cloud); % find vector with the maximum value
            [value, column] = max(value); % find maximum in vector
    
            a_start = value;
            cor_start = 0;
            x0_start = row(column);
            xWidth_start = 10;
            y0_start = column;
            yWidth_start = 10;
            z0_start = 0;
    
            opts.StartPoint = [ a_start cor_start x0_start xWidth_start ...
                                y0_start yWidth_start z0_start];
            opts.Upper = [Inf Inf Inf Inf Inf Inf];
    
            %perform the fit
            [this.cloudFit, this.cloudGOF] = fit( [x, y], z, ft, opts );
        end
        
        function this = flattenImage(this)
            this.flat = this.original - this.background;
        end
        
        function this = fitBackground(this)
            [dimX, dimY] = size(this.original);
            x1 = this.ROI(1,1);
            x2 = this.ROI(2,1);
            y1 = this.ROI(1,2);
            y2 = this.ROI(2,2);
            
            %generate mask to select the background
            backgroundROI = ones(dimX,dimY);
    
            %exclude cloud
            dimROIX = (x2-x1)+1;
            dimROIY = (y2-y1)+1;
            cloudMask = NaN(dimROIX,dimROIY);
            backgroundROI(x1:x2,y1:y2) = cloudMask;
    
            %apply roi mask
            maskedPicture = this.original .* backgroundROI;
    
            %prepare data for fitting and fit
            [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, maskedPicture);
            [this.backgroundFit, this.backgroundGOF] = fit([x,y],z,'poly22');
    
            %generate background correction matrix
            [x, y, ~] = prepareSurfaceData(1:dimX, 1:dimY, this.original);
            this.background = reshape(feval(this.backgroundFit,x,y),dimX,dimY);
        end
    end 
end