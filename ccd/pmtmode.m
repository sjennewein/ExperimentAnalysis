function [] = pmtmode(varargin)

% PMTMODE - perform high-speed non-ratiometric imaging
%
%    PMTMODE acquires a sequence of non-ratiometric images from a single
%    binned pixel.  A GUI interface is provided to control the acquisition.
%
%    If no PVCAM device is found, the program will operate in a demo mode
%    where images will be generated randomly.

% 10/29/03 SCM

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
    warning('MATLAB:pmtmode', 'type ''help pmtmode'' for syntax');
    return
elseif (isa(varargin{1}, 'serial') && isvalid(varargin{1}) && ...
        isfield(varargin{2}, 'Type') && isfield(varargin{2}, 'Data'))
    % Lambda 10-2 callback
    lambda_port = varargin{1};
    lambda_event = varargin{2};
    %lambda_struct = get(lambda_port, 'UserData');
    h_fig = gcf;
    control_command = 'lambda callback';
elseif (~istype(varargin{1}, 'figure'))
    warning('MATLAB:pmtmode', 'H_FIG must be a valid figure window');
    return
elseif (~ischar(varargin{2}) || isempty(varargin{2}))
    warning('MATLAB:pmtmode', 'CMD must be a string');
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
        warning('MATLAB:pmtmode', 'cannot find valid UserData cell array in H_FIG');
        return
    end
end

% figure window parameters
% used by Lambda 10-2 interface
motion_fcn = 'pmtmode(gcbo, ''pointer value'')';
figure_tag = 'pmtmode';

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
        lambda_par = cell2struct({1, [1 0], [5 2], 5, 'lambda 10-2', @pmtmode, []}, ...
            {'wheel', 'filter', 'speed', 'wait', 'name', 'fcn', 'port'}, 2);

        % initialize camera
        % operate in demo mode & use camera defaults if error
        h_cam = pvcamopen(0);
        if (isempty(h_cam))
            disp('PMTMODE: could not open camera, using DEMO mode');
            pvcamclose(0);
            pvcam_get = cell2struct(pvcam_getvalue, pvcam_getpar, 2);
            pvcam_set = cell2struct(pvcam_setvalue, pvcam_setpar, 2);
        else
            % read camera parameters
            disp('PMTMODE: camera detected');
            for i = 1 : length(pvcam_getpar)
                pvcam_get.(pvcam_getpar{i}) = pvcamgetvalue(h_cam, pvcam_getpar{i});
            end

            % set camera parameters
            for i = 1 : length(pvcam_setpar)
                if (pvcamsetvalue(h_cam, pvcam_setpar{i}, pvcam_setvalue{i}))
                    pvcam_set.(pvcam_setpar{i}) = pvcamgetvalue(h_cam, pvcam_setpar{i});
                else
                    warning('MATLAB:pmtmode', 'could not set %s, using current value', pvcam_setpar{i});
                    pvcam_set.(pvcam_setpar{i}) = pvcamgetvalue(h_cam, pvcam_setpar{i});
                end
            end
        end

        % create image parameters structure
        % create default ROI from camera parameters w/o binning
        image_size = [pvcam_get.PARAM_SER_SIZE pvcam_get.PARAM_PAR_SIZE];
        roi_coord = [1 1 image_size];
        field_name = {'h_cam', 'h_lambda', 'h_pmtseq', 'filter_name', ...
            'roi_full', 'roi_coord', 'roi_pmt', 'offset_pmt', 'image_size', 'bit_depth', ...
            'expose_full', 'total_full', 'bin_full', 'expose_pmt', 'total_pmt', ...
            'bin_pmt', 'pixel_pmt', 'total_seq', 'time_seq', 'color_map'};
        field_value = {h_cam, [], [], 'none', ...
            [], roi_coord, [], [], image_size, pvcam_get.PARAM_BIT_DEPTH, ...
            10, 1, [1 1], 1, 85, ...
            [4 4], [20 1], 1, 5, @jet};
        image_par = cell2struct(field_value, field_name, 2);
        image_par = create_roi_struct(image_par);

        % create file parameters structure
        field_name = {'file_path', 'name_full', 'name_pmt', 'file_prefix', ...
            'count_full', 'count_pmt', 'count_seq', 'count_acq', 'start_time', 'acq_time', 'version'};
        field_value = {'c:\scm\cells', '', '', 'scm', 0, 0, 0, 0, clock, clock, getversion};
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
        %focus_par = pvcamfocus(fig_handle.h_axes(1), 'initialize', h_cam, image_par.expose_full, image_par.roi_full);
        focus_par = [];
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        pmtmode(h_fig, 'lambda detect');

    case 'pointer value'        % obtain value under mouse pointer
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_data = get(h_image, 'UserData');
            [ptr_pos, ptr_flag] = ptrpos(h_fig, fig_handle.h_axes(1), 'image');
            if ((ptr_pos(1) >= 1) && (ptr_pos(1) <= size(image_data, 2)) && ...
                    (ptr_pos(2) >= 1) && (ptr_pos(2) <= size(image_data, 1)) && ptr_flag)
                ptr_val = double(image_data(ptr_pos(2), ptr_pos(1)));
                elapsed_time = datestr(datenum(file_par.acq_time) - datenum(file_par.start_time), 13);
                ptr_text = sprintf('Image: %d    Elapsed Time: %s    Intensity at (%d, %d) = %g', file_par.count_full, ...
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
            'StartFcn', 'pmtmode(gcf, ''lambda setup'')', ...
            'TimerFcn', 'pmtmode(gcf, ''no lambda 10-2'')', ...
            'StopFcn', '', ...
            'ErrorFcn', 'pmtmode(gcf, ''no lambda 10-2'')');
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
            disp('PMTMODE: Lambda 10-2 detected');
        elseif (~isempty(err_msg))
            warning('MATLAB:pmtmode', 'Lambda 10-2 error: %s', err_msg);
            set(h_fig, 'Tag', figure_tag);
            enable_buttons(fig_handle.h_button, file_par, image_par);
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        elseif (~strcmp(get(h_fig, 'Tag'), figure_tag))
            pmtmode(h_fig, 'acquire image');
        end

    case 'no lambda 10-2'       % configure the program to run w/o Lambda 10-2
        stop(image_par.h_lambda);
        set(h_fig, 'Tag', figure_tag);
        disp(sprintf('PMTMODE: Lambda 10-2 not found after %d sec', round(lambda_par.wait)));
        yes_no = questdlg('Reset the Lambda 10-2 and try again?', 'Lambda 10-2 not found', 'yes', 'no', 'no');
        if (strcmp(yes_no, 'yes'))
            pmtmode(h_fig, 'lambda detect');
        else
            enable_buttons(fig_handle.h_button, file_par, image_par);
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        end

    case 'pmt sequence'     % timed sequences like electrophysiologic acquisition
        % setup timer if needed
        file_par.count_seq = 0;
        file_par.count_acq = file_par.count_acq + 1;
        if ((image_par.total_seq > 1) && (image_par.time_seq > 0))
            set(fig_handle.h_button(5), 'Callback', 'pmtmode(gcf, ''stop sequence'')', 'String', 'Stop Sequence');
            if (~isa(image_par.h_pmtseq, 'timer'))
                image_par.h_pmtseq = timer(...
                    'ExecutionMode', 'fixedrate', ...
                    'BusyMode', 'drop');
            end
            set(image_par.h_pmtseq, ...
                'TasksToExecute', image_par.total_seq, ...
                'StartDelay', 0, ...
                'Period', image_par.time_seq, ...
                'StartFcn', '', ...
                'TimerFcn', 'pmtmode(gcf, ''start sequence'')', ...
                'StopFcn', 'pmtmode(gcf, ''stop sequence'')', ...
                'ErrorFcn', '');
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            start(image_par.h_pmtseq);
        else
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            pmtmode(h_fig, 'start sequence');
        end

    case 'stop sequence'    % end or interrupt timed sequences
        if (isa(image_par.h_pmtseq, 'timer'))
            set(image_par.h_pmtseq, 'StopFcn', '');
            stop(image_par.h_pmtseq);
        end
         
        % gather & delete temporary files after stop
        if (~isempty(file_par.name_pmt))
            pmtmode(h_fig, 'gather files');
        end
        
        % reset controls
        set(fig_handle.h_button(5), 'Callback', 'set(gcf, ''Tag'', ''stop'')', 'String', 'Stop Focus');
        enable_buttons(fig_handle.h_button, file_par, image_par);
       
    case 'gather files'     % gather & delete temporary files
        pmt_file = fullfile(file_par.file_path, file_par.name_pmt);
        tmp_file = strrep(pmt_file, '.mat', '_pmt*.mat');
        dir_list = dir(tmp_file);
        var_name = sprintf('img%04d_acq%04d', file_par.count_full, file_par.count_acq);
        save_struct = [];
        for i = 1 : length(dir_list)
            v = load(fullfile(file_par.file_path, dir_list(i).name));
            v_list = fieldnames(v);
            for j = 1 : length(v_list)
                save_struct.(v_list{j}) = v.(v_list{j});
            end
        end
        eval(sprintf('%s = save_struct;', var_name), '');
        if (exist(pmt_file, 'file'))
            if (file_par.version < 7)
                save(pmt_file, var_name, '-append');
            else
                save(pmt_file, var_name, '-append', '-v6');
            end
        else
            if (file_par.version < 7)
                save(pmt_file, var_name);
            else
                save(pmt_file, var_name, '-v6');
            end
        end
        delete(tmp_file);

    case {'snap image', 'image sequence', 'start focus', 'start sequence'}  % initiate image acquisition
        % disable buttons and open shutter
        % this will execute lambda 10-2 command callback upon completion
        % remainder of image acquisition will be completed during callback
        set(fig_handle.h_button, 'Enable', 'off');
        set(fig_handle.h_button(5), 'Enable', 'on');
        set(h_fig, 'WindowButtonMotionFcn', '');
        set(h_fig, 'Tag', control_command);

        % initiate acquisition directly or via Lambda 10-2 callback
        if (strcmp(image_par.filter_name, lambda_par.name))
            lambdactrl(lambda_par.port, 'open');
        else
            pmtmode(h_fig, 'acquire image');
        end

    case 'acquire image'        % callback following lambda 10-2 command echo
        % perform single or repetitive acquisition if specified
        image_cmd = get(h_fig, 'Tag');
        switch (image_cmd)

            case 'snap image'       % acquire single image
                total_full = image_par.total_full;
                image_par.total_full = 1;
                [image_data, file_par] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, 'normal');
                image_par.total_full = total_full;
                set(h_fig, 'Tag', figure_tag);
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
                set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
                enable_buttons(fig_handle.h_button, file_par, image_par);

            case 'image sequence'   % acquire image sequence
                [image_data, file_par] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, 'normal');
                set(h_fig, 'Tag', figure_tag);
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
                set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
                enable_buttons(fig_handle.h_button, file_par, image_par);

            case 'start focus'      % continuously acquire until stop is detected
                % call PVCAMFOCUS to obtain images
                % reset image parameters following focus
                %focus_par = pvcamfocus(h_fig, 'set mark', focus_par, image_par.roi_pmt);
                %focus_par = pvcamfocus(h_fig, 'start focus', focus_par);
                %if (istype(focus_par{1}.h_image, 'image'))
                %    set(fig_handle.h_axes(1), 'UserData', focus_par{1}.h_image);
                %    set(focus_par{1}.h_image, 'ButtonDownFcn', 'pmtmode(gcf, ''select pixel'')');
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

            case 'start sequence'     % acquire PMT mode (high rate) sequence
                [image_data, file_par] = get_pmt_seq(h_fig, image_par, file_par, lambda_par);
                set(h_fig, 'Tag', figure_tag);
                set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
                set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
                if ((image_par.total_seq > 1) && (image_par.time_seq > 0))
                else
                    enable_buttons(fig_handle.h_button, file_par, image_par);
                    if (~isempty(file_par.name_pmt))
                        pmtmode(h_fig, 'gather files');
                    end
                end

                % update graph of PMT data
                if (~isempty(image_data) && isnumeric(image_data))
                    pmtmode(h_fig, 'reset graph');
                    axes(fig_handle.h_axes(3));
                    % skip display of underexposed 1st sample
                    % account for 3-D image data for 2-D PMT pixels
                    if (ndims(image_data) == 2)
                        h_line = line(2 : size(image_data, 2), image_data(:, 2 : end));
                        set(fig_handle.h_axes(3), 'FontName', 'helvetica', 'FontSize', 8, 'Tag', 'graph', 'UserData', h_line);
                    end
                end
        end

    case 'select pixel'         % select pixel for PMT mode
        curr_pt = get(fig_handle.h_axes(1), 'CurrentPoint');
        if (axesflag(fig_handle.h_axes(1), curr_pt(1, 1), curr_pt(1, 2)) && strcmp(get(h_fig, 'SelectionType'), 'normal'))
            image_par.offset_pmt = round(curr_pt(1, 1 : 2));
            image_par = create_roi_struct(image_par);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            pmtmode(h_fig, 'draw pixel');
        end

    case 'draw pixel'           % draw zone on image
        axes(fig_handle.h_axes(1));
        h_image = get(fig_handle.h_axes(1), 'UserData');
        if (istype(h_image, 'image'))
            image_data = get(h_image, 'UserData');
            disp_single_image(image_data, fig_handle, image_par, file_par);
        end
        enable_buttons(fig_handle.h_button, file_par, image_par);

    case 'clear pixel'          % clear selected pixel
        if (~isempty(image_par.roi_pmt) || ~isempty(image_par.offset_pmt))
            [image_par.roi_pmt, image_par.offset_pmt] = deal([]);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

            % clear zone from image
            axes(fig_handle.h_axes(1));
            h_image = get(fig_handle.h_axes(1), 'UserData');
            if (istype(h_image, 'image'))
                disp_single_image(get(h_image, 'UserData'), fig_handle, image_par, file_par);
            end
            enable_buttons(fig_handle.h_button, file_par, image_par);
        end

    case 'draw line'            % acquire image from line of pixels
        % FUTURE IMPLEMENTATION
        % TEMPORARILY IMPLEMENTED WITH PIXEL_PMT PARAM

    case 'parameters'       % define sequence parameters
        % setup editing of acquisition parameters for GUISTRUCT
        field_name = {'file_path', 'file_prefix', 'expose_full', 'total_full', 'bin_full', ...
            'expose_pmt', 'total_pmt', 'bin_pmt', 'pixel_pmt', 'total_seq', 'time_seq'};
        field_lower = [-Inf -Inf 0 1 1 0 1 1 1 1 1];
        field_upper = Inf * ones(size(field_lower));
        field_title = {'File path', 'File prefix', 'Full exp (ms)', 'Full count', 'Full bin', ...
            'PMT exp (ms)', 'PMT count', 'PMT bin', 'PMT pixels', 'Seq count', 'Seq time (s)'};
        field_format = {'%s', '%s', '%d', '%d', '%d', ...
            '%d', '%d', '%d', '%d', '%d', '%d'};
        field_multi = {'string', 'string', 'scalar', 'scalar', 'vector', ...
            'scalar', 'scalar', 'vector', 'vector', 'scalar', 'scalar'};

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

            % recalculate PMT ROI in case binning has changed
            % recalculate focus parameters
            image_par = create_roi_struct(image_par);
            %focus_par = pvcamfocus(fig_handle.h_axes(1), 'initialize', ...
            %    image_par.h_cam, image_par.expose_full, image_par.roi_full);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            if (~isempty(image_par.offset_pmt))
                pmtmode(h_fig, 'draw pixel');
            end
            enable_buttons(fig_handle.h_button, file_par, image_par);
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
        image_par = create_roi_struct(image_par);
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
        set(h_fig, 'WindowButtonMotionFcn', motion_fcn);

    case 'open file'        % save images to TIF & MAT files
        % generate file name
        % full image example:  scm07feb03a.tif
        % PMT series example:  scm07feb03a.mat
        file_date = lower([datestr(datenum(date),'dd') datestr(datenum(date),'mmmyy')]);
        for file_char = double('a') : double('z')
            name_full = [file_par.file_prefix file_date char(file_char) '.tif'];
            name_pmt = [file_par.file_prefix file_date char(file_char) '.mat'];
            if (~exist(fullfile(file_par.file_path, name_full), 'file') && ...
                    ~exist(fullfile(file_par.file_path, name_pmt), 'file'))
                break
            end
        end

        % have user select file name
        old_dir = pwd;
        if (exist(file_par.file_path, 'dir'))
            cd(file_par.file_path);
            [name_full, file_path] = uiputfile(name_full, 'Save Images to File');
            cd(old_dir);
        else
            [name_full, file_path] = uiputfile(name_full, 'Save Images to File');
            warning('MATLAB:pmtmode', '%s not found, saving file to %s',  file_par.file_path, old_dir)
        end
        if ((name_full(1) ~= 0) && (file_path(1) ~= 0))
            % reset clock and filename display
            % reset pixel intensity graph
            % enable appropriate buttons
            file_par.name_full = lower(name_full);
            file_par.file_path = file_path;
            % INSERT FUTURE CHECK FOR .TIF EXT BEFORE STRREP!!!
            file_par.name_pmt = strrep(lower(name_full), '.tif', '.mat');
            file_par.count_full = 0;
            file_par.count_pmt = 0;
            file_par.count_acq = 0;
            file_par.start_time = clock;
            set(h_fig, 'Name', file_par.name_full);
            set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});
            enable_buttons(fig_handle.h_button, file_par, image_par);
            pmtmode(h_fig, 'reset graph');
        end

    case 'close file'       % stop saving images to TIF file
        file_par.name_full = '';
        file_par.name_pmt = '';
        enable_buttons(fig_handle.h_button, file_par, image_par);
        set(h_fig, 'Name', 'No file open');
        set(h_fig, 'UserData', {fig_handle, image_par, file_par, pvcam_get, pvcam_set, lambda_par, focus_par});

    case 'reset graph'      % reset time and graph display
        delete(get(fig_handle.h_axes(3), 'Children'));

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
        if (isa(image_par.h_pmtseq, 'timer'))
            stop(image_par.h_pmtseq);
            delete(image_par.h_pmtseq);
        end
        delete(h_fig);

    otherwise               % invalid command
        warning('MATLAB:pmtmode', 'command ''%s'' not recognized', control_command);
end
return



function [image_data, new_file] = get_pmt_seq(h_fig, image_par, file_par, lambda_par)

% initialize outputs
new_file = file_par;

% acquire image if device available
% otherwise generate random image
% wait for exposure time to pass in DEMO mode
% prevents Lambda 10-2 confusion during byte read from serial port
new_file.acq_time = clock;
if (isempty(image_par.h_cam))
    image_data = uint16((2 ^ image_par.bit_depth - 1) * rand(1, prod(image_par.pixel_pmt) * image_par.total_pmt));
    start_time = clock;
    while (1000 * etime(clock, start_time) < (image_par.expose_pmt * image_par.total_pmt))
    end
else
    %icl_script = create_icl_script(image_par, pvcam_get, pvcam_set);
    %[image_data, disp_info] = pvcamicl(image_par.h_cam, [icl_script{:}]);
    image_data = pvcamacq(image_par.h_cam, ...
        image_par.total_pmt, image_par.roi_pmt, image_par.expose_pmt, 'timed');
end

% close shutter if Lambda 10-2 present
if (strcmp(image_par.filter_name, 'lambda 10-2'))
    set(h_fig, 'Tag', 'close');
    lambdactrl(lambda_par.port, 'close');
end

% convert image stream into 2-D array
% NOTE CAN HANDLE MULTIPLE PIXEL ROIS WITH RESHAPE?
if (~isempty(image_data) && isnumeric(image_data))
    %image_data = roiparse(image_data, image_par.roi_full);
    if (all(image_par.pixel_pmt == 1))
        image_data = reshape(image_data, 1, numel(image_data));
    elseif (any(image_par.pixel_pmt == 1))
        image_data = reshape(image_data, prod(image_par.pixel_pmt), numel(image_data) / prod(image_par.pixel_pmt));
    else
        image_data = reshape(image_data, [image_par.pixel_pmt (numel(image_data) / prod(image_par.pixel_pmt))]);
    end
    new_file.count_pmt = new_file.count_pmt + 1;
    new_file.count_seq = new_file.count_seq + 1;

    % save image data if file is open
    % use temporary files then gather after stop
    if (~isempty(new_file.name_pmt))
        pmt_file = fullfile(new_file.file_path, new_file.name_pmt);
        tmp_file = strrep(pmt_file, '.mat', sprintf('_pmt%04d.mat', new_file.count_pmt));
        save_struct = cell2struct({new_file, image_par, image_data}, {'file_par', 'image_par', 'image_data'}, 2);
        var_name = sprintf('pmt%04d', new_file.count_pmt);
        eval(sprintf('%s = save_struct;', var_name), '');
        if (exist(tmp_file, 'file'))
            if (file_par.version < 7)
                save(tmp_file, var_name, '-append');
            else
                save(tmp_file, var_name, '-append', '-v6');
            end
        else
            if (file_par.version < 7)
                save(tmp_file, var_name);
            else
                save(tmp_file, var_name, '-v6');
            end
        end
    end
end
return



function [image_data, new_file] = get_single_image(h_fig, fig_handle, image_par, file_par, lambda_par, focus_flag)

% initialize outputs
new_file = file_par;
if (strcmp(focus_flag, 'focus'))
    image_par.total_full = 1;
end

% acquire image if device available
% otherwise generate random image
% wait for exposure time to pass in DEMO mode
% prevents Lambda 10-2 confusion during byte read from serial port
new_file.acq_time = clock;
if (isempty(image_par.h_cam))
    roi_size = diff(reshape(image_par.roi_coord, 2, 2), 1, 2)' + 1;
    image_data = uint16((2 ^ image_par.bit_depth - 1) * rand(1, prod(floor(roi_size ./ image_par.bin_full)), image_par.total_full));
    start_time = clock;
    while (1000 * etime(clock, start_time) < (image_par.expose_full + 100) * image_par.total_full)
    end
else
    image_data = pvcamacq(image_par.h_cam, ...
        image_par.total_full, image_par.roi_full, image_par.expose_full, 'timed');
end

% close shutter if Lambda 10-2 present
if (strcmp(image_par.filter_name, 'lambda 10-2') && ~strcmp(focus_flag, 'focus'))
    set(h_fig, 'Tag', 'close');
    lambdactrl(lambda_par.port, 'close');
end

% convert image stream into 2-D array
if (~isempty(image_data) && isnumeric(image_data))
    image_data = roiparse(image_data, image_par.roi_full);
    for i = 1 : size(image_data, 3)
        disp_single_image(image_data(:, :, i), fig_handle, image_par, new_file);

        % save image data if file is open
        if (~isempty(new_file.name_full) && ~strcmp(focus_flag, 'focus'))
            new_file.count_full = new_file.count_full + 1;
            imwrite(image_data(:, :, i), fullfile(new_file.file_path, new_file.name_full), ...
                'tif', 'WriteMode', 'append', 'Description', datestr(new_file.acq_time));
        end
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
    warning('MATLAB:disp_single_image', 'unable to find image axes');
    return
end
h_text = fig_handle.h_text;
if (~istype(h_text(1), 'uicontrol'))
    warning('MATLAB:disp_single_image', 'unable to find text label');
    return
end

% display image
% shift image down to 8 bits before display
if (isa(image_data, 'uint8'))
    image_disp = image_data;
else
    image_disp = uint8(image_data / feval(class(image_data), max(1, 2 ^ (image_par.bit_depth - 8))));
end

% create image mask if needed
% adjust mask if ROI selected
if (~isempty(image_par.roi_pmt))
    image_mask = feval(class(image_disp), ones(size(image_disp)));
    x(1) = min(max(image_par.roi_pmt.s1 - image_par.roi_coord(1) + 2, 1), size(image_disp, 2));
    x(2) = min(max(image_par.roi_pmt.s2 - image_par.roi_coord(1) + 2, 1), size(image_disp, 2));
    y(1) = min(max(image_par.roi_pmt.p1 - image_par.roi_coord(2) + 2, 1), size(image_disp, 1));
    y(2) = min(max(image_par.roi_pmt.p2 - image_par.roi_coord(2) + 2, 1), size(image_disp, 1));
    image_mask(y(1) : y(2), x(1) : x(2)) = feval(class(image_disp), 0);
    image_disp = image_disp .* image_mask;
end

if (istype(h_image, 'image'))
    set(h_image, 'CData', image_disp, 'UserData', image_data);
    set(h_axes, 'XLim', [1 size(image_disp, 2)], 'YLim', [1 size(image_disp, 1)]);
else
    h_image = image(image_disp);
    set(h_image, ...
        'EraseMode', 'none', ...
        'ButtonDownFcn', 'pmtmode(gcf, ''select pixel'')', ...
        'UserData', image_data);
    set(h_axes, ...
        'XDir', 'reverse', ...
        'XTick', [], ...
        'YDir', 'normal', ...
        'YTick', [], ...
        'Tag', 'image', ...
        'UserData', h_image);
end

% update text label with times, counts, etc.
elapsed_time = datestr(datenum(file_par.acq_time) - datenum(file_par.start_time), 13);
text_string = sprintf('Image: %d    Elapsed Time: %s    Min: %d    Max: %d    Size: %d x %d', file_par.count_full, ...
    elapsed_time, double(min(min(image_data))), double(max(max(image_data))), image_par.image_size);
set(h_text(1), 'String', text_string);
drawnow;
return



function [] = disp_colorbar(h_fig, h_axes, color_func)

% obtain colorbar axes
if (istype(h_axes, 'axes'))
    axes(h_axes);
    h_image = get(h_axes, 'UserData');
else
    warning('MATLAB:pmtmode', 'unable to find colorbar axes');
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
    set(h_image, ...
        'EraseMode', 'none', ...
        'ButtonDownFcn', 'pmtmode(gcf, ''colormap'')');
    set(h_axes, 'XDir', 'normal', ...
        'XTick', [], ...
        'YDir', 'normal', ...
        'YTick', [], ...
        'Tag', 'colorbar', ...
        'UserData', h_image);
end
return



% % CREATE_ICL_SCRIPT
% function icl_script = create_icl_script(image_par, pvcam_get, pvcam_set)
% 
% % obtain ICL coordinates from ROI structure
% s_offset = [image_par.roi_pmt(:).s1];
% s_size = [image_par.roi_pmt(:).s2] - [image_par.roi_pmt(:).s1] + 1;
% s_bin = [image_par.roi_pmt(:).sbin];
% x_size = floor(s_size ./ s_bin);
% if (length(image_par.roi_pmt) > 1)
%     p_shift = [image_par.roi_pmt.p1] - [-1 image_par.roi_pmt(1 : end - 1).p2] - 1;
% else
%     p_shift = image_par.roi_pmt.p1;
% end
% p_size = [image_par.roi_pmt(:).p2] - [image_par.roi_pmt(:).p1] + 1;
% p_bin = [image_par.roi_pmt(:).pbin];
% y_size = floor(p_size ./ p_bin);
% 
% % create scripts to open & close shutter
% % clear CCD array after shutter opens & closes
% icl_script = {'script_begin( );', ...
%     'shutter_open( );', ...
%     sprintf('clear_parallel( %d );', pvcam_set.PARAM_CLEAR_CYCLES), ...
%     sprintf('clear_serial( %d );', pvcam_set.PARAM_CLEAR_CYCLES)};
% 
% % begin exposure loop
% icl_script{end + 1} = sprintf('loop_begin( %d );', image_par.total_pmt);
% if (image_par.expose_pmt > 0)
%     icl_script{end + 1} = sprintf('expose( %d );', image_par.expose_pmt);
% end
% 
% % use frame transfer to maximize exposure time during shifting and readout
% % otherwise shift pixels directly into serial register
% if (pvcam_get.PARAM_FRAME_CAPABLE)
%     icl_script{end + 1} = 'shift_image_to_storage( );';
% else
%     p_shift(1) = p_shift(1) + pvcam_get.PARAM_PREMASK - 1;
% end
% 
% % shift exposed pixels into serial register if needed
% if (p_shift(1) > 0)
%     icl_script{end + 1} = sprintf('shift( %d );', p_shift(1));
% end
% 
% % readout pixels from serial register
% % shift subsequent ROIs into serial register if present
% for i = 1 : length(image_par.roi_pmt)
%     icl_script{end + 1} = sprintf('pixel_readout( %d, %d, %d, %d, %d );', s_offset(i), s_size(i), s_bin(i), p_size(i), p_bin(i));
%     if (i < length(image_par.roi_pmt))
%         if (p_shift(i + 1) > 0)
%             icl_script{end + 1} = sprintf('shift( %d );', p_shift(i + 1));
%         end
%     end
% end
% 
% % readout pixels as a matrix with one row per exposure
% % column size equals number of pixels in all ROIs
% icl_script{end + 1} = 'loop_end( );';
% icl_script{end + 1} = sprintf('pixel_display( %d, %d );', sum(x_size .* y_size), image_par.total_pmt);
% 
% % reset shift mode if frame transfer capable
% if (pvcam_get.PARAM_FRAME_CAPABLE)
%     icl_script{end + 1} = 'shift_mode_is( );';
% end
% 
% % close shutter and terminate script
% icl_script{end + 1} = 'shutter_close( );';
% icl_script{end + 1} = sprintf('clear_parallel( %d );', pvcam_set.PARAM_CLEAR_CYCLES);
% icl_script{end + 1} = sprintf('clear_serial( %d );', pvcam_set.PARAM_CLEAR_CYCLES);
% icl_script{end + 1} = 'script_end( 0 );';
% return



function [] = enable_buttons(h_button, file_par, image_par)

% enable all buttons except stop
set(h_button, 'Enable', 'on');
set(h_button(5), 'Enable', 'off');

% image sequence button
if (image_par.total_full < 2)
    set(h_button(2), 'Enable', 'off');
else
    set(h_button(2), 'Enable', 'on');
end

% PMT sequence button
if (isempty(image_par.roi_pmt) || isempty(image_par.offset_pmt))
    set(h_button(3), 'Enable', 'off');
else
    set(h_button(3), 'Enable', 'on');
end

% camera setup button
if (isscalar(image_par.h_cam))
    set(h_button(9), 'Enable', 'on');
else
    set(h_button(9), 'Enable', 'off');
end

% open/close file button
if (isempty(file_par.name_full))
    set(h_button(12), 'Enable', 'on');
    set(h_button(13), 'Enable', 'off');
else
    set(h_button(12), 'Enable', 'off');
    set(h_button(13), 'Enable', 'on');
end
return



function new_par = create_roi_struct(old_par)
new_par = old_par;
field_name = {'s1', 's2', 'sbin', 'p1', 'p2', 'pbin'};

% initialize full field ROI
field_value = {new_par.roi_coord(1) - 1, ...
    new_par.roi_coord(3) - mod(diff(new_par.roi_coord([1 3])) + 1, new_par.bin_full(1)) - 1, ...
    new_par.bin_full(1), ...
    new_par.roi_coord(2) - 1, ...
    new_par.roi_coord(4) - mod(diff(new_par.roi_coord([2 4])) + 1, new_par.bin_full(2)) - 1, ...
    new_par.bin_full(2)};
new_par.roi_full = cell2struct(field_value, field_name, 2);

% create PMT ROI
if (isempty(new_par.offset_pmt))
    new_par.roi_pmt = [];
else
    new_par.offset_pmt = round(min([max([new_par.offset_pmt; floor(new_par.bin_pmt .* new_par.pixel_pmt / 2)]); ...
        (new_par.image_size - floor(new_par.bin_pmt .* new_par.pixel_pmt / 2) - 1)]));
    first_pixel = new_par.offset_pmt - floor(new_par.bin_pmt .* new_par.pixel_pmt / 2);
    last_pixel = new_par.offset_pmt + floor(new_par.bin_pmt .* new_par.pixel_pmt / 2) - 1;
    field_value = {first_pixel(1), last_pixel(1), new_par.bin_pmt(1), first_pixel(end), last_pixel(end), new_par.bin_pmt(end)};
    new_par.roi_pmt = cell2struct(field_value, field_name, 2);
end
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
    'CloseRequestFcn', 'pmtmode(gcf, ''finish'')', ...
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
labels = {'Snap Image', 'Image Sequence', 'PMT Sequence', 'Start Focus', 'Stop Focus', 'Clear Pixel', ...
    'Draw Line', 'Parameters', 'Camera Setup', 'ROI Setup', 'Reset Graph', 'Open File', 'Close File'};
h_button = guipanel(h_fig, button_pos, 'vertical', ...
    'Enable', 'off', ...
    'FontName', 'Helvetica', ...
    'FontSize', 8, ...
    'Style', 'pushbutton', ...
    'Callback', 'pmtmode(gcf, get(gcbo, ''Tag''))', ...
    'String', labels, ...
    'Tag', labels);
set(h_button(5), 'Callback', 'set(gcf, ''Tag'', ''stop'')');

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
