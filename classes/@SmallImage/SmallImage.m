classdef SmallImage < handle
%ImageResult Analyzes pictures and keeps the results and parameters 
%   ImageResult(picture, roi, calibration, saturation, exposure, sequences, parameterName, parameterValue,parameterUnit)
%   picture ((n x m) double matrix)
%   roi (2x2 matrix roi values)
%   calibration (Adu per microsecond)
%   saturation (Saturation of the probe beam)
%   exposure (Exposure time in microseconds)
%   sequences (How many sequences the picture was illuminated)
%   parameterName (Cell array of parameter names)
%   parameterValue (Array of values. Corresponding order of parameterName)
%   parameterUnit (Cell array with units of parameterValue)
    properties (SetAccess = private)       
        original;   %original ccd picture (rescaled)
        rescaled;
        flat;       %picture with subtracted background
        background; %background picture from fit
        cloudFit;   %cloud fit object
        cloudGOF;   %cloud goodness of fit        
        backgroundFit; %background fit object
        backgroundGOF; %background goodness of fit
        ROI;    %region of interest [x1,y1; x2,y2]   
        calibration; %counts(adu) per microsecond
        exposure;    %exposure time in microseconds
        sequences;
        pName;
        pValue;
        pUnit;
    end
    methods
        function this = SmallImage(picture, roi, calibration, saturation, exposure, sequences, parameterName, parameterValue, parameterUnit)
            this.pName = parameterName;
            this.pValue = parameterValue;
            this.pUnit = parameterUnit;
            this.ROI = roi;            
            this.sequences = sequences;
            this.original = picture;
            this.exposure = exposure; %exposure time in microsecond
            this.rescaled = picture ./ (this.exposure * calibration * (saturation/(1+saturation)) * sequences);
            this.calibration = calibration; % fluoresence of a single atom            
            this.process;
        end
        
        function atoms = AtomsFromPicture(this)
            x1 = this.ROI(1,1);
            y1 = this.ROI(1,2);
            x2 = this.ROI(2,1);
            y2 = this.ROI(2,2);           
            atoms = sum(sum(this.flat(x1:x2,y1:y2)));
        end
        
        function atoms = AtomsFromFit(this)
            x1 = this.ROI(1,1);
            y1 = this.ROI(1,2);
            x2 = this.ROI(2,1);
            y2 = this.ROI(2,2);
            atoms = quad2d(this.cloudFit,x1,x2,y1,y2);
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
            [dimX, dimY] = size(this.flat);
            
            % region of interest is only used for guessing the initial
            % start parameter
            
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
    
            %we fit the gaussian to the whole picture otherwise there is an
            %error in the wings of the gaussian function
%             [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, this.flat);
            [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, cloud);
            %define Bivariate Normal Distribution fit function
            ft = fittype([im'], ...
                          'independent',{'x', 'y'}, 'dependent', 'z');

            %fit parameter          
            opts = fitoptions( ft );
            opts.Algorithm = 'Levenberg-Marquardt';
            opts.Display = 'Off';

            opts.Lower = [-Inf -0.9 -Inf -Inf -Inf -Inf -Inf];
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
            opts.Upper = [0.7 0.9 Inf Inf Inf Inf Inf];
    
            %perform the fit
            [this.cloudFit, this.cloudGOF] = fit( [x, y], z, ft, opts );
        end
        
        function this = flattenImage(this)
            this.flat = this.rescaled - this.background;
        end
        
        function this = fitBackground(this)
            [dimX, dimY] = size(this.rescaled);
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
            maskedPicture = this.rescaled .* backgroundROI;
    
            %prepare data for fitting and fit
            [x, y, z] = prepareSurfaceData(1:dimX, 1:dimY, maskedPicture);
            [this.backgroundFit, this.backgroundGOF] = fit([x,y],z,'poly22');
    
            %generate background correction matrix
            [x, y, ~] = prepareSurfaceData(1:dimX, 1:dimY, this.rescaled);
            this.background = reshape(feval(this.backgroundFit,x,y),dimX,dimY);
        end
    end 
end