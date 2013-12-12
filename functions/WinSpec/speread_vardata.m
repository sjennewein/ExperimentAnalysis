function varargout = speread_vardata(varargin)
%SPEREAD_VARDATA returns predefined header specs for SPEREAD_HEADER
%   Package name:     SPEREAD
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   [VARDATA,STRUCTDECL] = SPEREAD_VARDATA(KEYWORD) returns predefined
%   variables needed for SPEREAD_HEADER manual selection of fields.
%   User can change the source code for this function to create additional
%   sets of [VARDATA,STRUCTDECL] pairs.
%
%   By default only following sets are implemented:
%
%   KEYWORD         DESCRIPTION
%
%   'spe_min_2.5'   WinView/WinSpec File Format version 2.5. This is a
%                   minimal set of fields needed for SPEREAD functions to
%                   work.
%
%   'spe_full_2.5'  WinView/WinSpec File Format version 2.5. This is a
%                   full set of fields for this format.
%
%   'tvid_320_240'  TVID format (version that was current in 2010-02-27), 
%                   with 320x240 frame size and additional predefined 
%                   constants.
%
%   'tvid_160_120'  TVID format (version that was current in 2010-02-27), 
%                   with 160x120 frame size and additional predefined 
%                   constants.
%
%   Example:
%
%       % read only minimum required set of fields from header version 2.5
%       header = speread_header(filepath,speread_vardata('spe_min_2.5'));
%
%       % read full set of fields from header version 2.5
%       [vardata,structdecl] = speread_vardata('spe_full_2.5');
%       header = speread_header(filepath,vardata,structdecl);
%
%   HOW TO CREATE USER DEFINED FORMAT SPECIFICATIONS
%
%   SPEREAD and SPEFILE packages only support headers with constant offsets
%   and number of fields, like WinView/WinSpec files and comparable formats
%   like TVID.
%
%   To add support for such formats, user must first decide on the unique 
%   keyword for the format he wants to add support for, and create 
%   corresponding FORMAT cell array (defined in the primary function) 
%   row
%
%       FORMAT = {...
%           'keyword','*.key','Format description (*.key)',@gen_My_Format;
%       };
%
%   First column is used for user defined keyword. Second and third columns
%   are used for strings passed to uigetfile() dialog: second column is 
%   file extension for the format being defined, third is the description 
%   of the file format. Forth column is used for function handle to the 
%   subfunction that returns VARDATA and STRUCTDECL variables for use in 
%   SPEREAD_HEADER function.
%
%
%       function [vardata,structDecl] = gen_My_Format()
%           ...
%       end
%
%   First row of the FORMAT array is always used as default specification
%   used for SPEREAD_HEADER calls when user does not provide VARDATA
%   as an argument to this function.
%
%   1. BASIC FORMAT SPECIFICATION IN VARDATA
%   
%   VARDATA must be a cell array. Each row of this array defines an element 
%   of the header of the format. Each row must have at least four columns:
%
%       1 - NAME   - name of the field in the output HEADER structure.
%       2 - TYPE   - how data should be interpreted. Specify only source 
%                    format, for example 'uint16'. All numeric data will 
%                    be returned as double, and all 'char' data will be 
%                    returned as char arrays (see help for fread function 
%                    for precision definitions). See more instructions 
%                    below.
%       3 - OFFSET - offset of the data from the begining of the file.
%       4 - NUMEL  - number of elements to read.
%
%       User can also use fifth column of this array to store descriptions
%       of the field, which might be useful for long headers:       
%
%       5 - DESC   - user defined character string describing this
%                    field
%
%       This column is not required for SPEREAD and SPEFILE
%       functions to work correctly.
%
%   Example:
%
%       % simple VARDATA definition
%       vardata = {
%           'DATA_OFFSET','uint16',-1,4100,'Header size/beginning of data';
%           'xdim','uint16',42,1 ,'actual # of pixels on x axis';
%           'datatype','short',108,1 ,'experiment datatype';
%           'ydim','uint16',656,1 ,'y dimension of raw data.';
%           'NumFrames','int32',1446,1 ,'number of frames in file.';
%       };
%   
%   2. CONSTANTS
%
%   User can also specify predefined constants by including rows in 
%   VARDATA with the following interpretation of VARDATA columns:
%
%       1 - NAME   - name of field in the output HEADER structure where
%                    this constant will be stored
%       2 - TYPE   - will be ignored
%       3 - OFFSET - must always be -1 for user constants
%       4 - VALUE  - value of this constant, can be any MatLab data type
%                    that can be stored in cell arrays' cell
%
%   Example:
%
%       'DATA_OFFSET','uint16',-1,4100, 'Header size/beginning of data';
%   
%   3. STRUCTURES
%
%   It is also possible to return structures as elements of the header. 
%   To do this user must define STRUCTDECL structure with fields containing 
%   cell arrays with the same layout as VARDATA cell array, but with 
%   relative OFFSET from the start of each instance of such structure in 
%   the header. Structures in the header are only supported at top level
%   of the header - structures within structures are not supported, so
%   TYPE must always be a basic type in STRUCTDECL.
%
%   Then, placement of the structure inside the header is defined by the 
%   rows in VARDATA array with the following layout:
%
%       1 - NAME   - name of field in the output HEADER structure where
%                    this structre or array of structures will be stored.
%       2 - TYPE   - must always be a cell array with the following layout:
%                    {'struct','STRUCTDECL_field'}, where STRUCTDECL_field 
%                    is the name of the field in the STRUCTDECL structure
%                    where this structure type is defined.
%       3 - OFFSET - offset from the beginning of the file of this
%                    structure instance. Can be an array of offsets for
%                    multiple instances. They will be stored in an array.
%       4 - NUMEL  - must be empty
%
%   Example:
%
%       structDecl.ExampleDecl = {
%           'x', 'float32', 0, 1, 'x coordinate of particle';
%           'y', 'float32', 4, 1, 'y coordinate of particle';
%       };
%
%       vardata = {
%           ...
%           'Example',{'struct','ExampleDecl'},[100 108 116],[],'Example';
%           ...
%       };
% 
%   In the above example, there are three instances of ExampleDecl 
%   structure defined in the header - at offset 100 from the beginning of 
%   the file, and at offset 108. So, field 'x' of the first Example 
%   structure will be at offset 100, 'y' will be at 104, 'x' of the second 
%   structure will be at 108, and so on.
%
%   4. CELL ARRAYS
%
%   It is also possible to return cell arrays as elements of the header.
%   Cell arrays, like structures, are only supported at the top level of 
%   the header. For cell arrays, corresponding row in VARDATA array must 
%   have the following layout:
%
%       1 - NAME   - name of field in the output HEADER structure where
%                    this cell array will be stored.
%       2 - TYPE   - cell array of character strings with data types. Only
%                    basic types are allowed here.
%       3 - OFFSET - Offset from the beginning of the file for each element
%                    of this cell array.
%       4 - NUMEL  - number of elements of specified type in the 
%                    corresponging cell of this array.
%
%   Example:
%   
%       'Comments', {'char';'char';}, [200;280;], [80;80;], 'Comments';
%
%   5. REQUIRED FIELDS AND RESERVED FIELD NAMES
%
%   WARNING: For SPEREAD and SPEFILE data functions use it is important 
%   that VARDATA contains elements with these names at the top level of the 
%   header as they are necessary for correct operation of these functions:
%
%       'NumFrames' - this field is used to specify the number of frames 
%                     in a file
%       'xdim'      - this field specifies the number of pixels in a frame
%                     along X axis (columns)
%       'ydim'      - this field specifies the number of pixels along
%                     Y axis (rows)
%       'DATAORDER' - 'row' or 'column'. Specifies the order of data in a
%                     file. 'row' is used to specify that first row is
%                     written first, starting from the first element of the 
%                     row, then goes the second row, and so on. 'column'
%                     means that first column is written first, starting
%                     with its first element, then the second column, and
%                     so on
%
%       For SPE files:       
%       'datatype'  - this field specifies the source data type for frames
%                     for SPE files
%
%       For other files user must specify predefined constants in VARDATA
%       to override 'datatype':
%
%       'DATATYPE_STR'  - MatLab datatype string used in fread (ex. 
%                         "float32")
%       'DATATYPE_SIZE' - Size of single element of this datatype
%
%   Data offset must always be specified in VARDATA as 'DATA_OFFSET'
%   header field or as a predefined constant. For SPE format version 2.5
%   'DATA_OFFSET' will be specified as constant in VARDATA row:
%
%       'DATA_OFFSET','',-1,4100;
%
%   If 'DATA_OFFSET' is not constant, then user must provide constant
%   field 'HEADER_SIZE' in order for SPEFILE functions to work correctly.
%   'HEADER_SIZE' must be an integer number (with TYPE 'uint16', for 
%   example) that specifies maximum header size of this format. In other
%   words, offset at which it is safe to start writting data to output file
%   of this format in any possible case.
%
%   For more information on SPEFILE requirements, refer to HELP SPEFILE.
%
%   There are also the following reserved field names:
%
%       'FILEPATH' - used for absolute file path to the file from which
%                    header was read
%       'HEADER_READ_TIME' - used for time of the reading of the header
%
%   See also SPEREAD_HEADER, SPEREAD_FRAME, SPEREAD_POINTVALS, SPEFILE.

%% LICENSE
% Copyright (c) 2008-2013 Alexander Nikitin
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
% 3. The name of the author may not be used to endorse or promote products
%    derived from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
% IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
% NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
% THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%% Version history
%   2013-08-01 - added field descriptions strings to structures for ease of
%                use with long headers, added FORMATS array for ease of 
%                adding user defined formats and better speread_header
%                support, added support for column order of data
%   2011-11-05 - added tvid specification
%   2011-04-15 - now properly reports invalid TYPE field
%   2010-08-20 - first build

%% CODE
% user editable section
FORMATS = {'spe_full_2.5','*.spe','WinView/WinSpec Full Spec (*.spe)',@gen_Spe_Full_2_5;
    'spe_min_2.5','*.spe','WinView/WinSpec Min Spec (*.spe)',@gen_Spe_Min_2_5;
    'tvid_320_240','*.tvid','TVID 320x240px (*.tvid)',@gen_Tvid_320_240;
    'tvid_160_120','*.tvid','TVID 160x120px (*.tvid)',@gen_Tvid_160_120;
    };
% end of user editable section

if nargin == 0
    temp = unique(FORMATS(:,1));
    if any(size(temp) ~= size(FORMATS(:,1)))
        error('SPEREAD_VARDATA:DuplicateKeywords','Duplicate keywords found in FORMAT');
    end;
    varargout{1} = FORMATS(:,1:3);
    return;
end;

if ~ischar(varargin{1})
    error('SPEREAD_VARDATA:KeywordNotChar', ...
        'Invalid KEYWORD specified. See help speread_vardata.');
end;

[TF,LOC] = ismember(varargin{1},FORMATS(:,1));

if LOC ~= 0
    fhandle = FORMATS{LOC,4};
    [vardata,structDecl] = fhandle();
else
    error('SPEREAD_VARDATA:KeywordNotFound', ...
        'Invalid KEYWORD specified. See help speread_vardata.');
end;
varargout{1} = vardata;
varargout{2} = structDecl;
end

%% SPEC FUNCTIONS
% user spec functions can be defined here

function [vardata,structDecl] = gen_Tvid_320_240()
    structDecl = struct([]);
    vardata = {
        'HEADER_SIZE','uint16',-1,14,...
            'for SPEFILE functions to interpret as DATA_OFFSET';
        'DATAORDER','char',-1,'row', ...
            'data is always in row order';
        % DATA_OFFSET is equal to HeaderSize field in TVID specification
        'DATA_OFFSET','uint16',0,1, ...
            'Number of bytes in the header';
        'NumFrames','uint16',2,1 , ...
            'Number of frames in the file';
        'gain','float32',4,1 , ...
            '"contrast"';
        'shift','uint16',8,1 , ...
            '"brightness"';
        'FrameTime','float32',10,1 , ...
            'Time between frames, msec';
        % user defined fields, not present in TVID specification
        'xdim','uint16',-1,320 , ...
            'number of columns in frame';
        'ydim','uint16',-1,240 , ...
            'number of rows in frame';
        'DATATYPE_STR','char',-1,'float32', ...
            'datatype is always float32';
        'DATATYPE_SIZE','uint16',-1,4, ...
            'datatype size is always 4 bytes';
        };
end

function [vardata,structDecl] = gen_Tvid_160_120()
    structDecl = struct([]);
    vardata = {
        'HEADER_SIZE','uint16',-1,14,...
            'For SPEFILE functions to be interpreted as DATA_OFFSET';
        'DATAORDER','char',-1,'row', ...
            'data is always in row order';
        % DATA_OFFSET is equal to HeaderSize field in TVID specification
        'DATA_OFFSET','uint16',0,1 , ...
            'Number of bytes in the header';
        'NumFrames','uint16',2,1 , ...
            'Number of frames in the file';
        'gain','float32',4,1 , ...
            '"contrast"';
        'shift','uint16',8,1 , ...
            '"brightness"';
        'FrameTime','float32',10,1 , ...
            'Time between frames, msec';
        % user defined fields, not present in TVID specification
        'xdim','uint16',-1,160 , ...
            'number of columns in frame';
        'ydim','uint16',-1,120 , ...
            'number of rows in frame';
        'DATATYPE_STR','char',-1,'float32', ...
            'datatype is always float32';
        'DATATYPE_SIZE','uint16',-1,4, ...
            'datatype size is always 4 bytes';
        };
end

function [vardata,structDecl] = gen_Spe_Min_2_5()
structDecl = struct([]);
vardata = {
    'DATAORDER','char',-1,'row', ...
            'data is always in row order';
    'DATA_OFFSET','uint16',-1,4100, ...
        'Header size/beginning of data';
    'xdim','uint16',42,1 , ... 
        'actual # of pixels on x axis';
    'datatype','short',108,1 , ...
        'experiment datatype: 0 = float (4 bytes), 1 = long (4 bytes), 2 = short (2 bytes), 3 = unsigned short (2 bytes)';
    'ydim','uint16',656,1 , ...
        'y dimension of raw data.';
    'NumFrames','int32',1446,1 , ...
        'number of frames in file.';
    };
end

function [vardata,structDecl] = gen_Spe_Full_2_5()
% Max char str length for file name
HDRNAMEMAX = 120;
% User comment string max length (5 comments)
COMMENTMAX = 80;
% Label string max length
LABELMAX = 16;
% File version string max length
FILEVERMAX = 16;
% String length of file creation date string as ddmmmyyyy\0
DATEMAX = 10;
% Max time store as hhmmss\0
TIMEMAX = 7;

structDecl = struct();

structDecl.ROIinfo = {
    'startx','uint16',0,1 , ...
        'left x start value.';
    'endx','uint16',2,1 , ...
        'right x value.';
    'groupx','uint16',4,1 , ...
        'amount x is binned/grouped in hw.';
    'starty','uint16',6,1 , ...
        'top y start value.';
    'endy','uint16',8,1 , ...
        'bottom y value.';
    'groupy','uint16',10,1 , ...
        'amount y is binned/grouped in hw.';
    };

structDecl.XYCalib = {
    'offset','double',0,1 , ...
        'offset for absolute data scaling';
    'factor','double',8,1 , ...
        'factor for absolute data scaling';
    'current_uint','char',16,1 , ...
        'selected scaling unit';
    'reserved1','char',17,1 , ...
        'reserved';
    'string','char',18,40 , ...
        'special string for scaling';
    'reserved2','char',58,40 , ...
        'reserved';
    'calib_valid','char',98,1 , ...
        'flag if calibration is valid';
    'input_unit','char',99,1 , ...
        'current input units for "calib_value"';
    'polynom_unit','char',100,1 , ...
        'linear UNIT and used in the "polynom_coeff"';
    'polynom_order','char',101,1 , ...
        'ORDER of calibration POLYNOM';
    'calib_count','char',102,1 , ...
        'valid calibration data pairs';
    'pixel_position','double',103,10 , ...
        'pixel pos. of calibration data';
    'calib_value','double',183,10 , ...
        'calibration VALUE at above pos';
    'polynom_coeff','double',263,6 , ...
        'polynom COEFFICIENTS';
    'laser_position','double',311,1 , ...
        'laser wavenumber for relative WN';
    'reserved3','char',319,1 , ...
        'reserved';
    'new_calib_flag','uint8',320,1 , ...
        'If set to 200, valid label below';
    'calib_label','char',321,81 , ...
        'Calibration label (NULL term''d)';
    'expansion','char',402,87 , ...
        'Calibration Expansion area';
    };

structDecl.EndCalib = {
    'Istring','char',0,40 , ...
        'special intensity scaling string';
    'Spare_6','char',40,25 , ...
        '';
    'SpecType','uint8',65,1 , ...
        'spectrometer type (acton, spex, etc.)';
    'SpecModel','uint8',66,1 , ...
        'spectrometer model (type dependent)';
    'PulseBurstUsed','uint8',67,1 , ...
        'pulser burst mode on/off';
    'PulseBurstCount','uint32',68,1 , ...
        'pulser triggers per burst';
    'PulseBurstPeriod','double',72,1 , ...
        'pulser burst period (in usec)';
    'PulseBracketUsed','uint8',80,1 , ...
        'pulser bracket pulsing on/off';
    'PulseBracketType','uint8',81,1 , ...
        'pulser bracket pulsing type';
    'PulseTimeConstFast','double',82,1 , ...
        'pulser slow exponential time constant (in usec)';
    'PulseAmplitudeConstFast','double',90,1 , ...
        'pulser fast exponential amplitude constant';
    'PulseTimeConstSlow','double',98,1 , ...
        'pulser slow exponential time constant (in usec)';
    'PulseAmplitudeConstSlow','double',106,1 , ...
        'pulser slow exponential amplitude constant';
    'AnalogGain','short',114,1 , ...
        'analog gain';
    'AnalogUsed','short',116,1 , ...
        'avalanche gain was used';
    'AVGain','short',118,1 , ...
        'avalanche gain value';
    'lastvalue','short',120,1 , ...
        'Always the LAST value in the header';
    };

vardata = {
    'DATAORDER','char',-1,'row', ...
            'data is always in row order';
    'DATA_OFFSET','uint16',-1,4100 , ...
        'Header size/beginning of data';
    'ControllerVersion','short',0,1 , ...
        'Hardware Version';
    'LogicOutput','short',2,1 , ...
        'Definition of Output BNC';
    'AmpHiCapLowNoise','uint16',4,1 , ...
        'Amp Switching Mode';
    'xDimDet','uint16',6,1 , ...
        'Detector x dimension of chip.';
    'mode','short',8,1 , ...
        'timing mode';
    'exp_sec','float32',10,1 , ...
        'alternative exposure, in sec.';
    'VChipXDim','short',14,1 , ...
        'Virtual Chip X dim';
    'VChipYDim','short',16,1 , ...
        'Virtual Chip Y dim';
    'yDimDet','uint16',18,1 , ...
        'y dimension of CCD or detector.';
    'date','char',20,DATEMAX, ...
        'date';
    'VirtualChipFlag','short',30,1 , ...
        'On/Off';
    'Spare_1','char',32,2 , ...
        '';
    'noscan','short',34,1 , ...
        'Old number of scans - should always be -1';
    'DetTemperature','float32',36,1 , ...
        'Detector Temperature Set';
    'DetType','short',40,1 , ...
        'CCD/DiodeArray type';
    % 'xdim' is a very important mandatory field as it defines how frames will be
    % read when using 'speread_data' function
    'xdim','uint16',42,1 , ... 
        'actual # of pixels on x axis';
    'stdiode','short',44,1 , ...
        'trigger diode';
    'DelayTime','float32',46,1 , ...
        'Used with Async Mode';
    'ShutterControl','uint16',50,1 , ...
        'Normal, Disabled Open, Disabled Closed';
    'AbsorbLive','short',52,1 , ...
        'On/Off';
    'AbsorbMode','uint16',54,1 , ...
        'Reference Strip or File';
    'CanDoVirtualChipFlag','short',56,1 , ...
        'T/F Cont/Chip able to do Virtual Chip';
    'ThresholdMinLive','short',58,1 , ...
        'On/Off';
    'ThresholdMinVal','float32',60,1 , ...
        'Threshold Minimum Value';
    'ThresholdMaxLive','short',64,1 , ...
        'On/Off';
    'ThresholdMaxVal','float32',66,1 , ...
        'Threshold Maximum Value';
    'SpecAutoSpectroMode','short',70,1 , ...
        'T/F Spectrograph Used';
    'SpecCenterWlNm','float32',72,1 , ...
        'Center Wavelength in Nm';
    'SpecGlueFlag','short',76,1 , ...
        'T/F File is Glued';
    'SpecGlueStartWlNm','float32',78,1 , ...
        'Starting Wavelength in Nm';
    'SpecGlueEndWlNm','float32',82,1 , ...
        'Starting Wavelength in Nm';
    'SpecGlueMinOvrlpNm','float32',86,1, ...
        'Minimum Overlap in Nm';
    'SpecGlueFinalResNm','float32',90,1 , ...
        'Final Resolution in Nm';
    'PulserType','short',94,1 , ...
        '0=None, PG200=1, PTG=2, DG535=3';
    'CustomChipFlag','short',96,1 , ...
        'T/F Custom Chip Used';
    'XPrePixels','short',98,1 , ...
        'Pre Pixels in X direction';
    'XPostPixels','short',100,1 , ...
        'Post Pixels in X direction';
    'YPrePixels','short',102,1 , ...
        'Pre Pixels in Y direction';
    'YPostPixels','short',104,1 , ...
        'Post Pixels in Y direction';
    'asynen','short',106,1 , ...
        'asynchron enable flag 0 = off';
    % 'datatype' is mandatory field
    'datatype','short',108,1 , ...
        'experiment datatype: 0 = float (4 bytes), 1 = long (4 bytes), 2 = short (2 bytes), 3 = unsigned short (2 bytes)';
    'PulserMode','short',110,1 , ...
        'Repetitive/Sequential';
    'PulserOnChipAccums','uint16',112,1 , ...
        'Num PTG On-Chip Accums';
    'PulserRepeatExp','uint32',114,1 , ...
        'Num Exp Repeats (Pulser SW Accum)';
    'PulseRepWidth','float32',118,1 , ...
        'Width Value for Repetitive pulse (usec)';
    'PulseRepDelay','float32',122,1 , ...
        'Width Value for Repetitive pulse (usec)';
    'PulseSeqStartWidth','float32',126,1 , ...
        'Start Width for Sequential pulse (usec)';
    'PulseSeqEndWidth','float32',130,1 , ...
        'End Width for Sequential pulse (usec)';
    'PulseSeqStartDelay','float32',134,1 , ...
        'Start Delay for Sequential pulse (usec)';
    'PulseSeqEndDelay','float32',138,1 , ...
        'End Delay for Sequential pulse (usec)';
    'PulseSeqIncMode','short',142,1 , ...
        'Increments: 1=Fixed, 2=Exponential';
    'PImaxUsed','short',144,1 , ...
        'PI-Max type controller flag';
    'PImaxMode','short',146,1 , ...
        'PI-Max mode';
    'PImaxGain','short',148,1 , ...
        'PI-Max Gain';
    'BackGrndApplied','short',150,1 , ...
        '1 if background subtraction done';
    'PImax2nsBrdUsed','short',152,1 , ...
        'T/F PI-Max 2ns Board Used';
    'minblk','uint16',154,1 , ...
        'min. # of strips per skips';
    'numminblk','uint16',156,1 , ...
        '# of min-blocks before geo skps';
    'SpecMirrorLocation','short',158,2 , ...
        'Spectro Mirror Location, 0=Not Present';
    'SpecSlitLocation','short',162,4 , ...
        'Spectro Slit Location, 0=Not Present';
    'CustomTimingFlag','short',170,1 , ...
        'T/F Custom Timing Used';
    'ExperimentTimeLocal','char',172,TIMEMAX , ...
        'Experiment Local Time as hhmmss\0';
    'ExperimentTimeUTC','char',179,TIMEMAX , ...
        'Experiment UTC Time as hhmmss\0';
    'ExposUnits','short',186,1 , ...
        'User Units for Exposure';
    'ADCoffset','uint16',188,1 , ...
        'ADC offset';
    'ADCrate','uint16',190,1 , ...
        'ADC rate';
    'ADCtype','uint16',192,1 , ...
        'ADC type';
    'ADCresolution','uint16',194,1, ...
        'ADC resolution';
    'ADCbitAdjust','uint16',196,1, ...
        'ADC bit adjust';
    'gain','uint16',198,1, ...
        'gain';
    'Comments',{'char';'char';'char';'char';'char';}, ...
    [200;280;360;440;520;],[COMMENTMAX;COMMENTMAX;COMMENTMAX;COMMENTMAX;COMMENTMAX;] , ...
        'File Comments';
    'geometric','uint16',600,1 , ...
        'geometric ops: rotate 0x01,reverse 0x02, flip 0x04';
    'xlabel','char',602,LABELMAX , ...
        'intensity display string';
    'cleans','uint16',618,1 , ...
        'cleans';
    'NumSkpPerCln','uint16',620,1 , ...
        'number of skips per clean.';
    'SpecMirrorPos','short',622,2 , ...
        'Spectrograph Mirror Positions';
    'SpecSlitPos','float32',626,4 , ...
        'Spectrograph Slit Positions';
    'AutoCleansActive','short',642,1 , ...
        'T/F';
    'UseContCleansInst','short',644,1 , ...
        'T/F';
    'AbsorbStripNum','short',646,1 , ...
        'Absorbance Strip Number';
    'SpecSlitPosUnits','short',648,1 , ...
        'Spectrograph Slit Position Units';
    'SpecGrooves','float32',650,1 , ...
        'Spectrograph Grating Grooves';
    'srccmp','short',654,1 , ...
        'number of source comp.diodes';
    % 'ydim' is mandatory field
    'ydim','uint16',656,1 , ...
        'y dimension of raw data.';
    'scramble','short',658,1 , ...
        '0=scrambled,1=unscrambled';
    'ContinuousCleansFlag','short',660,1 , ...
        'T/F Continuous Cleans Timing Option';
    'ExternalTriggerFlag','short',662,1 , ...
        'T/F External Trigger Timing Option';
    'lnoscan','int32',664,1 , ...
        'Number of scans (Early WinX)';
    'lavgexp','int32',668,1 , ...
        'Number of Accumulations';
    'ReadoutTime','float32',672,1 , ...
        'Experiment readout time';
    'TriggeredModeFlag','short',676,1 , ...
        'T/F Triggered Timing Option';
    'Spare_2','char',678,10 , ...
        '';
    'sw_version','char',688,FILEVERMAX , ...
        'Version of SW creating this file';
    'type','short',704,1 , ...
        '1 = new120 (Type II), 2 = old120 (Type I), 3 = ST130, 4 = ST121, 5 = ST138, 6 = DC131 (PentaMax), 7 = ST133 (MicroMax/SpectroMax), 8 = ST135 (GPIB), 9 = VICCD, 10 = ST116 (GPIB), 11 = OMA3 (GPIB), 12 = OMA4';
    'flatFieldApplied','short',706,1 , ...
        '1 if flat field was applied.';
    'Spare_3','char',708,16 , ...
        '';
    'kin_trig_mode','short',724,1 , ...
        'Kinetics Trigger Mode';
    'dlabel','char',726,LABELMAX , ...
        'Data label.';
    'Spare_4','char',742,436 , ...
        '';
    'PulseFileName','char',1178,HDRNAMEMAX , ...
        'Name of Pulser File with Pulse Widths/Delays (for Z-Slice)';
    'AbsorbFileName','char',1298,HDRNAMEMAX , ...
        'Name of Absorbance File (if File Mode)';
    'NumExpRepeats','uint32',1418,1 , ...
        'Number of Times experiment repeated';
    'NumExpAccums','uint32',1422,1 , ...
        'Number of Time experiment accumulated';
    'YT_Flag','short',1426,1 , ...
        'Set to 1 if this file contains YT data';
    'clkspd_us','float32',1428,1 , ...
        'Vert Clock Speed in micro-sec';
    'HWaccumFlag','short',1432,1 , ...
        'set to 1 if accum done by Hardware.';
    'StoreSync','short',1434,1 , ...
        'set to 1 if store sync used';
    'BlemishApplied','short',1436,1 , ...
        'set to 1 if blemish removal applied';
    'CosmicApplied','short',1438,1 , ...
        'set to 1 if cosmic ray removal applied';
    'CosmicType','short',1440,1 , ...
        'if cosmic ray applied, this is type';
    'CosmicThreshold','float32',1442,1 , ...
        'Threshold of cosmic ray removal.';
    % 'NumFrames is mandatory field'
    'NumFrames','int32',1446,1 , ...
        'number of frames in file.';
    'MaxInrensity','float32',1450,1 , ...
        'max intensity of data (future)';
    'MinInrensity','float32',1454,1 , ...
        'min intensity of data future)';
    'ylabel','char',1458,LABELMAX , ...
        'y axis label.';
    'ShutterType','uint16',1474,1 , ...
        'shutter type.';
    'shutterComp','float32',1476,1 , ...
        'shutter compensation time.';
    'readoutMode','uint16',1480,1 , ...
        'readout mode, full,kinetics, etc';
    'WindowsSize','uint16',1482,1 , ...
        'window size for kinetics only.';
    'clkspd','uint16',1484,1 , ...
        'clock speed for kinetics & frame transfer';
    'interface_type','uint16',1486,1 , ...
        'computer interface (isa-taxi, pci, eisa, etc.)';
    'NumROIsInExperiment','uint16',1488,1 , ...
        'May be more than the 10 allowed in this header (if 0, assume 1)';
    'Spare_5','char',1490,16 , ...
        '';
    'controllerNum','uint16',1506,1 , ...
        'if multiple controller system will have controller number data came from. This is a future item.';
    'SWmade','uint16',1508,1 , ...
        'Which software package created this file';
    'NumROI','short',1510,1 , ...
        'number of ROIs used. if 0 assume 1.';
    'ROIinfo',{'struct','ROIinfo'},[1512 1524 1536 1548 1560 1572 1584 1596 1609 1620],[] , ...
        '';
    'FlatField','char',1632,HDRNAMEMAX , ...
        'Flat field file name.';
    'background','char',1752,HDRNAMEMAX , ...
        'background sub. file name.';
    'blemish','char',1872,HDRNAMEMAX , ...
        'blemish file name.';
    'file_header_ver','float32',1992,1 , ...
        'version of this file header';
    'YT_Info','char',1996,1000 , ...
        'Reserved for YT information';
    'WinView_id','int32',2996,1 , ...
        '== 0x01234567L if file created by WinX';
    % Calibration Structures
    % X Calibration Structure
    'xcalibration',{'struct','XYCalib'},3000,1 , ...
        'x axis calibration';
    % Y Calibration Structure
    'ycalibration',{'struct','XYCalib'},3489,1 , ...
        'y axis calibration';
    % End of Calibration Structures
    'endcalibration',{'struct','EndCalib'},3978,1 , ...
        'End of Calibration Structures';
    };
end
