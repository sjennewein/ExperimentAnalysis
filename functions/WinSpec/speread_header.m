function [header,vardata,structDecl] = speread_header(varargin)
%SPEREAD_HEADER reads header from .SPE version 2.5 compatible file
%   Package name:     SPEREAD
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   Use this function before calling SPEREAD data functions.
%
%   HEADER = SPEREAD_HEADER() shows a dialog box for selecting the
%   file with the supported specification and header structure from this 
%   file as defined in the selected specification. List of supported 
%   specifications can be aquired by calling SPEREAD_VARDATA().
%
%   HEADER = SPEREAD_HEADER(FILEPATH) returns the header structure
%   from FILEPATH file according to the default specification. Default
%   specification is described in the first row of cell array received by
%   SPEREAD_VARDATA() function call.
%
%   HEADER = SPEREAD_HEADER(FILEPATH,VARDATA) returns header structure
%   defined in VARDATA variable from FILEPATH file.
%
%   HEADER = SPEREAD_HEADER(FILEPATH,VARDATA,STRUCTDECL) must be called if
%   VARDATA containes structure fields.
%
%   For information on the VARDATA and STRUCTDECL variables, see help
%   for SPEREAD_VARDATA function.
%
%   [HEADER,VARDATA] = SPEREAD_HEADER(...) also returns used VARDATA 
%   variable.
%
%   [HEADER,VARDATA,STRUCTDECL] = SPEREAD_HEADER(...) also returns used 
%   STRUCTDECL structure with structure definitions used while processing 
%   VARDATA.
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
%       % simple TVID player
%       header = speread_header(filepath,speread_vardata('tvid_160_120'));
%       ax = axes;
%       for frame = 1:header.NumFrames
%           M = speread_frame(header,frame);
%           imagesc(M,'Parent',ax);
%           drawnow;
%       end;
%
%       % don't forget to pass STRUCTDECL variable if VARDATA contains
%       % custom structures
%       [vardata,structdecl] = speread_vardata('spe_full_2.5');
%       header = speread_header(filepath,vardata,structdecl);
%
%   See also SPEREAD_VARDATA, SPEREAD_FRAME, SPEREAD_POINTVALS.

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
%   2013-08-01 - improved dialog with support for all specification
%                defined in updated SPEREAD_VARDATA function
%   2011-11-05 - updated version, added support for TVID files
%   2011-04-16 - added reminder in help 'Examples' section
%                about the need to use STRUCTDECL structure 
%                if VARDATA uses custom structures
%   2011-04-15 - minor code cleanup
%   2010-08-20 - complete rewrite of code, new capabilities are 
%                introduced, old versions are now obsolete
%   2010-08-11 - FILEPATH should now always contain a full path 
%                to the file (using which(FILEPATH)), renamed
%                field header.readdate to header.HEADER_READ_TIME
%   2010-08-07 - minor fix - removed dependency upon
%                fopen_wstatus, fclose_wstatus, this m-file is now
%                standalone and doesn't require other functions
%                except matlab built-ins
%   2009-03-09 - first build

%% CODE
% input checks
if nargin == 0
    % get supported specs
    formats = speread_vardata();
    % display GUI for selecting file
    [filename,pathname,formind] = uigetfile(formats(:,2:3));
    if filename
        header.FILEPATH = fullfile(pathname,filename);
    else
        error('SPEREAD_HEADER:TerminatedByUser', ...
            'Operation was terminated by user');
    end;
    [vardata,structDecl] = speread_vardata(formats{formind,1});
elseif nargin > 0
    % check that file exists
    header.FILEPATH = varargin{1};
    if ~exist(header.FILEPATH,'file');
        error('SPEREAD_HEADER:FileNotFound', ...
            'Specified file ''%s'' does not exist',header.FILEPATH);
    end;
    if nargin >= 2
        % user specified vardata
        vardata = varargin{2};
        structDecl = struct([]);
        if nargin == 3
            structDecl = varargin{3};
            if ~isstruct(structDecl)
                error('SPEREAD_HEADER:StructDeclNotStruct', ...
                    '''structDecl'' must be a structure');
            end;
        end;
        if iscell(vardata)
            if size(vardata,2) < 4
                error('SPEREAD_HEADER:VardataInvalid', ...
                    '''vardata'' must contain at least 4 collumns');
            end;
        else
            error('SPEREAD_HEADER:VardataNotCell', ...
                '''vardata'' must be a cell array');
        end;
        if nargin > 3
            error('SPEREAD_HEADER:TooManyArgs', ...
                'Too many arguments');
        end;
    else
        formats = speread_vardata();
        % work with full SPE format header
        [vardata,structDecl] = speread_vardata(formats{1,1});
    end;
end;
%% Check VARDATA
RESERVED_FIELD_NAMES = {'FILEPATH','HEADER_READ_TIME'};
REQUIRED_FIELD_NAMES = {'xdim','ydim','NumFrames','DATA_OFFSET', ...
                        'DATAORDER'};
REQUIRED_FIELD_NAMES_ALT = {'datatype',{'DATATYPE_STR','DATATYPE_SIZE'}};

% check vardata correctness
temp = unique(vardata(:,1));
if(size(temp) ~= size(vardata(:,1)))
    error('SPEREAD_HEADER:DuplicateHeaderFields', ...
        'Duplicate header fields found');
end;
if any(ismember(RESERVED_FIELD_NAMES,vardata(:,1)))
    error('SPEREAD_HEADER:ReservedFieldName', ...
        'Reserved field name found');
end;
if ~all(ismember(REQUIRED_FIELD_NAMES,vardata(:,1)))
    error('SPEREAD_HEADER:ReqFieldNameNotFound', ...
        'Required field name not found');
end;
for i = 1:size(REQUIRED_FIELD_NAMES_ALT,1)
    conforms = 0;
    if ismember(REQUIRED_FIELD_NAMES_ALT(i,1),vardata(:,1));
        conforms = conforms + 1;
    else
        alts = REQUIRED_FIELD_NAMES_ALT{i,2};
        for j = 1:size(alts,1)
            if all(ismember(alts(j,:),vardata(:,1)))
                conforms = conforms + 1;
            end;
        end;
    end;
    if conforms ~= 1
        error('SPEREAD_HEADER:NoReqMutExAltFields', ...
            'Mutually exclusive alternative fields requirement not fulfiled');
    end;
end;

%% Start Processing
header.HEADER_READ_TIME = now;

[fid,fmessage] = fopen(header.FILEPATH,'r');

if fid == -1
    error('SPEREAD_HEADER:FopenError', ...
        'Unable to open file ''%s'' with read permissions: [%s]', ...
        header.FILEPATH,fmessage);
end;

try
    for count = 1:size(vardata,1)
        % check if user constant
        if vardata{count,3} == -1
            header.(vardata{count,1}) = vardata{count,4};
            continue;
        end;
        % not constant
        if ~iscell(vardata{count,2})
            data = read_basic_element(fid,vardata{count,2}, ...
                vardata{count,3},vardata{count,4},header.FILEPATH);
            header.(vardata{count,1}) = data;
        else
            if strcmp(vardata{count,2}{1},'struct')
                % data will be a struct field
                if isfield(structDecl,vardata{count,2}{2})
                    vardata_sub = structDecl.(vardata{count,2}{2});
                    for count_str = 1:length(vardata{count,3})
                        struct_el = struct();
                        for count_sub = 1:size(vardata_sub,1)
                            struct_el.(vardata_sub{count_sub,1}) = read_basic_element(fid, ...
                                vardata_sub{count_sub,2}, ...
                                vardata{count,3}(count_str) + vardata_sub{count_sub,3}, ...
                                vardata_sub{count_sub,4},header.FILEPATH);
                        end;
                        header.(vardata{count,1})(count_str) = struct_el;
                    end;
                else
                    error('SPEREAD_HEADER:structDeclFieldNotFound', ...
                        'Definition for ''%s'' structure field not found',vardata{count,2}{2});
                end;
            else
                % data will be a cell array
                rows = 1:size(vardata{count,2},1);
                cols = 1:size(vardata{count,2},2);
                cell_el = cell(rows(end),cols(end));
                for row = rows
                    for col = cols
                        cell_el{row,col} = read_basic_element(fid, ...
                            vardata{count,2}{row,col}, ...
                            vardata{count,3}(row,col), ...
                            vardata{count,4}(row,col), header.FILEPATH);
                    end;
                end;
                header.(vardata{count,1}) = cell_el;
            end;
        end;
    end;
    
%% SPE format multi datatype support
    % create additional fields for datatype information (SPE format only)
    if ~isfield(header,'DATATYPE_STR') && ~isfield(header,'DATATYPE_SIZE')
        if isfield(header,'datatype')
            switch header.datatype
                case 0 % floating point
                    header.DATATYPE_STR = 'float32';
                    header.DATATYPE_SIZE = 4;
                case 1 % long integer
                    header.DATATYPE_STR = 'int32';
                    header.DATATYPE_SIZE = 4;
                case 2 % integer
                    header.DATATYPE_STR = 'int16';
                    header.DATATYPE_SIZE = 2;
                case 3 % unsigned integer
                    header.DATATYPE_STR = 'uint16';
                    header.DATATYPE_SIZE = 2;
            end;
        end;
    end;
    
%% Finish Processing
catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('SPEREAD_HEADER:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            header.FILEPATH);
    end;
    rethrow(err);
end;

status = fclose(fid);
if status == -1
    warning('SPEREAD_HEADER:FcloseFailed','Unable to close file ''%s''',header.FILEPATH);
end;

end

%% INTERNAL FUNCTIONS

function data = read_basic_element(fid,type,offset,numel,filename)
% reads single element from absolute offset from the begining of file
% if numel > 1 - reads elements into vector array
% type is source data type, like 'uint16' or 'float32'
% filename is used in error strings
status = fseek(fid,offset,'bof');
if status == -1
    [errmessage,errnum] = ferror(fid);
    error('SPEREAD_HEADER:READ_ELEMENT:FseekError', ...
        'Error while seeking to offset %d in file ''%s'': [%d: %s]', ...
        offset, filename,errnum,errmessage);
end;

if strcmp(type,'char')
    % by default fread returns double for char
    precission_str = 'char=>char';
else
    precission_str = type;
end;

% read data
[data,numread] = fread(fid,numel,precission_str);
if numread ~= numel
    if feof(fid)
        error('SPEREAD_HEADER:READ_ELEMENT:FreadEOFReached', ...
            'Error while reading file ''%s'' at offset %d: end of file reached', ...
            filename,offset);
    end;
    [errmessage,errnum] = ferror(fid);
    if errnum
        error('SPEREAD_HEADER:READ_ELEMENT:FreadError', ...
            'Error while reading file ''%s'' at offset %d: [%d: %s]', ...
            filename,offset,errnum,errmessage);
    end;
end;

% we need to transpose data because fread returns elements as rows
if strcmp(type,'char')
    data = transpose(data);
else
    if numel > 1
        data = transpose(data);
    end;
end;
end
