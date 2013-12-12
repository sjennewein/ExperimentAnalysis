function M = vidread_frame(HEADER,INDEX)
%VIDREAD_FRAME reads frame from .VID file
%   Package name:     VIDREAD
%   Package version:  2013-08-01 BETA
%   File version:     2013-08-01 BETA
%
%   M = VIDREAD_FRAME(HEADER,INDEX) reads INDEX frame from file, specified
%   in the HEADER structure, which is returned by calling 
%   VIDREAD_HEADER.
%
%   Example:
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
%   See also VIDREAD_HEADER, VIDREAD_TAB.

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
if INDEX > HEADER.NumFrames || INDEX < 1
    error('VIDREAD_FRAME:InvalidFrameIndex', ...
        '''INDEX'' must lie in range [1,%g] for file \"%s\"', ...
        HEADER.NumFrames,HEADER.FILEPATH);
end;

[fid,fmessage] = fopen(HEADER.FILEPATH,'r');

if fid == -1
    error('VIDREAD_FRAME:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        header.FILEPATH,fmessage);
end;

try
    status = fseek(fid, HEADER.FrameOffsets(INDEX), 'bof');
    if status == -1
        [errmessage,errnum] = ferror(fid);
        error('VIDREAD_FRAME:FseekError', ...
            'Unable to seek to frame %d in file ''%s'': [%d: %s]', ...
            INDEX,HEADER.FILEPATH,errnum,errmessage);
    end;
    
    switch HEADER.DATAORDER
        case 'column'
            SIZE = [HEADER.ydim, HEADER.xdim];
        case 'row'
            SIZE = [HEADER.xdim, HEADER.ydim];
    end;

    [M,numread] = fscanf(fid, '%g', SIZE);

    if numread ~= HEADER.ydim * HEADER.xdim
        if feof(fid)
            error('VIDREAD_FRAME:FscanfEOFReached', ...
                'Attempted to read past the end of file ''%s''', ...
                FILEPATH);
        end;
        [errmessage,errnum] = ferror(fid);
        if errnum
            error('VIDREAD_FRAME:FscanfError', ...
                'Error while reading file ''%s'': [%d: %s]', ...
                FILEPATH,errnum,errmessage);
        end;
    end;
        
    if strcmp(HEADER.DATAORDER,'row')
        M = M';
    end;

catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('VIDREAD_FRAME:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            header.FILEPATH);
    end;
    rethrow(err);
end;

status = fclose(fid);
if status == -1
    warning('VIDREAD_FRAME:FcloseFailed',... 
        'Unable to close file ''%s''',header.FILEPATH);
end;
