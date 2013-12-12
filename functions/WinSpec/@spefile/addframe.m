function speobj = addframe(speobj,frame)
%ADDFRAME Add frame to SPEFILE object.
%   Package name:     SPEFILE
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   See also SPEFILE, SPEFILE/CLOSE.

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
%   2013-08-01 - release version
%   2012-08-02 - alpha version

%% CODE
if ~isa(speobj,'spefile')
    error('SPEFILE:ADDFRAME:InvalidObjectInput', ...
        'First input argument must be a spefile object.');
end

if speobj.finished
    error('SPEFILE:CLOSE:NotOpen', ...
        'The file is not open.');
end;

if speobj.NumFrames == 0
    speobj.xdim = size(frame,2);
    speobj.ydim = size(frame,1);
else
    if speobj.xdim ~= size(frame,2) || speobj.ydim ~= size(frame,1)
        error('SPEFILE:ADDFRAME:FrameSizeNotSame', ...
            'All frames must be of the same size.');
    end;
end;
if ndims(frame) ~= 2
    error('SPEFILE:ADDFRAME:DimensionNot2D', ...
        'All frames must be two-dimensional matrices.');
end;

% transpose if row order
if strcmp(speobj.DATAORDER,'row')
    M = transpose(frame);
else
    M = frame;
end;

[fid,fmessage] = fopen(speobj.filepath,'a');

if fid == -1
    error('SPEFILE:ADDFRAME:FopenError', ...
        'Unable to open file ''%s'' with write permissions: [%s]', ...
        speobj.filepath,fmessage);
end;

% this makes recovery possible if there were errors in previous call to
% this function (ex., frame wasn't fully written)
status = fseek(fid, speobj.DATA_OFFSET ...
    + speobj.ydim * speobj.xdim * (speobj.NumFrames) * ...
    speobj.DATATYPE_SIZE, 'bof');

if status == -1
    [errmessage,errnum] = ferror(fid);
    error('SPEFILE:ADDFRAME:FseekError', ...
        'Unable to seek in file ''%s'': [%d: %s]', ...
        speobj.filepath, errnum, errmessage);
end;

try

    count = fwrite(fid,M,speobj.DATATYPE_STR);

    if count ~= numel(M)
        [errmessage,errnum] = ferror(fid);
        error('SPEFILE:ADDFRAME:FwriteError', ...
            'Error while writing to file ''%s'': [%d: %s]', ...
            speobj.filepath,errnum,errmessage);
    end;

catch
    err = lasterror;
    status = fclose(speobj.FileHandle);
    if status == -1
        warning('SPEFILE:ADDFRAME:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            speobj.filepath);
    end;
    speobj.CurrentState = 'Error';
    rethrow(err);
end;

speobj.NumFrames = speobj.NumFrames + 1;

status = fclose(fid);
if status == -1
    warning('SPEFILE:ADDFRAME:FcloseFailed','Unable to close file ''%s''', ...
        speobj.filepath);
end;
