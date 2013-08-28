function h_control = guipanel(h_fig, panel_pos, orient_flag, varargin)

% GUIPANEL - create a control panel with the provided parameters
%
%    H_CTL = GUIPANEL(H_FIG, POS, 'horizontal', 'Name1', value1, ...)
%    creates a horizontal panel of controls on the figure window H_FIG.
%    The location of the panel is determined by the values in POS, a
%    four element vector containing the normalized coordinate values
%    [LEFT BOTTOM WIDTH HEIGHT].  The control properties are specified
%    by pairs of the form NAME/VALUE, where the property name is
%    provided by a string NAME and the property values for each control
%    are given by a subsequent cell array VALUE.  The control object
%    handles are returned as a vector H_CTL.
%
%    H_CTL = GUIPANEL(H_FIG, POS, 'vertical', ...) creates a vertical
%    panel of controls.
%
%    H_CTL = GUIPANEL(H_FIG, POS, [NR NC], ...) creates a panel of
%    controls having NR rows and NC columns of controls.

% By:   S.C. Molitor (smolitor@eng.utoledo.edu)
% Date: February 21, 2003

% check fixed input parameters
h_control = [];
if (nargin < 5)
    warning('MATLAB:guipanel', 'type ''help guipanel'' for syntax');
    return
elseif (~istype(h_fig, 'figure'))
    warning('MATLAB:guipanel', 'H_FIG must be a valid figure window');
    return
elseif (~isnumeric(panel_pos) || (length(panel_pos) ~= 4))
    warning('MATLAB:guipanel', 'POS must be a numeric vector with four elements');
    return
end

% make sure variable inputs are property name/value pairs
% create cell array to store name/value pairs
% count number of controls to be created
num_control = 1;
[prop_name, prop_value, prop_cell] = deal({});
for i = 2 : 2 : length(varargin)
    if (ischar(varargin{i - 1}) && ~isempty(varargin{i - 1}))
        prop_name{end + 1} = varargin{i - 1};
        if (isempty(varargin{i}))
            warning('MATLAB:guipanel', 'argument %d is not a valid property value', i + 3);
            return
        else
            prop_value{end + 1} = varargin{i};
            if (iscell(varargin{i}))
                if (num_control == 1)
                    num_control = length(varargin{i});
                else
                    num_control = min(num_control, length(varargin{i}));
                end
            end
        end
    else
        warning('MATLAB:guipanel', 'argument %d is not a valid property name', i + 2);
        return
    end
end

% copy property values to cell array
% needed for scalar property values
for i = 1 : length(prop_value)
    if (iscell(prop_value{i}))
        [prop_cell{i, 1 : num_control}] = deal(prop_value{i}{1 : num_control});
    else
        [prop_cell{i, 1 : num_control}] = deal(prop_value{i});
    end
end

% calculate layout of controls
% default layout is vertical
if (ischar(orient_flag))
    if (strcmp(orient_flag, 'horizontal'))
        num_rows = 1;
        num_cols = num_control;
    else
        num_rows = num_control;
        num_cols = 1;
    end
elseif (isnumeric(orient_flag))
    if (length(orient_flag) == 2)
        num_rows = orient_flag(1);
        num_cols = orient_flag(2);
    else
        num_rows = num_control;
        num_cols = 1;
    end
else
    num_rows = num_control;
    num_cols = 1;
end

% layout controls
control_width = panel_pos(3)/num_cols;
control_height = panel_pos(4)/num_rows;
control_bottom = panel_pos(2) + panel_pos(4);
control_count = 0;
h_control = zeros(1, num_rows * num_cols);
for i = 1 : num_rows
    control_left = panel_pos(1);
    control_bottom = control_bottom - control_height;
    for j = 1 : num_cols
        control_count = control_count + 1;
        h_control(control_count) = uicontrol(...
            'Parent', h_fig, ...
            'Units', 'normalized', ...
            'Position', [control_left control_bottom control_width control_height]);
        if (control_count <= num_control)
            for k = 1 : length(prop_name)
                set(h_control(control_count), prop_name{k}, prop_cell{k, control_count});
            end
        end
        control_left = control_left + control_width;
    end
end
return
