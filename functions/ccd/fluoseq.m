function [] = fluoseq(varargin)
addpath('pvcam');
addpath('gui');
addpath('color');
addpath('utilities');
% FLUOSEQ - perform non-ratiometric imaging during drug application
%
%    FLUOSEQ acquires a sequence of non-ratiometric images during drug
%    application.  A GUI interface is provided to control the acquisition.
%
%    If no PVCAM device is found, the program will operate in a demo mode
%    where images will be generated randomly.

% 3/31/03 SCM

% Files required:
% ---------------
% PVCAM*.DLL and PVCAM*.M
% LAMBDACTRL.M and LAMBDAREAD.M
% ROIPARSE.M
% UINT8/UINT16 DLLs
% UTILITY package
% Image processing toolbox (for ROIPOLY command)

% Files needed for compiling PVCAM DLLs:
% --------------------------------------
% PVCAM*.C & PVCAM*.H (for source code, compiled under MATLAB 6.5)
% PVCAM32.LIB (PVCAM library)
% PVCAM32_MANUAL.PDF (reference for parameter names)

% validate arguments
if (nargin == 0)
    control_command = 'initialize';
elseif (nargin ~= 2)
    warning('MATLAB:fluoseq', 'type ''help fluoseq'' for syntax');
    return
elseif (isa(varargin{1}, 'serial') && isvalid(varargin{1}) && ...
        isfield(varargin{2}, 'Type') && isfield(varargin{2}, 'Data'))
    % Lambda 10-2 callback
    lambda_port = varargin{1};
    lambda_event = varargin{2};
    h_fig = gcf;
    control_command = 'lambda callback';
elseif (~istype(varargin{1}, 'figure'))
    warning('MATLAB:fluoseq', 'H_FIG must be a valid figure window');
    return
elseif (~ischar(varargin{2}) || isempty(varargin{2}))
    warning('MATLAB:fluoseq', 'CMD must be a string');
    return
else
    h_fig = varargin{1};
    control_command = lower(varargin{2});
end

% obtain UserData from HFIG
% check for valid contents
if (~strcmp(control_command, 'initialize'))
    user_data = get(h_fig, 'UserData');
    if (iscell(user_data) && (length(user_data) >= 7))
        [fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par] = deal(user_data{1 : 7});
    else
        warning('MATLAB:fluoseq', 'cannot find valid UserData cell array in H_FIG');
        return
    end
end

% figure window parameters
% used by Lambda 10-2 interface
motion_fcn = 'fluoseq(gcbo, ''pointer value'')';
figure_tag = 'fluoseq';

switch (control_command)

    case 'initialize'       % open figure window
        % camera parameters
        %pvcam_getpar = {'PARAM_BIT_DEPTH', 'PARAM_CHIP_NAME', 'PARAM_FRAME_CAPABLE', 'PARAM_MPP_CAPABLE', ...
        %    'PARAM_PAR_SIZE', 'PARAM_SER_SIZE', 'PARAM_PREMASK', 'PARAM_TEMP'};
        %pvcam_getvalue = {12, 'demo mode', 0, 'mpp mode unknown', ...
        %    512, 512, 0, 0};
        pvcam_getpar = {'PARAM_BIT_DEPTH', 'PARAM_CHIP_NAME', ...
            'PARAM_PAR_SIZE', 'PARAM_SER_SIZE', 'PARAM_PREMASK', 'PARAM_TEMP'};
        pvcam_getvalue = {12, 'demo mode', 512, 512, 0, 0};
        pvcam_setpar = {'PARAM_CLEAR_MODE', 'PARAM_CLEAR_CYCLES', 'PARAM_GAIN_INDEX', ...
            'PARAM_PMODE', 'PARAM_SHTR_OPEN_MODE', 'PARAM_SHTR_CLOSE_DELAY', 'PARAM_SHTR_OPEN_DELAY', ...
            'PARAM_SPDTAB_INDEX', 'PARAM_TEMP_SETPOINT'};
        %pvcam_setvalue = {'clear pre-sequence', 2, 3, ...
        %    'normal parallel clocking', 'open shutter pre-sequence', 10, 5, 2, -2500};
        pvcam_setvalue = {'clear pre-sequence', 2, 2, ...
            'normal parallel clocking', 'open shutter pre-sequence', 10, 5, 0, 2000};

        % Lambda 10-2 parameters
        % LAMBDA PARAMS WILL BE EDITABLE IN FUTURE VERSIONS!
        lambda_par = cell2struct({1, [1 0], [5 2], 5, 'lambda 10-2', @fluoseq, []}, ...
            {'wheel', 'filter', 'speed', 'wait', 'name', 'fcn', 'port'}, 2);

        % initialize camera
        % operate in demo mode & use camera defaults if error
        h_cam = pvcamopen(0);
        if (isempty(h_cam))
            disp('FLUOSEQ: could not open camera, using DEMO mode');
            pvcamclose(0);
            pvcam_get = cell2struct(pvcam_getvalue, pvcam_getpar, 2);
            pvcam_set = cell2struct(pvcam_setvalue, pvcam_setpar, 2);
        else
            % read camera parameters
            disp('FLUOSEQ: camera detected');
            for i = 1 : length(pvcam_getpar)
                pvcam_get.(pvcam_getpar{i}) = pvcamgetvalue(h_cam, pvcam_getpar{i});
            end

            % set camera parameters
            for i = 1 : length(pvcam_setpar)
                if (pvcamsetvalue(h_cam, pvcam_setpar{i}, pvcam_setvalue{i}))
                    pvcam_set.(pvcam_setpar{i}) = pvcamgetvalue(h_cam, pvcam_setpar{i});
                else
                    warning('MATLAB:fluoseq', 'could not set %s, using current value', pvcam_setpar{i});
                    pvcam_set.(pvcam_setpar{i}) = pvcamgetvalue(h_cam, pvcam_setpar{i});
                end
            end
        end

        % create image parameters structure
        % create default ROI from camera parameters w/o binning
        image_size = [pvcam_get.PARAM_SER_SIZE pvcam_get.PARAM_PAR_SIZE];
        roi_coord = [1 1 image_size];
        field_name = {'h_cam', 'h_lambda', 'h_fluoseq', 'filter_name', 'roi_full', 'roi_coord', 'image_mask', ...
            'image_size', 'bit_depth', 'expose_time', 'image_time', 'image_total', 'bin_full', 'color_map'};
        field_value = {h_cam, [], [], 'none', create_roi_struct(roi_coord, [1 1]), roi_coord, [], ...
            image_size, pvcam_get.PARAM_BIT_DEPTH, 10, 30, 20, [1 1], @jet};
        image_par = cell2struct(field_value, field_name, 2);

        % create file parameters structure
        field_name = {'file_path', 'file_name', 'file_prefix', 'image_count', 'start_time', 'acq_time'};
        field_value = {'c:\scm\cells', '', 'scm', 0, clock, clock};
        file_par = cell2struct(field_value, field_name, 2);

        % open image window
        delete(findobj('Type', 'figure', 'Tag', figure_tag));
        h_fig = make_image_win(figure_tag);

        % obtain figure handles from HFIG
        % initialize colormap
        % disable all buttons to start
        % these will be enabled during Lambda 10-2 callback
        fig_handle = get(h_fig, 'UserData');
        disp_colorbar(h_fig, fig_handle.h_axes(2), image_par.color_map);

        % obtain focus parameters from PVCAMFOCUS
        % save structures in HFIG UserData
        %focus_par = pvcamfocus(fig_handle.h_axes(1), 'initialize', h_cam, image_par.expose_time, image_par.roi_full);
        focus_par = [];
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        fluoseq(h_fig, 'lambda detect');

    case 'pointer value'        % obtain value under mouse pointer
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_data = get(h_image, 'UserData');
            [ptr_pos, ptr_flag] = ptrpos(h_fig, fig_handle.h_axes(1), 'image');
            if ((ptr_pos(1) >= 1) && (ptr_pos(1) <= size(image_data, 2)) && ...
                    (ptr_pos(2) >= 1) && (ptr_pos(2) <= size(image_data, 1)) && ptr_flag)
                ptr_val = double(image_data(ptr_pos(2), ptr_pos(1)));
                elapsed_time = datestr(datenum(file_par.acq_time) - datenum(file_par.start_time), 13);
                ptr_text = sprintf('Image: %d    Elapsed Time: %s    Intensity at (%d, %d) = %g', file_par.image_count, ...
                    elapsed_time, ptr_pos(1) + image_par.roi_coord(1) - 2, ptr_pos(2) + image_par.roi_coord(2) - 2, ptr_val);
                set(fig_handle.h_text(1), 'String', ptr_text);
            end
        end

    case 'lambda detect'
        % initialize filter wheel
        % set timer and Lambda 10-2 callbacks to determine if filter wheel present
        % presence of Lambda 10-2 is independent of DEMO mode
        % buttons will be enabled during either callback
        if (~isa(image_par.h_lambda, 'timer'))
            image_par.h_lambda = timer(...
                'ExecutionMode', 'fixedrate', ...
                'BusyMode', 'drop');
        end
        set(image_par.h_lambda, ...
            'TasksToExecute', 1, ...
            'StartDelay', lambda_par.wait, ...
            'Period', lambda_par.wait, ...
            'StartFcn', 'fluoseq(gcf, ''lambda setup'')', ...
            'TimerFcn', 'fluoseq(gcf, ''no lambda 10-2'')', ...
            'StopFcn', '', ...
            'ErrorFcn', 'fluoseq(gcf, ''no lambda 10-2'')');
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        set(h_fig, 'Tag', control_command);
        lambda_par.port = lambdactrl('initialize');
        lambdactrl(lambda_par.port, 'callback', lambda_par.fcn);
        lambdactrl(lambda_par.port, 'wheel', lambda_par.wheel);
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        start(image_par.h_lambda);

    case 'lambda setup'         % setup filter and speed
        lambdactrl(lambda_par.port, 'batch', [0 0], lambda_par.filter, lambda_par.speed);

    case 'lambda callback'      % check echo from serial port
        % check echo from serial port unless initializing
        % echo should not be completed until command is finished
        % proceed with acquisition if bytes read back
        err_msg = lambdaread(lambda_port, lambda_event);
        if (strcmp(get(h_fig, 'Tag'), 'lambda detect'))
            if (isa(image_par.h_lambda, 'timer'))
                stop(image_par.h_lambda);
            end
            image_par.filter_name = lambda_par.name;
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            set(h_fig, 'Tag', figure_tag);
            enable_buttons(fig_handle.h_button, file_par, image_par);
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
            disp('FLUOSEQ: Lambda 10-2 detected');
        elseif (~isempty(err_msg))
            warning('MATLAB:fluoseq', 'Lambda 10-2 error: %s', err_msg);
            set(h_fig, 'Tag', figure_tag);
            enable_buttons(fig_handle.h_button, file_par, image_par);
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        elseif (~strcmp(get(h_fig, 'Tag'), figure_tag))
            fluoseq(h_fig, 'acquire image');
        end

    case 'no lambda 10-2'       % configure the program to run w/o Lambda 10-2
        stop(image_par.h_lambda);
        set(h_fig, 'Tag', figure_tag);
        disp(sprintf('FLUOSEQ: Lambda 10-2 not found after %d sec', round(lambda_par.wait)));
        yes_no = questdlg('Reset the Lambda 10-2 and try again?', 'Lambda 10-2 not found', 'yes', 'no', 'no');
        if (strcmp(yes_no, 'yes'))
            fluoseq(h_fig, 'lambda detect');
        else
            enable_buttons(fig_handle.h_button, file_par, image_par);
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        end

    case 'start sequence'       % setup timed image acquisition
        % setup timer
        if (isa(image_par.h_fluoseq, 'timer'))
            stop(image_par.h_fluoseq);
        else
            image_par.h_fluoseq = timer(...
                'ExecutionMode', 'fixedrate', ...
                'BusyMode', 'drop');
        end
        set(image_par.h_fluoseq, ...
            'TasksToExecute', image_par.image_total, ...
            'StartDelay', 0, ...
            'Period', image_par.image_time, ...
            'StartFcn', '', ...
            'StopFcn', 'fluoseq(gcf, ''stop sequence'')', ...
            'ErrorFcn', 'fluoseq(gcf, ''stop sequence'')');
        if (strcmp(image_par.filter_name, lambda_par.name))
            set(image_par.h_fluoseq, 'TimerFcn', 'set(gcf, ''Tag'', ''start sequence''); fluoseq(gcf, ''open shutter'')');
        else
            set(image_par.h_fluoseq, 'TimerFcn', 'set(gcf, ''Tag'', ''start sequence''); fluoseq(gcf, ''acquire image'')');
        end

        % change stop button callback to stop timer
        % start timer
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        set(fig_handle.h_button(4), 'Callback', 'fluoseq(gcf, ''stop sequence'')');
        set(fig_handle.h_button, 'Enable', 'off');
        set(fig_handle.h_button(4), 'Enable', 'on');
        set(h_fig, 'WindowButtonMotionFcn', '');
        start(image_par.h_fluoseq);

    case 'open shutter'         % open shutter for timed sequences
        lambdactrl(lambda_par.port, 'open');

    case 'stop sequence'        % stop timed image acquisition
        % stop running timer
        if (isa(image_par.h_fluoseq, 'timer'))
            stop(image_par.h_fluoseq);
        end
        set(fig_handle.h_button(4), 'Callback', 'set(gcf, ''Tag'', ''stop'')');
        set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        enable_buttons(fig_handle.h_button, file_par, image_par);

    case {'snap image', 'start focus'}      % setup snap or focus
        % disable buttons and open shutter
        % this will execute lambda 10-2 command callback upon completion
        % remainder of image acquisition will be completed here
        set(fig_handle.h_button, 'Enable', 'off');
        set(fig_handle.h_button(4), 'Enable', 'on');
        set(h_fig, 'WindowButtonMotionFcn', '');
        set(h_fig, 'Tag', control_command);

        % initiate acquisition directly or via Lambda 10-2 callback
        if (strcmp(image_par.filter_name, lambda_par.name))
            lambdactrl(lambda_par.port, 'open');
        else
            fluoseq(h_fig, 'acquire image');
        end

    case 'acquire image'        % callback following lambda 10-2 command echo
        % perform single or repetitive acquisition if specified
        image_cmd = get(h_fig, 'Tag');
        switch (image_cmd)

            case 'snap image'       % acquire single image
                [image_data, file_par] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, 'normal');
                set(h_fig, 'Tag', figure_tag);
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
                set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
                enable_buttons(fig_handle.h_button, file_par, image_par);

            case 'start focus'      % continuously acquire until stop is detected
                % call PVCAMFOCUS to obtain images
                % reset image parameters following focus
                %focus_par = pvcamfocus(h_fig, 'start focus', focus_par);
                %if (istype(focus_par{1}.h_image, 'image'))
                %    set(fig_handle.h_axes(1), 'UserData', focus_par{1}.h_image);
                %end
                
                % old focus code
                if (~isempty(image_par.h_cam))
                    [param_value, param_type, param_access, param_range] = pvcamgetvalue(image_par.h_cam, 'PARAM_SPDTAB_INDEX');
                    pvcamsetvalue(image_par.h_cam, 'PARAM_SPDTAB_INDEX', max(param_range));
                end
                while (~strcmp(get(h_fig, 'Tag'), 'stop'))
                    [image_data, file_par] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, 'focus');
                    if (isempty(image_data) || ~isnumeric(image_data))
                        break
                    end
                end
                % end old focus code

                % close LAMBDA 10-2 shutter and reset other parameters
                set(h_fig, 'Tag', figure_tag);
                if (strcmp(image_par.filter_name, lambda_par.name))
                    lambdactrl(lambda_par.port, 'close');
                end
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
                set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
                enable_buttons(fig_handle.h_button, file_par, image_par);

            case 'start sequence'   % acquire single image for timed sequence
                [image_data, file_par] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, 'normal');
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

                % update display of pixel intensity
                if (isempty(image_data) || ~isnumeric(image_data))
                    fluoseq(h_fig, 'stop sequence');
                else
                    image_time = etime(file_par.acq_time, file_par.start_time) / 60;
                    if (all(size(image_par.image_mask) == size(image_data)))
                        pixel_value = sum(sum(double(image_par.image_mask) .* ...
                            double(image_data))) / sum(sum(double(image_par.image_mask)));
                    else
                        pixel_value = mean(mean(double(image_data)));
                    end
                    h_line = get(fig_handle.h_axes(3), 'UserData');
                    if (istype(h_line, 'line'))
                        set(h_line, 'XData', [get(h_line, 'XData') image_time]);
                        set(h_line, 'YData', [get(h_line, 'YData') pixel_value]);
                    else
                        axes(fig_handle.h_axes(3));
                        h_line = line(image_time, pixel_value);
                        set(fig_handle.h_axes(3), 'FontName', 'helvetica', 'FontSize', 8, 'Tag', 'graph', 'UserData', h_line);
                    end
                end
        end

    case 'select region'        % select region for intensity calculation
        axes(fig_handle.h_axes(1));
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_par.image_mask = roipoly;
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            fluoseq(h_fig, 'show region');
        end

    case 'show region'          % display region for intensity calculation
        axes(fig_handle.h_axes(1));
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_data = get(h_image, 'UserData');
            if (all(size(image_par.image_mask) == size(image_data)))
                image_mask = image_data .* (1 - feval(class(image_data), image_par.image_mask));
                disp_single_image(image_mask, fig_handle, image_par, file_par);
                set(h_image, 'UserData', image_data);
            end
        end

    case 'clear region'         % clear region for intensity calculation
        image_par.image_mask = [];
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_data = get(h_image, 'UserData');
            if (~isempty(image_data))
                disp_single_image(image_data, fig_handle, image_par, file_par);
            end
        end
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

    case 'reset graph'      % reset time and graph display
        file_par.image_count = 0;
        file_par.start_time = clock;
        delete(get(fig_handle.h_axes(3), 'Children'));
        set(fig_handle.h_axes(3), 'UserData', []);
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

    case 'parameters'       % define sequence parameters
        % setup editing of acquisition parameters for GUISTRUCT
        field_name = {'file_path', 'file_prefix', 'expose_time', 'image_time', 'image_total', 'bin_full'};
        field_lower = [-Inf -Inf 0 0 1 1];
        field_upper = Inf * ones(size(field_lower));
        field_title = {'File path', 'File prefix', 'Exposure (ms)', 'Cycle (sec)', 'Image count', 'Pixel bins'};
        field_format = {'%s', '%s', '%d', '%d', '%d', '%d'};
        field_multi = {'string', 'string', 'scalar', 'scalar', 'scalar', 'vector'};

        % obtain parameters from FILE_PAR and IMAGE_PAR to edit
        edit_struct = [];
        for i = 1 : length(field_name)
            if (isfield(file_par, field_name{i}))
                edit_struct.(field_name{i}) = file_par.(field_name{i});
            elseif (isfield(image_par, field_name{i}))
                edit_struct.(field_name{i}) = image_par.(field_name{i});
            end
        end
        [edit_struct, edit_flag] = guistruct('Acquisition Parameters', ...
            edit_struct, field_lower, field_upper, field_title, field_format, field_multi);

        % modify parameters if selected
        if (isstruct(edit_struct) && edit_flag)
            field_name = fieldnames(edit_struct);
            for i = 1 : length(field_name)
                if (isfield(file_par, field_name{i}))
                    file_par.(field_name{i}) = edit_struct.(field_name{i});
                elseif (isfield(image_par, field_name{i}))
                    image_par.(field_name{i}) = edit_struct.(field_name{i});
                end
            end

            % update ROI structure in case binning changed
            % recalculate focus parameters
            image_par.roi_full = create_roi_struct(image_par.roi_coord, image_par.bin_full);
            %focus_par = pvcamfocus(fig_handle.h_axes(1), 'initialize', ...
            %    image_par.h_cam, image_par.expose_time, image_par.roi_full);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        end

    case 'camera setup'     % edit PVCAM parameters
        pvcam_setpar = fieldnames(pvcam_set);
        [new_value, edit_flag] = pvcameditor(image_par.h_cam, pvcam_setpar);
        if (edit_flag)
            for i = 1 : length(pvcam_setpar)
                pvcam_set.(pvcam_setpar{i}) = pvcamgetvalue(image_par.h_cam, pvcam_setpar{i});
            end
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        end
        
    case 'roi setup'        % create/remove ROI
        set(h_fig, 'WindowButtonMotionFcn', '');
        [x1, y1, x2, y2, roi_flag] = guirbsel(h_fig, fig_handle.h_axes(1));
        if (roi_flag)
            image_par.roi_coord = round([x1, y1, x2, y2]);
        else
            image_par.roi_coord = [1 1 image_par.image_size];
        end
%         ans_cell = inputdlg('Enter ROI coords', 'ROI setup', 1, {num2str(image_par.roi_coord)});
%         if (isempty(ans_cell))
%             return
%         else
%             image_par.roi_coord = str2num(ans_cell{1});
%         end
        image_par.roi_full = create_roi_struct(image_par.roi_coord, image_par.bin_full);
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        set(h_fig, 'WindowButtonMotionFcn', motion_fcn);

    case 'open file'        % save images to TIF file
        % generate file name
        % filename example:  scm07feb03a.tif
        file_date = lower([datestr(datenum(date),'dd') datestr(datenum(date),'mmmyy')]);
        for file_char = double('a') : double('z')
            file_name = [file_par.file_prefix file_date char(file_char) '.tif'];
            if (~exist(fullfile(file_par.file_path, file_name), 'file'))
                break
            end
        end

        % have user select file name
        old_dir = pwd;
        if (exist(file_par.file_path, 'dir'))
            cd(file_par.file_path);
            [file_name, file_path] = uiputfile(file_name, 'Save Images to File');
            cd(old_dir);
        else
            [file_name, file_path] = uiputfile(file_name, 'Save Images to File');
            warning('MATLAB:fluoseq', '%s not found, saving file to %s',  file_par.file_path, old_dir)
        end
        if ((file_name(1) ~= 0) && (file_path(1) ~= 0))
            % reset clock and filename display
            % reset pixel intensity graph
            % enable appropriate buttons
            file_par.file_name = file_name;
            file_par.file_path = file_path;
            set(h_fig, 'Name', file_par.file_name);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            enable_buttons(fig_handle.h_button, file_par, image_par);
            fluoseq(h_fig, 'reset graph');
        end

    case 'close file'       % stop saving images to TIF file
        file_par.file_name = '';
        enable_buttons(fig_handle.h_button, file_par, image_par);
        set(h_fig, 'Name', 'No file open');
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

    case 'colormap'         % select a new colormap
        palette_list = {'autumn', 'bone', 'cool', 'copper', ...
            'gray', 'hot', 'hsv', 'invgray', ...
            'invhsv', 'jet', 'jetshift', 'lucifer', ...
            'pink', 'spectrum', 'spring', 'summer', 'winter'};
        [new_value, select_flag] = guilist('Palette', palette_list, func2str(image_par.color_map));
        if (select_flag)
            image_par.color_map = str2func(new_value);
            disp_colorbar(h_fig, fig_handle.h_axes(2), image_par.color_map);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        end

    case 'finish'           % close figure window, camera and filter wheel
        if (isempty(image_par.h_cam))
            pvcamclose(0);
        else
            pvcamclose(image_par.h_cam);
        end
        lambdactrl(lambda_par.port, 'clear');
        if (isa(image_par.h_lambda, 'timer'))
            stop(image_par.h_lambda);
            delete(image_par.h_lambda);
        end
        if (isa(image_par.h_fluoseq, 'timer'))
            stop(image_par.h_fluoseq);
            delete(image_par.h_fluoseq);
        end
        delete(h_fig);

    otherwise               % invalid command
        warning('MATLAB:fluoseq', 'command ''%s'' not recognized', control_command);
end
return



function [image_data, new_file] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, focus_flag)

% initialize outputs
new_file = file_par;

% acquire image if device available
% otherwise generate random image
% wait for exposure time to pass in DEMO mode
% prevents Lambda 10-2 confusion during byte read from serial port
new_file.acq_time = clock;
if (isempty(image_par.h_cam))
    roi_size = diff(reshape(image_par.roi_coord, 2, 2), 1, 2)' + 1;
    image_data = uint16((2 ^ image_par.bit_depth - 1) * rand(1, prod(floor(roi_size ./ image_par.bin_full))));
    start_time = clock;
    while (1000 * etime(clock, start_time) < (image_par.expose_time + 100))
    end
else
    image_data = pvcamacq(image_par.h_cam, 1, image_par.roi_full, image_par.expose_time, 'timed');
end

% close shutter if Lambda 10-2 present
if (strcmp(image_par.filter_name, 'lambda 10-2') && ~strcmp(focus_flag, 'focus'))
    set(h_fig, 'Tag', 'close');
    lambdactrl(lambda_par.port, 'close');
end

% convert image stream into 2-D array
if (~isempty(image_data) && isnumeric(image_data))
    image_data = roiparse(image_data, image_par.roi_full);
    disp_single_image(image_data, fig_handle, image_par, new_file);

    % save image data if file is open
    if (~isempty(new_file.file_name) && ~strcmp(focus_flag, 'focus'))
        new_file.image_count = new_file.image_count + 1;
        imwrite(image_data, fullfile(new_file.file_path, new_file.file_name), ...
            'tif', 'WriteMode', 'append', 'Description', datestr(new_file.acq_time));
    end
end
return



function [] = disp_single_image(image_data, fig_handle, image_par, file_par)

% obtain image axes and text
h_axes = fig_handle.h_axes(1);
if (istype(h_axes, 'axes'))
    axes(h_axes);
    h_image = get(h_axes, 'UserData');
else
    warning('MATLAB:fluoseq', 'unable to find image axes');
    return
end
h_text = fig_handle.h_text;
if (~istype(h_text, 'uicontrol'))
    warning('MATLAB:fluoseq', 'unable to find text label');
    return
end

% display image
% shift image down to 8 bits before display
if (isa(image_data, 'uint8'))
    image_disp = image_data;
else
    image_disp = uint8(image_data / feval(class(image_data), max(1, 2 ^ (image_par.bit_depth - 8))));
end
if (istype(h_image, 'image'))
    set(h_image, 'CData', image_disp, 'UserData', image_data);
    set(h_axes, 'XLim', [1 size(image_disp, 2)], 'YLim', [1 size(image_disp, 1)]);
else
    h_image = image(image_disp);
    set(h_image, 'EraseMode', 'none', 'UserData', image_data);
    set(h_axes, 'XDir', 'reverse', ...
        'XTick', [], ...
        'YDir', 'normal', ...
        'YTick', [], ...
        'Tag', 'image', ...
        'UserData', h_image);
end

% update text label with times, counts, etc.
elapsed_time = datestr(datenum(file_par.acq_time) - datenum(file_par.start_time), 13);
text_string = sprintf('Image: %d    Elapsed Time: %s    Min: %d    Max: %d    Size: %d x %d', ...
    file_par.image_count, elapsed_time, double(min(min(image_data))), double(max(max(image_data))), ...
    floor(image_par.image_size ./ image_par.bin_full));
set(h_text, 'String', text_string);
drawnow;
return



function [] = disp_colorbar(h_fig, h_axes, color_func)

% obtain colorbar axes
if (istype(h_axes, 'axes'))
    axes(h_axes);
    h_image = get(h_axes, 'UserData');
else
    warning('MATLAB:fluoseq', 'unable to find colorbar axes');
    return
end

% obtain colormap
color_map = feval(color_func, 256);
set(h_fig, 'Colormap', color_map);
display_map = uint8(255 * reshape(color_map, [size(color_map, 1) 1 size(color_map, 2)]));

% display colorbar
if (istype(h_image, 'image'))
    set(h_image, 'CData', display_map);
else
    h_image = image(display_map);
    set(h_image, 'EraseMode', 'none', ...
        'ButtonDownFcn', 'fluoseq(gcf, ''colormap'')');
    set(h_axes, 'XDir', 'normal', ...
        'XTick', [], ...
        'YDir', 'normal', ...
        'YTick', [], ...
        'Tag', 'colorbar', ...
        'UserData', h_image);
end
return



function [] = enable_buttons(h_button, file_par, image_par)

% enable all buttons except stop
set(h_button, 'Enable', 'on');
set(h_button(4), 'Enable', 'off');

% camera setup button
if (isscalar(image_par.h_cam))
    set(h_button(10), 'Enable', 'on');
else
    set(h_button(10), 'Enable', 'off');
end

% open/close file button
if (isempty(file_par.file_name))
    set(h_button(12), 'Enable', 'on');
    set(h_button(13), 'Enable', 'off');
else
    set(h_button(12), 'Enable', 'off');
    set(h_button(13), 'Enable', 'on');
end
return



function roi_struct = create_roi_struct(roi_coord, image_bin)

% create valid ROI
% round pixels to provide exact binning
field_name = {'s1', 's2', 'sbin', 'p1', 'p2', 'pbin'};
field_value = {roi_coord(1) - 1, roi_coord(3) - mod(diff(roi_coord([1 3])) + 1, image_bin(1)) - 1, image_bin(1), ...
    roi_coord(2) - 1, roi_coord(4) - mod(diff(roi_coord([2 4])) + 1, image_bin(2)) - 1, image_bin(2)};
roi_struct = cell2struct(field_value, field_name, 2);
return



function h_fig = make_image_win(figure_tag)

% default parameters
figure_bkgnd = [0.8 0.8 0.8];       % figure window background colorspec
figure_pos = [0.10 0.10 0.80 0.80]; % figure window position (% of screen)
text_pos = [0.17 0.95 0.73 0.03];   % text label position (% of figure)
button_pos = [0.02 0.23 0.13 0.72]; % button panel position (% of figure)
image_pos = [0.17 0.23 0.73 0.72];  % image display position (% of figure)
color_pos = [0.92 0.23 0.06 0.72];  % colorbar display position (% of figure)
graph_pos = [0.08 0.05 0.90 0.15];  % graph display position (% of figure)

% create figure window
h_fig = figure('Color', figure_bkgnd, ...
    'Units', 'normalized', ...
    'Position', figure_pos, ...
    'BackingStore', 'off', ...
    'CloseRequestFcn', 'fluoseq(gcf, ''finish'')', ...
    'MenuBar', 'none', ...
    'Name', 'No file open', ...
    'NumberTitle', 'off', ...
    'Pointer', 'arrow', ...
    'UserData', [], ...
    'Tag', figure_tag);

% create text label
h_text = uicontrol('Parent', h_fig, ...
    'Units', 'normalized', ...
    'Position', text_pos, ...
    'BackgroundColor', figure_bkgnd, ...
    'ForegroundColor', [0.0 0.0 0.0], ...
    'FontName', 'Helvetica', ...
    'FontSize', 8, ...
    'String', '', ...
    'Style', 'text', ...
    'Tag', 'imagetext');

% create button panel
labels = {'Snap Image', 'Start Sequence', 'Start Focus', 'Stop Focus', 'Select Region', 'Show Region', ...
    'Clear Region', 'Reset Graph', 'Parameters', 'Camera Setup', 'ROI Setup', 'Open File', 'Close File'};
h_button = guipanel(h_fig, button_pos, 'vertical', ...
    'Enable', 'off', ...
    'FontName', 'Helvetica', ...
    'FontSize', 8, ...
    'Style', 'pushbutton', ...
    'Callback', 'fluoseq(gcf, get(gcbo, ''Tag''))', ...
    'String', labels, ...
    'Tag', labels);
set(h_button(4), 'Callback', 'set(gcf, ''Tag'', ''stop'')');

% create image axes
h_axes(1) = axes('Parent', h_fig, ...
    'Units', 'normalized', ...
    'Position', image_pos, ...
    'Box', 'on', ...
    'XDir', 'reverse', ...
    'XTick', [], ...
    'YDir', 'normal', ...
    'YTick', [], ...
    'Tag', 'image');

% create colorbar axes
h_axes(2) = axes('Parent', h_fig, ...
    'Units', 'normalized', ...
    'Position', color_pos, ...
    'Box', 'on', ...
    'XDir', 'normal', ...
    'XTick', [], ...
    'YDir', 'normal', ...
    'YTick', [], ...
    'Tag', 'colorbar');

% create graph axes
h_axes(3) = axes('Parent', h_fig, ...
    'Units', 'normalized', ...
    'Position', graph_pos, ...
    'Box', 'on', ...
    'FontName', 'helvetica', ...
    'FontSize', 8, ...
    'Tag', 'graph');

% save handles to figure UserData structure
fig_handle = cell2struct({h_axes, h_text, h_button}, {'h_axes', 'h_text', 'h_button'}, 2);
set(h_fig, 'UserData', fig_handle);
return
