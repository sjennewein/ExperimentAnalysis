function varargout = guirbsel(h_fig, h_axes, command_str)

% GUIRBSEL - obtain coordinates from selected region
%
%    [X1, Y1, X2, Y2, FLAG] = GUIRBSEL(H_FIG, H_AXES) allows the user
%    to select a region on the image displayed on H_AXES.  The region
%    is selected graphically using the mouse.  The coordinates of the
%    region are returned in (X1, Y1) and (X2, Y2).  FLAG indicates
%    whether a valid region was selected (0 if invalid, 1 if valid).

% By:   S.C. Molitor (smolitor@med.unc.edu)
% Date: May 18, 2000
% modified 7/22/02 SCM

% initialize output
if (nargout > 0)
    varargout = cell(1, nargout);
end

% check input parameters
if ((nargin < 2) || (nargin > 3))
    warning('MATLAB:guirbsel', 'Invalid number of arguments');
    return
elseif (~istype(h_fig, 'figure'))
    warning('MATLAB:guirbsel', 'H_FIG must be a valid figure handle');
    return
elseif (~istype(h_axes, 'axes'))
    warning('MATLAB:guirbsel', 'H_AXES must be a valid axes handle');
    return
elseif (nargin == 2)
    command_str = 'start';
elseif (~ischar(command_str) || isempty(command_str))
    warning('MATLAB:guirbsel', 'COMMAND must be a character string');
    return
end

switch (command_str)

    case 'start'
        % set figure & axis to be active
        % initialize structure for selection parameters
        figure(h_fig);
        axes(h_axes);

        % change pointer type
        % change button down callbacks
        % save old values
        pointer_type = get(h_fig, 'Pointer');
        set(h_fig, 'Pointer', 'crosshair');
        button_down = get(h_fig, 'WindowButtonDownFcn');
        set(h_fig, 'WindowButtonDownFcn', '');
        button_up = get(h_fig, 'WindowButtonUpFcn');
        set(h_fig, 'WindowButtonUpFcn', '');
        h_child = [h_fig; h_axes; get(h_axes, 'Children')];
        child_down = get(h_child, 'ButtonDownFcn');
        set(h_child, 'ButtonDownFcn', '');
        user_data = get(h_fig, 'UserData');
        set(h_fig, 'UserData', []);

        % set ButtonDown callback routine to get region coordinates
        % waitfor UserData to be changed after region is selected
        set(h_fig, 'WindowButtonDownFcn', 'guirbsel(gcf, gca, ''select'')');
        waitfor(h_fig, 'UserData');

        % order coordinates
        % determine if valid region selected
        box_coord = get(h_fig, 'UserData');
        box_coord = [min(box_coord, [], 1); max(box_coord, [], 1)];
        select_flag = (min(diff(box_coord, 1, 1)) > 0);

        % reset figure properties
        set(h_fig, 'Pointer', pointer_type);
        set(h_fig, 'WindowButtonDownFcn', button_down);
        set(h_fig, 'WindowButtonUpFcn', button_up);
        for i = 1 : min(length(h_child), length(child_down))
            set(h_child(i), 'ButtonDownFcn', child_down{i});
        end
        set(h_fig, 'UserData', user_data);

        % assign output
        output_val = [reshape(box_coord', 1, numel(box_coord)) select_flag];
        for i = 1 : min(nargout, length(output_val))
            varargout{i} = output_val(i);
        end

    case 'select'
        % if first click is within axes limits, obtain second point
        % limit second point to be within axes ranges
        % otherwise second point equals first point
        get_point = get(h_axes, 'CurrentPoint');
        box_coord = get_point(1, 1 : 2);
        if (axesflag(h_axes, box_coord(1), box_coord(2)))
            finalrect = rbbox;
            get_point = get(h_axes, 'CurrentPoint');
            box_coord(2, :) = get_point(1, 1 : 2);
            [box_coord(2, 1), box_coord(2, 2)] = axesflag(h_axes, box_coord(2, 1), box_coord(2, 2));
        else
            box_coord(2, :) = box_coord(1, :);
        end
        set(h_fig, 'UserData', box_coord);

    otherwise
        warning('MATLAB:guirbsel', '%s is an invalid COMMAND string', command_str);
end
return
