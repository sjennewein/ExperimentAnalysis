function varargout = pvcamfocus(varargin)

% PVCAMFOCUS - runs an ICL script for camera focus
%
%    PVCAMFOCUS acquires a series of images from a PVCAM camera using ICL
%    and frame transfer mode if available.  The images are displayed within
%    a new figure window that has Start and Stop buttons.
%
%    PVCAMFOCUS(HAXES, 'initialize', HCAM, EXPTIME, ROI) specifies various
%    parameters for image acquisition and display.  HAXES is the handle to
%    the image display axes.  HCAM is the handle to an open PVCAM camera to
%    use for image acquisition.  EXPTIME specifies the exposure time in ms.
%    ROI specifies the CCD region(s) from which images will be acquired.
%    The structure array ROI must have the following scalar fields:
%
%					s1 = first serial register
%					s2 = last serial register
%					sbin = serial binning factor
%					p1 = first parallel register
%					p2 = last parallel register
%					pbin = parallel binning factor
%
%	 The length of the structure array ROI determines the number of CCD
%	 regions that will be imaged.
%
%    PVCAMFOCUS(HFIG, 'set mark') sets a registration mark for display.
%
%    PVCAMFOCUS(HFIG, 'start focus') starts the image acquisition.
%
%    PVCAMFOCUS(HFIG, 'stop focus') interrupts image acquisition.
%
%    PVCAMFOCUS(HFIG, 'color map') changes the color map of the image
%    display.
%
%    PVCAMFOCUS(HFIG, 'finish') closes the camera and figure window.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Use the following with another image acquisition program:
%
%        USER_DATA = PVCAMFOCUS(HAXES, 'initialize', HCAM, EXPTIME, ROI);
%        USER_DATA = PVCAMFOCUS(HFIG, 'start_focus', USER_DATA);
%
%    The calling program must provide a valid axis handle HAXES for image
%    display and a handle to an open PVCAM device HCAM.  The default
%    exposure time EXPTIME is 0 ms and the default ROI is the full array
%    with 1 x 1 binning if not provided by the calling routine.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1/30/04 SCM

% initialize outputs
if (nargout > 0)
    varargout = cell(1, nargout);
end

% validate fixed arguments
if (nargin > 5)
    warning('MATLAB:pvcamfocus', 'type ''help pvcamfocus'' for syntax');
    return
else
    control_command = lower(chkvarargin(varargin, 2, 'char', [1 10], 'cmd', 'initialize'));
end

% call routine to initialize variable inputs on first call
% obtain parameters from figure window if callback
if (strcmp(control_command, 'initialize'))
    h_axes = chkvarargin(varargin, 1, 'double', [1 1], 'haxes', NaN);
    h_cam = chkvarargin(varargin, 3, 'double', [1 1], 'hcam', NaN);
    camera_struct.exp_time = max(floor(chkvarargin(varargin, 4, 'double', [1 1], 'exptime', 100)), 0);
    if (nargin >= 5)
        roi_struct = varargin{5};
    else
        roi_struct = [];
    end

    % figure window parameters
    motion_fcn = 'pvcamfocus(gcbo, ''pointer value'')';
    figure_tag = 'pvcamfocus';

    % default camera parameters
    pvcam_setpar = {'TEMP_SETPOINT', 'CLEAR_MODE', 'CLEAR_CYCLES', ...
        'SHTR_OPEN_MODE', 'SPDTAB_INDEX', 'GAIN_INDEX'};
    pvcam_setvalue = {-2500, 'clear pre-exposure', 2, 'do not change shutter state', 2, 3};
    pvcam_getpar = {'SER_SIZE', 'PRESCAN', 'POSTSCAN', 'PAR_SIZE', 'PREMASK', 'POSTMASK', ...
        'BIT_DEPTH', 'FRAME_CAPABLE', 'PIX_TIME', 'TEMP'};
    pvcam_getvalue = {535, 13, 6, 512, 528, 16, 12, 1, 333, -2500};

else
    h_fig = chkvarargin(varargin, 1, 'double', [1 1], 'hfig', NaN);
    if (istype(h_fig, 'figure'))
        if (nargin > 2)
            user_data = varargin{3};
            if (nargin > 3)
                roi_mark = varargin{4};
            end
        else
            user_data = get(h_fig, 'UserData');
        end
        if (iscell(user_data) && (length(user_data) >= 4))
            [figure_struct, camera_struct, pvcam_struct, icl_script] = deal(user_data{1 : 4});
        else
            warning('MATLAB:pvcamfocus', 'cannot find valid UserData cell array in H_FIG');
            return
        end
    else
        warning('MATLAB:pvcamfocus', 'HFIG must be a valid figure window');
        return
    end
end

% execute callback command
switch (control_command)

    case 'initialize'   % initialize figure window and camera
        % open camera if needed
        if (isnan(h_cam))
            camera_struct.h_cam = pvcamopen(0);
            if (isempty(camera_struct.h_cam))
                disp('PVCAMFOCUS: could not open camera, using DEMO mode');
                pvcamclose(0);
            else
                disp('PVCAMFOCUS: camera detected');
            end

            % set camera parameters
            for i = 1 : length(pvcam_setpar)
                if (isempty(camera_struct.h_cam))
                    pvcam_struct.(lower(pvcam_setpar{i})) = pvcam_setvalue{i};
                elseif (pvcamsetvalue(camera_struct.h_cam, ...
                        sprintf('PARAM_%s', upper(pvcam_setpar{i})), pvcam_setvalue{i}))
                    pvcam_struct.(lower(pvcam_setpar{i})) = pvcam_setvalue{i};
                else
                    warning('MATLAB:pvcamfocus', 'could not set PARAM_%s, use current value', pvcam_setpar{i});
                    pvcam_struct.(lower(pvcam_setpar{i})) = ...
                        pvcamgetvalue(camera_struct.h_cam, sprintf('PARAM_%s', upper(pvcam_setpar{i})));
                end
            end
        else
            % obtain camera parameters
            camera_struct.h_cam = h_cam;
            for i = 1 : length(pvcam_setpar)
                if (isempty(camera_struct.h_cam))
                    pvcam_struct.(lower(pvcam_setpar{i})) = pvcam_setvalue{i};
                else
                    pvcam_struct.(lower(pvcam_setpar{i})) = ...
                        pvcamgetvalue(camera_struct.h_cam, sprintf('PARAM_%s', upper(pvcam_setpar{i})));
                end
            end
        end

        % obtain chip geometry & other camera parameters
        % some values (PRESCAN, POSTSCAN & POSTMASK) are irrelevant
        for i = 1 : length(pvcam_getpar)
            if (isempty(camera_struct.h_cam))
                camera_struct.(lower(pvcam_getpar{i})) = pvcam_getvalue{i};
            else
                camera_struct.(lower(pvcam_getpar{i})) = ...
                    pvcamgetvalue(camera_struct.h_cam, sprintf('PARAM_%s', upper(pvcam_getpar{i})));
            end
        end

        % initialize ROI if needed
        % call ROIOVERLAP to check for valid ROI coordinates
        % create ICL scripts for shutter and focus
        camera_struct.roi_struct = roioverlap(defstruc(roi_struct, ...
            {'s1', 's2', 'sbin', 'p1', 'p2', 'pbin'}, ...
            {0, camera_struct.ser_size - 1, 1, 0, camera_struct.par_size - 1, 1}), ...
            camera_struct.ser_size, camera_struct.par_size);
        camera_struct.roi_mark = [];
        icl_script = create_icl_script(camera_struct, pvcam_struct);

        % create figure window if needed
        % obtain object handles
        if (istype(h_axes, 'axes'))
            h_fig = get(h_axes, 'Parent');
            figure_struct.h_axes = h_axes;
            figure_struct.h_image = [];
        else
            h_fig = make_image_win(figure_tag);
            figure_struct = get(h_fig, 'UserData');
            disp_colorbar(h_fig, figure_struct.h_axes(2), figure_struct.color_map);

            % setup mouse pointer motion callback
            % enable Start & disable Stop button
            set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
            set(figure_struct.h_button(1), 'Enable', 'on');
            set(figure_struct.h_button(2), 'Enable', 'off');
        end

    case 'set mark'
        if (isempty(roi_mark))
            camera_struct.roi_mark = [];
        else
            camera_struct.roi_mark = defstruc(roi_mark, {'s1', 's2', 'p1', 'p2'}, ...
                {0, camera_struct.ser_size - 1, 0, camera_struct.par_size - 1});
        end

    case 'start focus'  % start focus
        % disable Start & enable Stop button if provided
        if (isfield(figure_struct, 'h_button'))
            set(figure_struct.h_button(1), 'Enable', 'off');
            set(figure_struct.h_button(2), 'Enable', 'on');
        end

        % reset figure text if provided
        if (isfield(figure_struct, 'h_text'))
            set(figure_struct.h_text(1), 'String', 'Acquiring Images ...');
        end

        % clear Tag to stop acquisition
        % disable WindowButtonMotionFcn
        old_tag = get(h_fig, 'Tag');
        set(h_fig, 'Tag', 'start');
        motion_fcn = get(h_fig, 'WindowButtonMotionFcn');
        set(h_fig, 'WindowButtonMotionFcn', '');

        % open camera shutter & load acquisition script if not demo mode
        if (isempty(camera_struct.h_cam))
            data_struct = zeros(1, sum(sum(roimask(camera_struct.roi_struct))));
        else
            [data_struct, disp_info] = pvcamicl(camera_struct.h_cam, [icl_script.open{:}], 'full');
            if (isempty(data_struct) && ischar(disp_info))
                if (strcmp(disp_info, 'no image'))
                    %[data_struct, disp_info] = pvcamicl(camera_struct.h_cam, [icl_script.acq{:}], 'load');
                    %if (~isempty(data_struct) && isstruct(disp_info))
                    %else
                    %    set(h_fig, 'Tag', 'stop');
                    %end
                else
                    set(h_fig, 'Tag', 'stop');
                end
            else
                set(h_fig, 'Tag', 'stop');
            end
        end

        % acquire images if stop detected
        image_mask = [];
        while (~strcmp(get(h_fig, 'Tag'), 'stop'))
            if (isempty(camera_struct.h_cam))
                data_struct = uint16((2 ^ camera_struct.bit_depth - 1) * rand(size(data_struct)));
                pause(camera_struct.exp_time / 1000);
            else
                data_struct = pvcamicl(camera_struct.h_cam, data_struct, 'run');
                %data_struct = pvcamacq(camera_struct.h_cam, 1, ...
                %    camera_struct.roi_struct, camera_struct.exp_time, 'timed');
                if (isempty(data_struct))
                    break
                end
            end

            % convert image to UINT8 for display
            image_data = roiparse(data_struct, camera_struct.roi_struct);
            if (camera_struct.bit_depth > 8)
                image_disp = uint8(image_data / 2 ^ (camera_struct.bit_depth - 8));
            else
                image_disp = uint8(image_data);
            end

            % create image mask if needed
            if (isstruct(camera_struct.roi_mark))
                if (isempty(image_mask))
                    image_mask = feval(class(image_disp), ones(size(image_disp)));
                    image_mask(camera_struct.roi_mark.p1 : camera_struct.roi_mark.p2, ...
                        camera_struct.roi_mark.s1 : camera_struct.roi_mark.s2) = feval(class(image_disp), 0);
                end
                image_disp = image_disp .* image_mask;
            end

            % display acquired image
            if (istype(figure_struct.h_image, 'image'))
                set(figure_struct.h_image, 'CData', image_disp, 'UserData', image_data);
                set(figure_struct.h_axes(1), 'XLim', [1 size(image_disp, 2)], 'YLim', [1 size(image_disp, 1)]);
            else
                axes(figure_struct.h_axes(1));
                figure_struct.h_image = image(image_disp);
                set(figure_struct.h_image, 'EraseMode', 'none', 'UserData', image_data);
                set(figure_struct.h_axes(1), 'XDir', 'reverse', ...
                    'XTick', [], ...
                    'YDir', 'normal', ...
                    'YTick', []);
            end
            drawnow;
        end

        % remove acquisition script & close camera shutter if not demo mode
        if (~isempty(camera_struct.h_cam))
            if (pvcamicl(camera_struct.h_cam, [], 'uninit'))
                [data_struct, disp_info] = pvcamicl(camera_struct.h_cam, [icl_script.close{:}], 'full');
            end
        end

        % reset figure Tag
        % enable WindowButtonMotionFcn
        % enable Start & disable Stop button
        set(h_fig, 'Tag', old_tag);
        set(h_fig, 'WindowButtonMotionFcn', motion_fcn);
        if (isfield(figure_struct, 'h_button'))
            set(figure_struct.h_button(1), 'Enable', 'on');
            set(figure_struct.h_button(2), 'Enable', 'off');
        end

    case 'stop focus'  % start focus
        set(h_fig, 'Tag', 'stop');
        return

    case 'color map'     % change color map
        palette_list = {'autumn', 'bone', 'cool', 'copper', ...
            'gray', 'hot', 'hsv', 'invgray', ...
            'invhsv', 'jet', 'jetshift', 'lucifer', ...
            'pink', 'spectrum', 'spring', 'summer', 'winter'};
        [new_value, select_flag] = guilist('Palette', palette_list, func2str(figure_struct.color_map));
        if (select_flag)
            figure_struct.color_map = str2func(new_value);
            disp_colorbar(h_fig, figure_struct.h_axes(2), figure_struct.color_map);
        else
            return
        end

    case 'pointer value'    % obtain value under mouse pointer
        if (istype(figure_struct.h_image, 'image'))
            image_data = get(figure_struct.h_image, 'UserData');
            [ptr_pos, ptr_flag] = ptrpos(h_fig, figure_struct.h_axes(1), 'image');
            if ((ptr_pos(1) >= 1) && (ptr_pos(1) <= size(image_data, 2)) && ...
                    (ptr_pos(2) >= 1) && (ptr_pos(2) <= size(image_data, 1)) && ptr_flag)
                set(figure_struct.h_text(1), 'String', sprintf('Intensity at (%d, %d) = %g', ...
                    ptr_pos(1), ptr_pos(2), double(image_data(ptr_pos(2), ptr_pos(1)))));
            end
        end
        return

    case 'finish'       % close camera and figure window
        if (isempty(camera_struct.h_cam))
            pvcamclose(0);
        else
            pvcamclose(camera_struct.h_cam);
        end
        delete(h_fig);
        return

    otherwise           % invalid command
        warning('MATLAB:pvcamfocus', '%s is not a valid command', upper(control_command));
        return
end

% return cell array of parameters if output argument
% otherwise store all parameters to figure UserData field
if (nargout > 0)
    varargout{1} = {figure_struct, camera_struct, pvcam_struct, icl_script};
else
    set(h_fig, 'UserData', {figure_struct, camera_struct, pvcam_struct, icl_script});
end
return



% CREATE_ICL_SCRIPT
function icl_script = create_icl_script(camera_struct, pvcam_struct)

% obtain ICL coordinates from ROI structure
s_offset = [camera_struct.roi_struct(:).s1];
s_size = [camera_struct.roi_struct(:).s2] - [camera_struct.roi_struct(:).s1] + 1;
s_bin = [camera_struct.roi_struct(:).sbin];
x_size = floor(s_size ./ s_bin);
p_shift(1) = camera_struct.roi_struct(1).p1 + camera_struct.premask - 1;
if (length(camera_struct.roi_struct) > 1)
    p_shift(2 : length(camera_struct.roi_struct)) = ...
        [camera_struct.roi_struct(2 : end).p1] - [camera_struct.roi_struct(1 : end - 1).p2] - 1;
end
p_size = [camera_struct.roi_struct(:).p2] - [camera_struct.roi_struct(:).p1] + 1;
p_bin = [camera_struct.roi_struct(:).pbin];
y_size = floor(p_size ./ p_bin);

% create scripts to open & close shutter
% clear CCD array after shutter opens & closes
% make sure camera is in proper shift mode if frame transfer capable
icl_script.open = {'script_begin( );', ...
    'shutter_open( );', ...
    sprintf('clear_parallel( %d );', pvcam_struct.clear_cycles), ...
    sprintf('clear_serial( %d );', pvcam_struct.clear_cycles)};
if (camera_struct.frame_capable)
    icl_script.open{end + 1} = 'shift_mode_is( );';
end
icl_script.open{end + 1} = 'script_end( 0 );';

icl_script.close = {'script_begin( );', ...
    'shutter_close( );', ...
    sprintf('clear_parallel( %d );', pvcam_struct.clear_cycles), ...
    sprintf('clear_serial( %d );', pvcam_struct.clear_cycles), ...
    'script_end( 0 );'};

% initialize acquisition script
% clear array and expose for specified time
icl_script.acq = {'script_begin( );', ...
    sprintf('clear_parallel( %d );', pvcam_struct.clear_cycles), ...
    sprintf('clear_serial( %d );', pvcam_struct.clear_cycles), ...
    sprintf('expose( %d );', camera_struct.exp_time)};

% shift exposed pixels into serial register if needed
if (p_shift(1) > 0)
    icl_script.acq{end + 1} = sprintf('shift( %d );', p_shift(1));
end

% readout pixels from serial register
% shift subsequent ROIs into serial register if present
for i = 1 : length(camera_struct.roi_struct)
    icl_script.acq{end + 1} = sprintf('pixel_readout( %d, %d, %d, %d, %d );', ...
        s_offset(i), s_size(i), s_bin(i), p_size(i), p_bin(i));
    icl_script.acq{end + 1} = sprintf('pixel_display( %d, %d );', x_size(i), y_size(i));
    if (i < length(camera_struct.roi_struct))
        if (p_shift(i + 1) > 0)
            icl_script.acq{end + 1} = sprintf('shift( %d );', p_shift(i + 1));
        end
    end
end
icl_script.acq{end + 1} = 'script_end( 0 );';
return



% MAKE_IMAGE_WIN
function h_fig = make_image_win(figure_tag)

% default parameters
figure_bkgnd = [0.8 0.8 0.8];       % figure window background colorspec
figure_pos = [0.10 0.10 0.80 0.80]; % figure window position (% of screen)
text_pos = [0.03 0.95 0.87 0.03];   % text label position (% of figure)
button_pos = [0.28 0.03 0.42 0.05]; % button panel position (% of figure)
image_pos = [0.03 0.10 0.87 0.85];  % image display position (% of figure)
color_pos = [0.92 0.10 0.06 0.85];  % colorbar display position (% of figure)

% create figure window
h_fig = figure('Color', figure_bkgnd, ...
    'Units', 'normalized', ...
    'Position', figure_pos, ...
    'BackingStore', 'off', ...
    'CloseRequestFcn', 'pvcamfocus(gcf, ''finish'')', ...
    'MenuBar', 'none', ...
    'Name', 'Focus Window', ...
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
labels = {'Start Focus', 'Stop Focus'};
h_button = guipanel(h_fig, button_pos, 'horizontal', ...
    'Enable', 'off', ...
    'FontName', 'Helvetica', ...
    'FontSize', 8, ...
    'Style', 'pushbutton', ...
    'Callback', 'pvcamfocus(gcf, get(gcbo, ''Tag''))', ...
    'String', labels, ...
    'Tag', labels);
set(h_button(2), 'Callback', 'set(gcf, ''Tag'', ''stop'')');

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

% save handles to figure UserData structure
figure_struct = cell2struct({h_axes, h_text, h_button, [], @gray}, ...
    {'h_axes', 'h_text', 'h_button', 'h_image', 'color_map'}, 2);
set(h_fig, 'UserData', figure_struct);
return



% DISP_COLORBAR
function [] = disp_colorbar(h_fig, h_axes, color_func)

% obtain colorbar axes
if (istype(h_axes, 'axes'))
    axes(h_axes);
    h_image = get(h_axes, 'UserData');
else
    warning('MATLAB:disp_colorbar', 'unable to find colorbar axes');
    return
end

% obtain color map
color_map = feval(color_func, 256);
set(h_fig, 'Colormap', color_map);
display_map = uint8(255 * reshape(color_map, [size(color_map, 1) 1 size(color_map, 2)]));

% display colorbar
if (istype(h_image, 'image'))
    set(h_image, 'CData', display_map);
else
    h_image = image(display_map);
    set(h_image, 'EraseMode', 'none', ...
        'ButtonDownFcn', 'pvcamfocus(gcf, ''color map'')');
    set(h_axes, 'XDir', 'normal', ...
        'XTick', [], ...
        'YDir', 'normal', ...
        'YTick', [], ...
        'Tag', 'colorbar', ...
        'UserData', h_image);
end
return
