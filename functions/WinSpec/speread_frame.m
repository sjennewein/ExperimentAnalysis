function M = speread_frame(HEADER,INDEX)
%SPEREAD_FRAME reads frame from .SPE compatible file
%   Package name:     SPEREAD
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   M = SPEREAD_FRAME(HEADER,INDEX) reads INDEX frame from file, specified
%   in the HEADER structure, which is returned by calling SPEREAD_HEADER.
%
%   Example:
%       % simple SPE player
%       header = speread_header(filepath,speread_vardata('spe_min_2.5'));
%       ax = axes;
%       for frame = 1:header.NumFrames
%           M = speread_frame(header,frame);
%           imagesc(M,'Parent',ax);
%           drawnow;
%       end;
%
%   See also SPEREAD_HEADER, SPEREAD_VARDATA, SPEREAD_POINTVALS.

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
%   2013-08-01 - added support for column order of data
%   2011-11-05 - updated to work with TVID files and other SPE-like
%                formats
%   2011-04-15 - changed name of this function from SPEREAD_DATA 
%                to SPEREAD_FRAME to properly reflect its purpose
%   2010-08-20 - modified to work with SPEREAD_HEADER 2010-08-20,
%                old versions are now obsolete
%   2010-08-07 - minor fix - removed dependency upon
%                fopen_wstatus, fclose_wstatus, this m-file is now
%                standalone and doesn't require other functions
%                except matlab built-ins
%   2009-03-10 - performance improvements
%   2009-03-09 - first build

%% CODE
if INDEX > HEADER.NumFrames || INDEX < 1
    error('SPEREAD_FRAME:InvalidFrameIndex', ...
        '''INDEX'' must lie in range [1,%g] for file \"%s\"', ...
        HEADER.NumFrames,HEADER.FILEPATH);
end;

[fid,fmessage] = fopen(HEADER.FILEPATH,'r');

if fid == -1
    error('SPEREAD_FRAME:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        header.FILEPATH,fmessage);
end;

try

    status = fseek(fid, HEADER.DATA_OFFSET ...
        + HEADER.ydim*HEADER.xdim*(INDEX-1)*HEADER.DATATYPE_SIZE, 'bof');
    if status == -1
        [errmessage,errnum] = ferror(fid);
        error('SPEREAD_FRAME:FseekError', ...
            'Unable to seek to frame %d in file ''%s'': [%d: %s]', ...
            INDEX,HEADER.FILEPATH,errnum,errmessage);
    end;

    % reading as a matrix and then transposing the result seems to be much
    % faster that reading rows of data in matlab
    if strcmp(HEADER.DATAORDER,'row')
        [DATA,numread] = fread(fid,[HEADER.xdim,HEADER.ydim],HEADER.DATATYPE_STR);
    elseif strcmp(HEADER.DATAORDER,'column')
        [DATA,numread] = fread(fid,[HEADER.ydim,HEADER.xdim],HEADER.DATATYPE_STR);
	else
        error('SPEREAD_POINTVALS:InvalidDataorder', ...
            'header.dataorder ''%s'' is unknown',HEADER.DATAORDER);
    end;
    
    if numread ~= HEADER.ydim*HEADER.xdim
        if feof(fid)
            error('SPEREAD_FRAME:FreadEOFReached', ...
                'Attempted to read past the end of file ''%s'' while reading %d frame', ...
                HEADER.FILEPATH,INDEX);
        end;
        [errmessage,errnum] = ferror(fid);
        if errnum
            error('SPEREAD_FRAME:FreadError', ...
                'Error while reading %d frame from file ''%s'': [%d: %s]', ...
                INDEX,HEADER.FILEPATH,errnum,errmessage);
        end;
    end;
    
    % transpose data after fread if data order is row-wise
    % for column order, no further operations are necesary
    if strcmp(HEADER.DATAORDER,'row')
        M = transpose(DATA);
    elseif strcmp(HEADER.DATAORDER,'column')
        M = DATA;
    end;
catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('SPEREAD_FRAME:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            header.FILEPATH);
    end;
    rethrow(err);
end;

status = fclose(fid);
if status == -1
    warning('SPEREAD_FRAME:FcloseFailed',... 
        'Unable to close file ''%s''',header.FILEPATH);
end;
