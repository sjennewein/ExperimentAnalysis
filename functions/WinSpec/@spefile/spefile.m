function speobj = spefile(filepath,header,vardata,varargin)
%SPEFILE Create a new SPE file
%   Package name:     SPEFILE
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   SPEOBJ = SPEFILE(FILENAME,HEADER,VARDATA) creates a SPEFILE object
%   SPEOBJ with header created with fields specified in VARDATA cell
%   array and corresponding field values specified in HEADER structure.
%   Use SPEFILE/CLOSE to close the file opened by SPEFILE.
%
%   SPEOBJ = SPEFILE(FILENAME,HEADER,VARDATA,STRUCTDECL) must be called if 
%   VARDATA contains structures. STRUCTDECL is a structure containing 
%   definitions for structures used in VARDATA.
%
%   HEADER, VARDATA and STRUCTDECL parameters must be of the same
%   specification as used in SPEREAD package. For more information,
%   see help for SPEREAD_VARDATA function.
%
%   HEADER can contain more fields than specified in VARDATA, but only 
%   those fields that are specified in VARDATA will be written to the file. 
%   Header fields that were not specified will be initialized with zeros.
%   VARDATA fields not present in HEADER will also be initialized with
%   zeros. Header is only written to the file after call to SPEFILE/CLOSE.
%
%   If VARDATA contains elements with names 'xdim', 'ydim', 'NumFrames',
%   then corresponding HEADER values are ignored. Instead, frame size and
%   number of frames that are correct for created SPEFILE are written to 
%   the output file to offsets that are specified in VARDATA for these
%   fields.
%
%   IMPORTANT LIMITATIONS: Currently, the following condition apply to
%   HEADER and VARDATA arguments when used with SPEFILE functions:
%
%       - DATA_OFFSET must either be a constant in VARDATA, or
%         alternative HEADER_SIZE constant must be present in VARDATA. This
%         constant is used instead of DATA_OFFSET to determine start of
%         data, and is written to file to offset specified for DATA_OFFSET
%         variable.
%       - DATAORDER must be constant
%       - DATATYPE_STR and DATATYPE_SIZE must be constant or the following
%         conditions are applied:
%           - if 'datatype' field is present in the HEADER and VARDATA
%             (converting from WinView to WinView file), then output file
%             will have the same 'datatype' as input file
%           - Otherwise, default datatype 'float32' (datatype = 0 for 
%             WinView files) is used
%
%   Example 1:
%       % read .SPE file to be copied
%       [vardata,structdecl] = speread_vardata('spe_full_2.5');
%       header = speread_header(filepath,vardata,structdecl);
%       % initialize new .SPE file
%       speobj = spefile('copy.spe',header,vardata,structdecl);
%       for frame = 1:header.NumFrames
%           M = speread_frame(header,frame);
%           % add M frame to 'copy.spe'
%           speobj = addframe(speobj,M);
%       end;
%       % write header to new file and close it
%       close(speobj);
%
%       % check if frames are identical between original and copy
%       header2 = speread_header('copy.spe',vardata,structdecl);
%       for frame = 1:header.NumFrames
%           M1 = speread_frame(header,frame);
%           M2 = speread_frame(header2,frame);
%           if any(any(M1 ~= M2))
%               disp('ERROR DETECTED');
%               break;
%           end;
%       end;
%
%   Example 2:
%       % read .SPE to copy its header fields into new file
%       [vardata,structdecl] = speread_vardata('spe_full_2.5');
%       header = speread_header(filepath,vardata,structdecl);
%       % initialize new .SPE file
%       speobj = spefile('simulation.spe',header,vardata,structdecl);
%       % write simulation data to file. In this example we will
%       % write random values into 50 frames with frame size 1000x1000
%       for i = 1:50
%           M = rand(1000,1000);
%           speobj = addframe(speobj,M);
%       end;
%       close(speobj);
%
%   See also SPEFILE/ADDFRAME, SPEFILE/CLOSE.

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
%   2013-08-01 - release version, added support for column order of data
%   2012-08-02 - alpha version

%% CODE
if nargin < 3
    error('SPEFILE:SPEFILE:NotEnoughArguments', ...
        'Not enough input arguments');
elseif ~isa(filepath,'char') || ~isa(header,'struct') ...
        || ~isa(vardata,'cell')
    error('SPEFILE:SPEFILE:InvalidArguments', ...
        'Invalid argument type');
end;

speobj = struct();
speobj.header = header;
speobj.vardata = vardata;

if nargin == 4
    if isa(varargin{1},'struct')
        speobj.structDecl = varargin{1};
    else
        error('SPEFILE:SPEFILE:InvalidArguments', ...
            'Invalid argument type');
    end;
end;

% determine required data write parameters
ind_dataoffset = strmatch('DATA_OFFSET',vardata(:,1),'exact');
ind_datatypestr = strmatch('DATATYPE_STR',vardata(:,1),'exact');
ind_datatypesize = strmatch('DATATYPE_SIZE',vardata(:,1),'exact');
ind_headersize = strmatch('HEADER_SIZE',vardata(:,1),'exact');
ind_dataorder = strmatch('DATAORDER',vardata(:,1),'exact');
ind_datatype = strmatch('datatype',vardata(:,1),'exact');

% processing flags
speobj.datatype_override_flag = false;
speobj.data_offset_override_flag = false;
speobj.ignore_missing_header_fields = true;

if isempty(ind_dataoffset) ||  isempty(ind_dataorder)
    error('SPEFILE:SPEFILE:RequiredFieldsMissing',...
            'Missing required fields in VARDATA');
else
    if vardata{ind_dataoffset,3} ~= -1
        % look for HEADER_SIZE field to use as DATA_OFFSET
        if isempty(ind_headersize)
            error('SPEFILE:SPEFILE:NoDATAOFFSETAlternative',...
                'HEADER_SIZE alternative to constant DATA_OFFSET not found');
        else
            if vardata{ind_headersize,3} ~= -1
                error('SPEFILE:SPEFILE:HEADERSIZENotConstant',...
                    'HEADER_SIZE not constant');
            else
                speobj.DATA_OFFSET = vardata{ind_headersize,4};
                speobj.data_offset_override_flag = true;
            end;
        end;
    else
        speobj.DATA_OFFSET = vardata{ind_dataoffset,4};
    end;
    if vardata{ind_dataorder,3} ~= -1
        error('SPEFILE:SPEFILE:RequiredFieldsNotConstant',...
            'Only constant required fields are supported in this version');
    else
        if isempty(ind_datatypestr) || isempty(ind_datatypesize)
            if ~isempty(ind_datatype)
                % when converting from spe to spe
                if isfield(header,'datatype')
                    speobj.DATATYPE_STR = header.DATATYPE_STR;
                    speobj.DATATYPE_SIZE = header.DATATYPE_SIZE;
                else
                    % use default
                    speobj.DATATYPE_STR = 'float32';
                    speobj.DATATYPE_SIZE = 4;
                    % when converting to spe from another header
                    speobj.datatype_override = 0;
                    speobj.datatype_override_flag = true;
                end;
            else
                error('SPEFILE:SPEFILE:RequiredFieldsMissing',...
                    'Missing required fields in VARDATA');
            end;
        else
            speobj.DATATYPE_STR = vardata{ind_datatypestr,4};
            speobj.DATATYPE_SIZE = vardata{ind_datatypesize,4};
        end;
    end;
end;

% Fields required to write frames to file
speobj.DATAORDER = vardata{ind_dataorder,4};

% These fields are auto-updated on first frame insert
speobj.xdim = 0;
speobj.ydim = 0;
% These fields are auto-updated on any frame insert
speobj.NumFrames = 0;
% other flags
speobj.finished = 0;
% this is purely for information when calling SPEFILE/display function
speobj.CurrentState = 'Open';

speobj.filepath = filepath;

% init header with zeros to prepare for frames writing
temp = zeros(1,speobj.DATA_OFFSET,'uint8');

[fid,fmessage] = fopen(speobj.filepath,'w');

if fid == -1
    error('SPEFILE:SPEFILE:FopenError', ...
        'Unable to open file ''%s'' with write permissions: [%s]', ...
        speobj.filepath,fmessage);
end;

try
    count = fwrite(fid,temp);

    if count ~= numel(temp)
        [errmessage,errnum] = ferror(fid);
        error('SPEFILE:SPEFILE:FwriteError', ...
            'Error while writing to file ''%s'': [%d: %s]', ...
            speobj.filepath,errnum,errmessage);
    end;

    status = fclose(fid);
    if status == -1
        warning('SPEFILE:SPEFILE:FcloseFailed','Unable to close file ''%s''', ...
            speobj.filepath);
    end;
catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('SPEFILE:SPEFILE:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            speobj.filepath);
    end;
    rethrow(err);
end;

% create class object
speobj = class(speobj,'spefile');
