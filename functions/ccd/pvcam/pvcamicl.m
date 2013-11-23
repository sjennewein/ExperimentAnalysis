% PVCAMICL - acquire image sequence using ICL script
%
%    [DATA, ROI] = PVCAMICL(HCAM, SCRIPT) acquires an image sequence from
%    ICL code in the character string SCRIPT.  If successful, DATA will be a
%    vector of unsigned integers containing the image data acquired by the
%    ICL script, and ROI will be a structure array that contains the fields
%    X, Y and OFFSET to provide the size and offset of each PIXEL_DISPLAY( )
%    command issued within the ICL script.  If no images are acquired, such
%    as a script to open or close the shutter, DATA = [] and ROI = "no
%    image".  If an error occurs, DATA = [] and ROI = "error".
%
%    Use the syntax [DATA, ROI] = PVCAMICL(HCAM, [SCRIPT{:}]) if SCRIPT is a
%    cell array of ICL code lines.
%
%    [DATA, ROI] = PVCAMICL(HCAM, SCRIPT, 'load') initializes and loads the
%    script only.  Although no acquisition is performed, DATA will be
%    returned as zeros(IMAGE_SIZE), which is required for image storage for
%    subsequent 'run' commands.
%
%    DATA = PVCAMICL(HCAM, DATA, 'run') runs the loaded script and
%    stores any acquired images to DATA.  Note that DATA is initially
%    allocated by the 'load' option and must be provided as an input for
%    any image acquisition.
%
%    STATUS = PVCAMICL(HCAM, [], 'uninit') uninitializes the loaded ICL
%    script so another script can be loaded.  STATUS = 1 if there are no
%    errors.
%
%    The 'load', 'run' and 'uninit' options are provided for repetitive
%    script execution.  An example of this repetitive execution would be: 
%
%    [DATA, ROI] = PVCAMICL(HCAM, SCRIPT, 'load');
%    for i = 1 : NIMAGE
%        DATA = PVCAMICL(HCAM, DATA, 'run');
%    end
%    STATUS = PVCAMICL(HCAM, [], 'uninit');

% 1/8/04 SCM
% mex DLL code
