function varargout = vidread_header(varargin)
%VIDREAD_HEADER prepares for reading/reads .VID file
%   Package name:     VIDREAD
%   Package version:  2013-08-01 BETA
%   File version:     2013-08-01 BETA
%
%   HEADER = VIDREAD_HEADER() shows dialog for selecting .VID file
%   with pre-defined set of standard frame sizes (240x320 or 120x160 
%   pixels) and returns HEADER structure for use with VIDREAD_FRAME
%   function to read frames from file. Frame size and number of frames in
%   the file are stored in HEADER fields 'ydim', 'xdim' and 'NumFrames'. 
%   'ydim' is the number of rows, 'xdim' is the number of columns in
%   frames. Frames will be read row-wise.
%
%   HEADER = VIDREAD_HEADER(FILEPATH,[ROWS,COLS]) returns HEADER
%   structure for file FILEPATH with specified [ROWS,COLS] frame size, 
%   where ROWS is the number of rows, COLS is the number of columns 
%   in frames.
%
%   HEADER = VIDREAD_HEADER(FILEPATH,[ROWS,COLS],DATAORDER) sets
%   resulting HEADER structure 'DATAORDER' field to DATAORDER to specify how 
%   file must be read. DATAORDER can either be 'row' for row-wise reading 
%   of file frames [default], or 'column' for column-wise reading of frames.
%
%   Due to specifics of .VID format, files must be fully scanned by this 
%   function, which may take considerable amount of time (up to 4,0 seconds
%   for file with 161 frames of size 120x160px on contemporary systems with
%   standard desktop hard drives).
%
%   [HEADER,M] = VIDREAD_HEADER(...) reads full .VID file into a 3D 
%   MatLab array. Frames are selected by third dimension of the resulting 
%   array. Performance of this function call is nearly identical to 
%   HEADER = VIDREAD_HEADER(...) variants, since whole file is read in 
%   all cases. This function call may require a lot of memory to store 
%   frames, depending on file size. But, since whole file is already in
%   memory, operations with frames can have better performance.
%
%   Example 1:
%       % select .VID file using GUI dialog
%       header = vidread_header();
%       % read first frame
%       M = vidread_frame(header,1);
%
%   Example 2:
%       % scan and read FILEPATH .VID file with 120x160px, row-wise
%       header = vidread_header(FILEPATH,[120,160],'row');
%       ax = axes;
%       % display frames
%       for frame = 1:header.NumFrames
%           M = vidread_frame(header,frame);
%           imagesc(M,'Parent',ax);
%           drawnow;
%       end;
%
%   Example 3:
%       % scan and read whole file into memory
%       [header,M] = vidread_frame(FILEPATH,[120,160],'row');
%       % this is faster that Example 2, but requires more memory
%       ax = axes;
%       for frame = 1:header.NumFrames
%           imagesc(M(:,:,frame),'Parent',ax);
%       end;
%
%   See also VIDREAD_FRAME, VIDREAD_TAB.

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

%% Version history:
%   2012-07-25 BETA - first build

%% CODE
if nargin == 0
    % display GUI for selecting file
    [filename,pathname,filter] = uigetfile({'*.vid','VID Files 120x160px (*.tab)'; ...
        '*.vid','VID Files 240x320px (*.tab)'; ...
        });
    if filename
        FILEPATH = fullfile(pathname,filename);
    else
        error('VIDREAD_HEADER:TerminatedByUser', ...
            'Operation was terminated by user');
    end;
    switch filter
        case 1
            SIZE = [120,160];
        case 2
            SIZE = [240,320];
    end;
    DATAORDER = 'row';
elseif nargin == 2;
    FILEPATH = varargin{1};
    SIZE = varargin{2};
    DATAORDER = 'row';
elseif nargin == 3
    FILEPATH = varargin{1};
    SIZE = varargin{2};
    DATAORDER = varargin{3};
    if ~strcmp(DATAORDER,'row') && ~strcmp(DATAORDER,'column')
        error('VIDREAD_HEADER:ReadModeError', ...
            'Unknown READ_MODE ''%s''. See ''help speread_tab'' for information on correct values', ...
            DATAORDER);
    end;
else
    error('VIDREAD_HEADER:InvalidNumberOfArgs', ...
        'Invalid number of arguments');
end;

if nargout == 1
    readFull = 0;
elseif nargout == 2
    readFull = 1;
end;

[fid,fmessage] = fopen(FILEPATH,'r');

if fid == -1
    error('VIDREAD_HEADER:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        FILEPATH,fmessage);
end;

try

    % we don't know exact frame offsets until we read all of the previous
    % frames. That's because in .vid and .tab files data values are
    % represented in character form, without fixed convertion format, they
    % can be with or without decimal fraction part, for example -0081 or
    % -0082.9
    % That format is a real 'pleasure' to work with...
    fileinfo = dir(FILEPATH);

    % guess aproximate number of frames
    tempNumFrames = floor(fileinfo.bytes / 9 / (SIZE(1)*SIZE(2)));
    tempFrameOffsets = zeros(tempNumFrames);

    HEADER = struct();
    HEADER.FILEPATH = FILEPATH;
    HEADER.HEADER_READ_TIME = now;
    HEADER.FileSizeBytes = fileinfo.bytes;
    HEADER.DATAORDER = DATAORDER;
    HEADER.NumFrames = 0;
    HEADER.ydim = SIZE(1);
    HEADER.xdim = SIZE(2);

    if readFull
        switch HEADER.DATAORDER
            case 'column'
                SIZE = [HEADER.ydim, HEADER.xdim];
            case 'row'
                SIZE = [HEADER.xdim, HEADER.ydim];
        end;
        DATA = zeros([HEADER.ydim, HEADER.xdim, tempNumFrames]);
    end;

    while ~feof(fid)
        tempOffset = ftell(fid);

        [M,numread] = fscanf(fid, '%g', SIZE);

        if numread ~= prod(SIZE)
            if feof(fid)
                if numread ~= 0
                    warning('VIDREAD_HEADER:EOFNotReached', ...
                        'EOF was reached prematurely while reading file ''%s''. It is possible that invalid SIZE was specified.', ...
                        FILEPATH);
                end;
                break;
            end;
            [errmessage,errnum] = ferror(fid);
            if errnum
                error('VIDREAD_HEADER:FscanfError', ...
                    'Error while reading file ''%s'': [%d: %s]', ...
                    FILEPATH,errnum,errmessage);
            end;
        end;


        HEADER.NumFrames = HEADER.NumFrames + 1;
        tempFrameOffsets(HEADER.NumFrames) = tempOffset;

        if readFull
            if strcmp(HEADER.DATAORDER,'row')
                M = M';
            end;
            DATA(:,:,HEADER.NumFrames) = M;
        end;
    end;

    % test for EOF to check if invalid size is possible
    fscanf(fid, '%g', 1);
    if ~feof(fid)
        warning('VIDREAD_HEADER:EOFNotReached', ...
            'EOF was not reached after finishing reading file ''%s''. It is possible that invalid SIZE was specified.', ...
            FILEPATH);
    end;

    HEADER.FrameOffsets = tempFrameOffsets(1:HEADER.NumFrames);

    varargout{1} = HEADER;

    if readFull
        varargout{2} = DATA;
    end;

catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('VIDREAD_HEADER:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            FILEPATH);
    end;
    rethrow(err);
end;

status = fclose(fid);
if status == -1
    warning('VIDREAD_HEADER:FcloseFailed',...
        'Unable to close file ''%s''',FILEPATH);
end;
