function speobj = close(speobj)
%CLOSE Close SPEFILE object.
%   Package name:     SPEFILE
%   Package version:  2013-08-01
%   File version:     2013-08-01
%
%   See also SPEFILE, SPEFILE/ADDFRAME.

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
    error('SPEFILE:CLOSE:InvalidObjectInput', ...
        'First input must be a spefile object.');
end

if speobj.finished
    error('SPEFILE:CLOSE:NotOpen', ...
        'The file is not open.');
end;

if speobj.NumFrames == 0
    warning('SPEFILE:CLOSE:NoAssociatedFrames', ...
        'Warning: No frames were added to file.');
end

[fid,fmessage] = fopen(speobj.filepath,'r+');

if fid == -1
    error('SPEFILE:CLOSE:FopenError', ...
        'Unable to open file ''%s'' with append permissions: [%s]', ...
        speobj.filepath,fmessage);
end;

try
    for count = 1:size(speobj.vardata,1)
        % check if user constant
        if speobj.vardata{count,3} == -1
            continue;
        end;
        % check if field is auto-updated
        if strcmp(speobj.vardata{count,1},'xdim')
            write_basic_element(fid, ...
                speobj.xdim, ...
                speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                speobj.vardata{count,4}, ...
                speobj.filepath, 'xdim');
            continue;
        elseif strcmp(speobj.vardata{count,1},'ydim')
            write_basic_element(fid, ...
                speobj.ydim, ...
                speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                speobj.vardata{count,4}, ...
                speobj.filepath, 'ydim');
            continue;
        elseif strcmp(speobj.vardata{count,1},'NumFrames')
            write_basic_element(fid, ...
                speobj.NumFrames, ...
                speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                speobj.vardata{count,4}, ...
                speobj.filepath, 'NumFrames');
            continue;
        end;
        % single element field
        if ~iscell(speobj.vardata{count,2})
            if strcmp(speobj.vardata{count,1},'datatype') && ...
                    speobj.datatype_override_flag
                write_basic_element(fid, ...
                    speobj.datatype_override, ...
                    speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                    speobj.vardata{count,4}, speobj.filepath, ...
                    speobj.vardata{count,1});
            elseif strcmp(speobj.vardata{count,1},'DATA_OFFSET') && ...
                    speobj.data_offset_override_flag
                write_basic_element(fid, ...
                    speobj.DATA_OFFSET, ...
                    speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                    speobj.vardata{count,4}, speobj.filepath, ...
                    speobj.vardata{count,1});
            else
                % check if field should be ignored
                if ~isfield(speobj.header,speobj.vardata{count,1}) && ...
                        speobj.ignore_missing_header_fields
                    continue;
                end;
                write_basic_element(fid, ...
                    speobj.header.(speobj.vardata{count,1}), ...
                    speobj.vardata{count,2}, speobj.vardata{count,3}, ...
                    speobj.vardata{count,4}, speobj.filepath, ...
                    speobj.vardata{count,1});
            end;
        else
            if strcmp(speobj.vardata{count,2}{1},'struct')
                % data will be a struct field
                for count_str = 1:length(speobj.vardata{count,3})
                    if isfield(speobj.structDecl, ...
                            speobj.vardata{count,2}{2})
                        vardata_sub = speobj.structDecl.( ...
                            speobj.vardata{count,2}{2});
                        struct_el = speobj.header.(speobj.vardata{count,1})(count_str);
                        for count_sub = 1:size(vardata_sub,1)
                            write_basic_element(fid, struct_el.(vardata_sub{count_sub,1}), ...
                                vardata_sub{count_sub,2}, ...
                                speobj.vardata{count,3}(count_str) + vardata_sub{count_sub,3}, ...
                                vardata_sub{count_sub,4}, ...
                                speobj.filepath, ...
                                speobj.vardata{count,1});
                        end;
                    else
                        error('SPEFILE:CLOSE:structDeclFieldNotFound', ...
                            'Definition for ''%s'' structure field not found', ...
                            speobj.vardata{count,2}{2});
                    end;
                end;
            else
                % data will be a cell array
                rows = 1:size(speobj.vardata{count,2},1);
                cols = 1:size(speobj.vardata{count,2},2);
                cell_el = speobj.header.(speobj.vardata{count,1});
                for row = rows
                    for col = cols
                        write_basic_element(fid, cell_el{row,col}, ...
                            speobj.vardata{count,2}{row,col}, ...
                            speobj.vardata{count,3}(row,col), ...
                            speobj.vardata{count,4}(row,col), ...
                            speobj.filepath, ...
                            speobj.vardata{count,1});
                    end;
                end;
            end;
        end;
    end;

catch
    err = lasterror;
    status = fclose(fid);
    if status == -1
        warning('SPEFILE:CLOSE:RecoveryFcloseFailed', ...
            'Error occured during call to fclose() on file ''%s'' while recovering from previous error', ...
            speobj.filepath);
    end;
    speobj.CurrentState = 'Error';
    rethrow(err);
end;

speobj.finished = 1;

status = fclose(fid);
if status == -1
    warning('SPEFILE:CLOSE:FcloseFailed','Unable to close file ''%s''', ...
        speobj.filepath);
end;

speobj.CurrentState = 'Closed';

end

function data = write_basic_element(fid,data,type,offset,num_el,filename, ...
    fieldname)

if num_el ~= numel(data)
    error('SPEFILE:CLOSE:WRITE_ELEMENT:DataNumelNotEqual', ...
        'Data in HEADER field ''%s'' is of different size than specified in VARDATA.', ...
        fieldname);
end;

status = fseek(fid,offset,'bof');
if status == -1
    [errmessage,errnum] = ferror(fid);
    error('SPEFILE:CLOSE:WRITE_ELEMENT:FseekError', ...
        'Error while seeking to offset %d in file ''%s'': [%d: %s]', ...
        offset, filename,errnum,errmessage);
end;

if numel(data) > 1
    data = transpose(data);
end;

count = fwrite(fid,data,type);

if count ~= numel(data)
    [errmessage,errnum] = ferror(fid);
    error('SPEFILE:CLOSE:WRITE_ELEMENT:FwriteError', ...
        'Error while writing to file ''%s'': [%d: %s]', ...
        filename,errnum,errmessage);
end;

end
