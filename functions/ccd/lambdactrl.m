function varargout = lambdactrl(varargin);

% LAMBDACTRL - routines to control Sutter Lambda 10-2 thru serial port
%
%    HOBJ = LAMBDACTRL('initialize') opens the serial port HOBJ and sets
%    the Lambda 10-2 on-line in serial mode.
%
%    LAMBDACTRL(HOBJ, 'callback', BYTEFCN) allows the calling routine to
%    specify a BytesAvailableFcn callback routine.  If not specified, the
%    default BytesAvailableFcn callback routine is LAMBDAREAD.M.
%
%    LAMBDACTRL(HOBJ, 'wheel', WHEEL) selects wheel A (WHEEL = 1) or wheel
%    B (WHEEL = 2) as the target for subsequent shutter, filter & speed
%    commands.
%
%    LAMBDACTRL(HOBJ, 'open') opens the shutter on the selected wheel.
%
%    LAMBDACTRL(HOBJ, 'close') closes the shutter on the selected wheel.
%
%    LAMBDACTRL(HOBJ, 'filter', POSITION) changes the position of the
%    selected wheel to the value specified by POSITION (0 - 9).
%
%    LAMBDACTRL(HOBJ, 'speed', SPEED) changes the speed of the selected
%    wheel to the value specified by SPEED (0 - 7).
%
%    LAMBDACTRL(HOBJ, 'batch', SHUTTER, FILTER, SPEED) sends a batch
%    command to operate both wheels simultaneously.  SHUTTER, FILTER and
%    SPEED are two element numeric arrays to indicate the shutter state
%    (0 = closed, 1 = open), filter position and speed for both wheels.
%
%    LAMBDACTRL(HOBJ, 'clear') closes the serial port.
%
% Note that the UserData field of serial port object HOBJ contains a
% structure to store the selected wheel, filter and speed settings, as well
% as the current commands sent to the Lambda 10-2 through the serial port.
%
% This code also contains the BytesAvailableFcn callback routine, which
% reads the commands echoed by the Lambda 10-2 and compares them to the
% commands saved in the UserData field.  Any errors are stored to the
% UserData field of the serial port. This or another callback function may
% be used by the calling routine to wait for the Lambda 10-2 to process and
% echo commands.

% 5/17/02 SCM
% modified 3/28/03 SCM
% modified 7/7/05 SCM to pass serial port object

% Lambda 10-2 parameters
serial_port = 'COM1';   % use COM1 serial port
time_out = 3;           % timeout period (sec)
lambda_tag = 'lambda 10-2'; % serial port tag
lambda_fcn = @lambdaread;   % default callback function

% Lambda 10-2 UserData structure
field_list = {'command', 'wheel', 'filter', 'speed', 'error'};
field_default = {[], 1, [0 0], [2 2], ''};

% other parameters
syntax_err = 'type ''help lambdactrl'' for syntax';
serial_err = 'HOBJ is not a valid serial port';
control_cmd = '';       % no command to execute in switch(command) below
lambda_cmd = [];        % device command to write to serial port

% initialize outputs
if (nargout > 0)
    varargout = cell(1, nargout);
end

% validate arguments
if (nargin == 1)
    if (~ischar(varargin{1}))
        warning(syntax_err);
        return
    elseif (~strcmp(varargin{1}, 'initialize'));
        warning(syntax_err);
        return
    else
        lambda_port = [];
        control_cmd = varargin{1};
        lambda_param = lambda_fcn;
    end
else
    if (~isa(varargin{1}, 'serial'))
        warning(serial_err);
        return
    elseif (~isvalid(varargin{1}))
        warning(serial_err);
        return
    elseif (~ischar(varargin{2}))
        warning(syntax_err);
        return
    else
        lambda_port = varargin{1};
        control_cmd = varargin{2};
        % get Lambda 10-2 parameter structure if it exists
        % otherwise initialize with default values
        lambda_struct = defstruc(get(lambda_port, 'UserData'), field_list, field_default);
    end
    if (nargin == 2)
        if (isempty(strmatch(control_cmd, {'open', 'close', 'clear'})));
            warning(syntax_err);
            return
        else
            lambda_param = lambda_fcn;
        end
    elseif (nargin == 3)
        if (isempty(strmatch(control_cmd, {'callback', 'wheel', 'speed', 'filter'})))
            warning(syntax_err);
            return
        elseif (~isa(varargin{3}, 'function_handle') & ~isscalar(varargin{3}))
            warning(syntax_err);
            return
        else
            lambda_param = varargin{3};
        end
    elseif (nargin == 5)
        if (~strcmp(control_cmd, 'batch'));
            warning(syntax_err);
            return
        end
        for i = 3 : nargin
            if (~isnumeric(varargin{i}) | (prod(size(varargin{i})) ~= 2))
                warning(syntax_err);
                control_cmd = '';
            end
        end
    else
        warning(syntax_err);
        return
    end
end


switch (control_cmd)

    case 'initialize'   % get serial port control of Lambda 10-2
        % configure serial port if needed
        % confirm serial port is open
        lambda_port = instrfind('Type', 'serial', 'Port', serial_port, 'Tag', lambda_tag);
        if (isempty(lambda_port))
            serial_list = instrfind('Type', 'serial', 'Port', serial_port);
            if (~isempty(serial_list))
                fclose(serial_list);
            end
            if (isa(lambda_param, 'function_handle'))
                lambda_func = lambda_param;
            else
                lambda_func = lambda_fcn;
            end
            lambda_port = serial(serial_port, ...
                'BaudRate', 9600, ...
                'BytesAvailableFcn', lambda_func, ...
                'ErrorFcn', lambda_func, ...
                'DataBits', 8, ...
                'Parity', 'none', ...
                'StopBits', 1, ...
                'Terminator', 'CR', ...
                'Timeout', time_out, ...
                'Tag', lambda_tag, ...
                'UserData', []);
            fopen(lambda_port);
        else
            lambda_port = lambda_port(1);
            if (strcmp(get(lambda_port, 'Status'), 'closed'))
                fopen(lambda_port);
            end
        end

        % get Lambda 10-2 parameter structure if it exists
        % otherwise initialize with default values
        lambda_struct = defstruc(get(lambda_port, 'UserData'), field_list, field_default);

        % send command to initialize
        lambda_struct.command = [];
        lambda_cmd = 238;

    case 'callback'     % set serial port BytesAvailableFcn
        set(lambda_port, 'BytesAvailableFcn', lambda_param);

    case 'wheel'    % select wheel
        if ((lambda_param == 1) | (lambda_param == 2))
            lambda_struct.wheel = lambda_param;
        else
            warning(sprintf('LAMBDACTRL - wheel %d is not valid, should be 1 or 2', lambda_param));
        end

    case 'open'     % open the selected shutter
        open_shutter = [170 186];   % commands to open shutters A & B
        lambda_cmd = open_shutter(lambda_struct.wheel);

    case 'close'    % close the selected shutter
        close_shutter = [172 188];  % commands to close shutters A & B
        lambda_cmd = close_shutter(lambda_struct.wheel);

    case 'filter'   % change the position of the selected wheel
        if ((lambda_param >= 0) & (lambda_param <= 9))
            lambda_struct.filter(lambda_struct.wheel) = lambda_param;
            lambda_cmd = 128*(lambda_struct.wheel - 1) + ...
                16*lambda_struct.speed(lambda_struct.wheel) + lambda_struct.filter(lambda_struct.wheel);
        else
            warning(sprintf('LAMBDACTRL - filter %d is not valid, should be 0 - 9\n', lambda_param));
        end

    case 'speed'    % change the speed of the selected wheel
        if ((lambda_param >= 0) & (lambda_param <= 7))
            lambda_struct.speed(lambda_struct.wheel) = lambda_param;
            lambda_cmd = 128*(lambda_struct.wheel - 1) + ...
                16*lambda_struct.speed(lambda_struct.wheel) + lambda_struct.filter(lambda_struct.wheel);
        else
            warning(sprintf('LAMBDACTRL - speed %d is not valid, should be 0 - 7', lambda_param));
        end

    case 'batch'    % provide a batch command - shutter A, shutter B, wheel A, wheel B
        % copy & reshape input arguments
        % make 5 element vectors for arithmetic below
        shutter_list = [0 reshape(varargin{3}, 1, 2) 0 0];
        filter_list = [0 0 0 reshape(varargin{4}, 1, 2)];
        speed_list = [0 0 0 reshape(varargin{5}, 1, 2)];

        % validate shutter, filter & speed parameters
        if (any(shutter_list < 0) | any(shutter_list > 1))
            warning('LAMBDACTRL (batch) - shutter should be 0 or 1');
        elseif (any(filter_list < 0) | any(filter_list > 9))
            warning('LAMBDACTRL (batch) - filter should be 0 - 9');
        elseif (any(speed_list < 0) | any(speed_list > 7))
            warning('LAMBDACTRL (batch) - speed should be 0 - 7');
        else
            % save new filter & speed settings
            lambda_struct.filter = filter_list(4 : 5);
            lambda_struct.speed = speed_list(4 : 5);

            % create base byte list = [BATCH CLOSE_A CLOSE_B WHEEL_A WHEEL_B]
            % modify 2nd & 3rd bytes to open shutter if specified
            % changes 172 -> 170 and 188 -> 186 if shutter A or B to open
            % modify 4th & 5th bytes to specify wheel A & B positions & speeds
            lambda_cmd = [223 172 188 0 128] - (2 * shutter_list) + (16 * speed_list) + filter_list;
        end

    case 'clear'    % close and delete serial port
        fclose(lambda_port);
        delete(lambda_port);
        return

    otherwise       % invalid command
        warning(syntax_err);
        return
end

% output command to serial port if specified
% otherwise update values in parameter structure
if (isempty(lambda_cmd))
    set(lambda_port, 'UserData', lambda_struct);
else
    % initialize error field to indicate no echo yet
    % don't allow duplicate command
    % Lambda 10-2 will ignore and won't echo
    if (strcmp(char(lambda_struct.command), char(lambda_cmd)))
        lambda_struct.error = 'duplicate command';
        set(lambda_port, 'UserData', lambda_struct);
    else
        lambda_struct.error = 'no echo';
        lambda_struct.command = lambda_cmd;
        set(lambda_port, 'UserData', lambda_struct);
        fwrite(lambda_port, uint8(lambda_cmd), 'uint8');
    end
end

% return serial port handle as output
if (nargout > 0)
    varargout{1} = lambda_port;
end
return
