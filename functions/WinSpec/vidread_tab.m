function M = vidread_tab(varargin)
%VIDREAD_TAB reads frame from .TAB file
%   Package name:     VIDREAD
%   Package version:  2013-08-01 BETA
%   File version:     2012-07-25 BETA
%
%   M = VIDREAD_TAB() shows dialog for selecting .TAB file with pre-defined
%   set of standard frame sizes (240x320 or 120x160 pixels) and returns 
%   frame read from selected file. Frame will be read row-wise.
%
%   M = VIDREAD_TAB(FILEPATH,SIZE) reads frame row-wise from old format 
%   .tab file into M matrix. SIZE is the size of the frame in form 
%   [rows,cols]. FILEPATH is full path to the .tab file.
%
%   M = VIDREAD_TAB(FILEPATH,SIZE,READMODE) reads frame according to
%   READMODE parameter. If READMODE is 'col', data will be read
%   column-wise from the file. If READMODE is 'row', data will be read
%   row-wise.
%
%   For better performance, convert .TAB files to .TVID format, using 
%   VID2TVID software package, and read resulting .TVID files using 
%   SPEREAD package.
%
%   Example 1:
%       % select and read 240x320px .tab with a dialog
%       M = vidread_tab();
%       % display read frame
%       imagesc(M);
%
%   Example 2:
%       % read .tab file from 'filepath' with size 120x160px, column-wise
%       M = vidread_tab(filepath,[120,160],'col');
%       % display read frame
%       imagesc(M);
%
%   See also VIDREAD_HEADER, VIDREAD_FRAME

%% LICENSE
% Copyright (c) 2008-2012 Alexander Nikitin
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
    [filename,pathname,filter] = uigetfile({'*.tab','TAB Files 120x160px (*.tab)'; ...
        '*.tab','TAB Files 240x320px (*.tab)'; ...
        });
    if filename
        FILEPATH = fullfile(pathname,filename);
    else
        error('VIDREAD_TAB:TerminatedByUser', ...
            'Operation was terminated by user');
    end;
    switch filter
        case 1
            SIZE = [120,160];
        case 2
            SIZE = [240,320];
    end;
    readmode = 'row';
elseif nargin == 2;
    FILEPATH = varargin{1};
    SIZE = varargin{2};
    readmode = 'row';
elseif nargin == 3
    FILEPATH = varargin{1};
    SIZE = varargin{2};
    readmode = varargin{3};
    if ~strcmp(readmode,'row') && ~strcmp(readmode,'col')
        error('VIDREAD_TAB:ReadModeError', ...
                'Unknown READ_MODE ''%s''. See ''help vidread_tab'' for information on correct values', ...
                readmode);
    end;
else
    error('VIDREAD_TAB:InvalidNumberOfArgs', ...
                'Invalid number of arguments');
end;

[fid,fmessage] = fopen(FILEPATH,'r');

if fid == -1
    error('VIDREAD_TAB:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        FILEPATH,fmessage);
end;

try

    if strcmp(readmode,'row')
        temp = SIZE(1);
        SIZE(1) = SIZE(2);
        SIZE(2) = temp;
    end;
    
    [M,numread] = fscanf(fid, '%g', SIZE);

    if numread ~= prod(SIZE)
        if feof(fid)
            error('VIDREAD_TAB:FscanfEOFReached', ...
                'Attempted to read past the end of file ''%s''', ...
                FILEPATH);
        end;
        [errmessage,errnum] = ferror(fid);
        if errnum
            error('VIDREAD_TAB:FscanfError', ...
                'Error while reading file ''%s'': [%d: %s]', ...
                FILEPATH,errnum,errmessage);
        end;
    end;
    
    % test for EOF to check if invalid size is possible
    fscanf(fid, '%g', 1);
    if ~feof(fid)
        warning('VIDREAD_TAB:EOFNotReached', ...
            'EOF was not reached after finishing reading file ''%s''. It is possible that invalid SIZE was specified.', ...
            FILEPATH);
    end;
    
    if strcmp(readmode,'row')
        M = M';
    end;

catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('VIDREAD_TAB:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            FILEPATH);
    end;
    rethrow(err);
end;

status = fclose(fid);
if status == -1
    warning('VIDREAD_TAB:FcloseFailed',...
        'Unable to close file ''%s''',FILEPATH);
end;
