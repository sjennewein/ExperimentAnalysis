function OUT = speread_pointvals(HEADER,ROWS,COLS,varargin)
%SPEREAD_POINTSVALS reads selected points from frames in .SPE file
%   Package name:     SPEREAD
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   POINTS = SPEREAD_POINTVALS(HEADER,ROWS,COLS) reads points with
%   index (ROWS(i),COLS(i)) from all frames in the file, specified
%   in the HEADER structure, which was returned by calling SPEREAD_HEADER
%   on that file. ROWS,COLS can be two scalars, or vectors of the same
%   size.
%
%   POINTS = SPEREAD_POINTVALS(HEADER,ROWS,COLS,FRAMES) reads points
%   from frames with numbers defined in FRAMES only. FRAMES can be a scalar
%   or a vector.
%
%   POINTS is a structure with fields 'row', 'col' and 'data'. 'row' and
%   'col' are row and column indices of the point, and data is a vector
%   with point values from selected frames. If FRAMES was specified than
%   data(i) corresponds to the value in FRAMES(i) frame. Otherwise, data(i)
%
%   If more than one point was selected, then POINTS will be an array of
%   structures. Points in this array are sorted by indices in ascending
%   order (it means from min(ROW(i) * HEADER.xdim + COL(i)) to
%   max(ROW(i) * HEADER.xdim + COL(i))).
%
%   Examples:
%       % read element (10,10) values from all frame matrices
%       header = speread_header(filepath,speread_vardata('spe_min_2.5'));
%       point = speread_pointvals(header,10,10);
%       plot(1,header.NumFrames,point.data);
%
%       % read element (10,10) from [1, 3, 5 ...] frames
%       header = speread_header(filepath,speread_vardata('spe_min_2.5'));
%       frames = 1:2:header.NumFrames;
%       point = speread_pointvals(header,10,10,frames);
%       plot(frames,point.data,'*-');
%
%       % read elements (10,10), (500,354), (2,256)
%       header = speread_header(filepath,speread_vardata('spe_min_2.5'));
%       frames = 1:2:header.NumFrames;
%       row = [10,500,2];
%       col = [10,354,256];
%       point = speread_pointvals(header,row,col,frames);
%       plot(frames,point(1).data,'b*-',frames,point(2).data,'r*-', ...
%           frames,point(3).data,'g*-');
%       legend(sprintf('[%g,%g]',point(1).row,point(1).col), ...
%           sprintf('[%g,%g]',point(2).row,point(2).col), ...
%           sprintf('[%g,%g]',point(3).row,point(3).col));
%
%   See also SPEREAD_HEADER, SPEREAD_VARDATA, SPEREAD_FRAME.

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
%   2013-08-01 - added support for column order
%   2011-11-05 - updated to support TVID format
%   2011-04-16 - first version

%% CODE
if ~isnumeric(ROWS) || ~isnumeric(COLS)
    error('SPEREAD_POINTVALS:InvalidArgs', ...
        'ROWS and COLS must be numeric');
end;

if size(ROWS) ~= size(COLS)
    error('SPEREAD_POINTVALS:InvalidArgs', ...
        'ROWS and COLS vectors must be of the same size');
end;

if any(ROWS) > HEADER.ydim || any(COLS) > HEADER.xdim
    error('SPEREAD_POINTVALS:InvalidArgs', ...
        'Some [ROW,COL] indices exceed frame size for this HEADER');
end;

if nargin < 4
    FRAMES = 1:HEADER.NumFrames;
else
    if isnumeric(varargin{1})
        FRAMES = varargin{1};
    else
        error('SPEREAD_POINTVALS:InvalidArgs', ...
            'FRAMES must be numeric');
    end;
end;

if strcmp(HEADER.DATAORDER,'row')
    INDICES_ALL = (ROWS-1)*HEADER.xdim + (COLS-1);
elseif strcmp(HEADER.DATAORDER,'column')
    INDICES_ALL = (COLS-1)*HEADER.ydim + (ROWS-1);
else
    error('SPEREAD_POINTVALS:InvalidDataorder', ...
        'header.dataorder ''%s'' is unknown',HEADER.DATAORDER);
end;

[INDICES,I] = unique(INDICES_ALL);

% prepare output structure
OUT = struct();
for point = 1:length(INDICES)
    OUT(point).row = ROWS(I(point));
    OUT(point).col = COLS(I(point));
    OUT(point).data = zeros(1,length(FRAMES));
end;

[fid,fmessage] = fopen(HEADER.FILEPATH,'r');

if fid == -1
    error('SPEREAD_POINTVALS:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        HEADER.FILEPATH,fmessage);
end;

try

    for frame = 1:length(FRAMES)
        % seek to the beginning of frame
        frame_off = HEADER.DATA_OFFSET + ...
            HEADER.ydim*HEADER.xdim*(FRAMES(frame)-1) * ...
            HEADER.DATATYPE_SIZE;
        status = fseek(fid,frame_off,'bof');
        
        if status == -1
            [errmessage,errnum] = ferror(fid);
            error('SPEREAD_POINTVALS:FseekError', ...
                'Unable to seek to frame %d in file ''%s'': [%d: %s]', ...
                FRAMES(frame),HEADER.FILEPATH,errnum,errmessage);
        end;

        for point = 1:length(INDICES)
            status = fseek(fid,frame_off + INDICES(point) * ...
                HEADER.DATATYPE_SIZE,'bof');
            if status == -1
                [errmessage,errnum] = ferror(fid);
                error('SPEREAD_POINTSVAL:FseekError', ...
                    'Unable to seek to %g element in frame %d in file ''%s'': [%d: %s]', ...
                    INDICES(point),FRAMES(frame),HEADER.FILEPATH,errnum,errmessage);
            end;
            [DATA,numread] = fread(fid,1,HEADER.DATATYPE_STR);
            if numread ~= 1
                if feof(fid)
                    error('SPEREAD_POINTSVAL:FreadEOFReached', ...
                        'End of file encountered in ''%s'' while reading %g element in frame %d', ...
                        HEADER.FILEPATH,INDICES(point),FRAMES(frame));
                end;
                [errmessage,errnum] = ferror(fid);
                if errnum
                    error('SPEREAD_POINTSVAL:FreadError', ...
                        'Error while attemting to read %g element in frame %d in file ''%s'': [%d: %s]', ...
                        INDICES(point),FRAMES(frame),HEADER.FILEPATH,errnum,errmessage);
                end;
            end;
            OUT(point).data(frame) = DATA;
        end;

    end;

catch
    status = fclose(fid);
    if status == -1
        warning('SPEREAD_POINTVALS:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            HEADER.FILEPATH);
    end;
    rethrow(lasterror);
end;

status = fclose(fid);
if status == -1
    warning('SPEREAD_POINTVALS:FcloseFailed',... 
        'Unable to close file ''%s''',HEADER.FILEPATH);
end;
