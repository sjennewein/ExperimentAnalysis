function varargout = lambdaread(lambda_obj, lambda_event);

% LAMBDAREAD - callback to read bytes on Lambda 10-2 serial port
%
%    LAMBDAREAD(OBJ, EVENT) is the BytesAvailableFcn callback routine for
%    the serial port object LAMBDA_PORT.  This routine reads the commands
%    echoed by the Lambda 10-2 and compares them to the commands saved in the
%    UserData field.  Any errors are stored to the UserData field of LAMBDA_PORT.
%    This or another callback function may be used by the calling routine to wait
%    for the Lambda 10-2 to process and echo commands.
%
%    MSG = LAMBDAREAD(OBJ, EVENT) returns an error message MSG if an error occurs.

% 3/24/03 SCM

% validate arguments
if (nargin ~= 2)
    err_msg = 'type ''help lambdaread'' for syntax';
elseif (~isa(lambda_obj, 'serial'))
    err_msg = 'OBJ must be a valid serial port';
elseif (~isvalid(lambda_obj))
    err_msg = 'OBJ must be a valid serial port';
elseif (~isfield(lambda_event, 'Type') | ~isfield(lambda_event, 'Data'))
    err_msg = 'EVENT must be a valid event structure';
else
    err_msg = '';
end

% process event based on type
lambda_struct = get(lambda_obj, 'UserData');
if (~isstruct(lambda_struct))
    err_msg = 'could not find valid UserData structure';
elseif (isempty(err_msg))
    switch (lambda_event.Type)
        case 'BytesAvailable'
            % read echo from Lambda 10-2 & compare with written bytes
            if (lambda_obj.BytesAvailable > 0)
                byte_read = double(fread(lambda_obj, lambda_obj.BytesAvailable, 'uint8'));
                byte_read = reshape(byte_read, 1, prod(size(byte_read)));
                write_cmd = char([lambda_struct.command 13]);
                if (length(byte_read) ~= length(write_cmd))
                    err_msg = 'length mismatch';
                elseif (~strcmp(char(byte_read), write_cmd))
                    err_msg = 'character mismatch';
                end
            else
                err_msg = 'no bytes';
            end
        case 'Error'
            err_msg = 'timeout';
        case 'Timer'
            err_msg = 'timer event';
        otherwise
            err_msg = 'unknown';
    end
end

% return or display error message
lambda_struct.error = err_msg;
set(lambda_obj, 'UserData', lambda_struct);
switch (nargout)
    case 0
        if (~isempty(err_msg))
            disp(sprintf('Lambda 10-2 error: %s', err_msg));
        end
    case 1
        varargout{1} = err_msg;
    otherwise
        varargout{1} = err_msg;
        [varargout{2 : nargout}] = deal([]);
end
return
