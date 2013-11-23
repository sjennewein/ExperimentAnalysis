function varargout = guistruct(varargin)

% GUISTRUCT - create window for editing structure elements
%
%    [OUTPUT, FLAG] = GUISTRUCT(NAME, INPUT) creates a window named NAME
%    where the values contained in the structure INPUT can be individually
%    edited.  The edited structure is returned in OUTPUT.  FLAG indicates
%    how the edit window was exited (0 if Cancel, 1 if OK).
%
%    [ ... ] = GUISTRUCT( ... , LOWER, UPPER, TITLE, FORMAT) allows the
%    user to specify limits on numeric values with the vectors LOWER and
%    UPPER, text labels for the edit boxes with the cell array TITLE, and 
%    numeric or character formats with the cell array FORMAT.  If these
%    values are not provided, appropriate titles, limits and formats will
%    be determined from the contents of INPUT.
%
%    [ ... ] = GUISTRUCT( ..., FORMAT, MULTI) allows the user to specify
%    whether numeric values are 'scalar' or 'vector' so that numeric data
%    can be limited to single or multiple values.  If MULTI is 'fixed', 
%    then the length of a numeric array is fixed to be the length of the
%    current value.  If MULTI is 'enumerated', then the edit box is
%    replaced by a drop-down list whose values are obtained from the cell
%    array FORMAT.  Set MULTI to 'string' for non-enumerated character
%    strings.
%
%    [ ... ] = GUISTRUCT( ..., SORT, ENABLE) allows the user to specify the
%    display order in the vector SORT and to enable editing with the
%    logical vector ENABLE.
%
%    The limits and format of the edited values can also be provided by
%    setting INPUT as a structure array with the fields 'name', 'value',
%    'upper', 'lower', 'title', 'format' and 'multi'.  Optional fields
%    'sort' and 'enable' may also be included in this structure array.
%    These values can also be provided by the PBM-style structure created
%    for the ACQ program, see STRUCT_EDIT.M or MATPVCAM_NEW.M for details.

% By:   S.C. Molitor (smolitor@eng.utoledo.edu)
% Date: May 27, 2003

% MOD 6/3/04 SCM for compatibility for PBM style structures
% added 'fixed' length option for MULTI to force constant vector length
% allow PBM format field to contain cell array for enumerated lists
% accounts for locked fields to disable UICONTROLS
% orders lists based on PBM number field

% initialize output
if (nargout > 0)
    varargout = cell(1, nargout);
end

% validate arguments
if ((nargin < 1) || (nargin > 9))
    warning('MATLAB:guistruct', 'type ''help guistruct'' for syntax');
    return
elseif (nargin == 1)
    if (istype(varargin{1}, 'uicontrol'))
        h_obj = varargin{1};
        control_command = 'validate';
    else
        warning('MATLAB:guistruct', 'H_OBJ must be a valid UICONTROL');
        return
    end
elseif (~ischar(varargin{1}) || isempty(varargin{1}))
    warning('MATLAB:guistruct', 'NAME must be a string');
    return
elseif (~isstruct(varargin{2}) || isempty(varargin{2}))
    warning('MATLAB:guistruct', 'INPUT must be a structure');
    return
else
    control_command = 'initialize';
    fig_title = varargin{1};
    edit_struct = varargin{2};
end

% validate edited values when callback occurs
% strings are always valid
% otherwise check valid numeric conversion
if (strcmp(control_command, 'validate'))
    element_struct = get(h_obj, 'UserData');
    edit_value = get(h_obj, 'String');
    if (strcmp(element_struct.format, '%s') || strcmp(element_struct.format, '%c'))
        element_struct.value = edit_value;
    elseif (~isempty(edit_value))
        % enforce approriate scalar & vector lengths
        new_value = str2num(edit_value);
        % MOD 6/17/05 SCM
        % enforce integer format
        if (~isempty(strmatch('%d', element_struct.format)))
            new_value = round(new_value);
        end
        if (~isempty(new_value))
            switch (element_struct.multi)
                case 'scalar'
                    element_struct.value = new_value(1);
                case 'fixed'
                    if (length(new_value) > length(element_struct.value))
                        element_struct.value = new_value(1 : length(element_struct.value));
                    else
                        element_struct.value(1 : length(new_value)) = new_value;
                    end
                case 'vector'
                    element_struct.value = new_value;
            end
            % enforce limits on numeric conversions
            element_struct.value = min(element_struct.value, element_struct.upper);
            element_struct.value = max(element_struct.value, element_struct.lower);
        end
    end
    set(h_obj, 'String', rmblank(sprintf(element_struct.format, element_struct.value)));
    set(h_obj, 'UserData', element_struct);
    return
elseif (~strcmp(control_command, 'initialize'))
    warning('MATLAB:guistruct', '%s is not a valid command, type ''help guistruct'' for syntax', control_command);
    return
end

% determine structure format (native, PBM or regular)
% assume default format is regular
field_name = fieldnames(edit_struct);
element_field = {'name', 'value', 'lower', 'upper', 'title', 'format', 'multi'};
struct_type = 'regular';
if (all(ismember(element_field, field_name)))
    % native format is used by subsequent code
    % copy INPUT directly
    struct_type = 'native';
    element_list = edit_struct;
    % MOD 6/4/04 SCM
    % account for optional sort field
    % account for optional enable field
    if (isfield(element_list, 'sort'))
        element_sort = [element_list(:).sort];
    else
        element_sort = (1 : length(element_list));
    end
    if (isfield(element_list, 'lock'))
        element_enable = ([element_list(:).lock] == 0);
    else
        element_enable = ones(1, length(element_list));
    end
else
    % PBM format has 'start' and 'end' fields
    % check fields in between are structures with specific fields
    % copy info from each field in INPUT to native format
    [field_flag, field_index] = ismember({'start', 'end'}, field_name);
    if (all(field_flag))
        struct_type = 'PBM';
        % MOD 6/3/04 SCM
        % check for enumerated list & fixed length vectors
        multi_list = {'enumerated', 'scalar', 'vector', 'fixed'};
        for i = field_index(1) + 1 : field_index(end) - 1
            element_struct = edit_struct.(field_name{i});
            if (all(ismember({'v', 'm', 'n', 't', 'f', 'l', 'vl', 'vh'}, fieldnames(element_struct))))
                % MOD 6/3/04 SCM
                % convert MULTI flag to value from multi_list cell
                % make sure MULTI flags are 'enumerated' or 'string' for string values
                if (ischar(element_struct.v) && (element_struct.m >= 0))
                    element_struct.f = '%s';
                    element_struct.m = 'string';
                else
                    element_struct.m = multi_list{min(max((element_struct.m + 2), 1), length(multi_list))};
                end
                % MOD 6/4/04 SCM
                % account for PBM sorting field
                % allow locked parameters
                element_sort(i - field_index(1)) = element_struct.n;
                element_enable(i - field_index(1)) = (element_struct.l == 0);
                % convert from PBM to native format
                element_list(i - field_index(1)) = cell2struct({field_name{i}, element_struct.v, element_struct.vl, ...
                        element_struct.vh, element_struct.t, element_struct.f, element_struct.m}, element_field, 2);
            else
                struct_type = 'regular';
                break
            end
        end
    end
end

% copy field values from regular structure
% use command line arguments if provided
% otherwise use defaults from structure
if (strcmp(struct_type, 'regular'))
    element_lower = chkvarargin(varargin, 3, 'double', [1 length(field_name)], 'lower', -Inf);
    element_upper = chkvarargin(varargin, 4, 'double', [1 length(field_name)], 'upper', Inf);
    element_title = chkvarargin(varargin, 5, 'cell', [1 length(field_name)], 'title', field_name');
    element_format = chkvarargin(varargin, 6, 'cell', [1 length(field_name)], 'format', '');
    element_multi = chkvarargin(varargin, 7, 'cell', [1 length(field_name)], 'multi', '');
    % MOD 6/4/04 SCM
    % account for optional sort field
    % account for optional enable field
    element_sort = chkvarargin(varargin, 8, 'double', [1 length(field_name)], 'sort', 1);
    if (all(element_sort == 1))
        element_sort = (1 : length(field_name));
    end
    element_enable = chkvarargin(varargin, 9, 'double', [1 length(field_name)], 'enable', 1);
    for i = 1 : length(field_name)
        % obtain current structure values
        % change default format based on value type
        element_value = edit_struct(1).(field_name{i});
        if (isempty(element_format{i}))
            if (ischar(element_value))
                element_format{i} = '%s';
            else
                element_format{i} = '%g';
            end
        end
        % change default multi flag based on value type
        if (isempty(element_multi{i}))
            if (ischar(element_value))
                element_multi{i} = 'string';
            elseif (isnumeric(element_value) && (length(element_value) > 1))
                element_multi{i} = 'vector';
            else
                element_multi{i} = 'scalar';
            end
        end
        % create structure element for edit box
        element_list(i) = cell2struct({field_name{i}, element_value, element_lower(i), ...
                element_upper(i), element_title{i}, element_format{i}, element_multi{i}}, element_field, 2);
    end
end

% verify MULTI flags and FORMAT specifiers
element_flag = ones(1, length(element_list));
for i = 1 : length(element_list)
    err_msg = sprintf('ignoring %s field %s with %s value', ...
        upper(element_list(i).multi), upper(element_list(i).name), upper(class(element_list(i).value)));
    switch (element_list(i).multi)
        case 'scalar'
            % check for valid scalar fields
            % truncate vectors for scalar fields
            if (~isnumeric(element_list(i).value) || isempty(element_list(i).value))
                element_flag(i) = 0;
            else
                element_list(i).value = element_list(i).value(1);
            end
        case {'vector', 'fixed'}
            % check for valid vector fields
            % add space to vector field format for integer spacing
            if (~isnumeric(element_list(i).value) || isempty(element_list(i).value))
                element_flag(i) = 0;
            elseif (all(round(element_list(i).value) == element_list(i).value))
                element_list(i).format = [element_list(i).format ' '];
            end
        case 'enumerated'
            % make sure 'enumerated' fields have cell array format for list
            % make sure 'enumerated' values are strings
            % add enumerated value if not already in list
            if (~iscellstr(element_list(i).format))
                element_flag(i) = 0;
                err_msg = sprintf('%s - format field is not cell array of strings', err_msg);
            elseif (~ischar(element_list(i).value) || isempty(element_list(i).value))
                element_flag(i) = 0;
            elseif (isempty(strmatch(element_list(i).value, element_list(i).format, 'exact')))
                element_list(i).format{end + 1} = element_list(i).value;
            end
        case 'string'
            % check for valid vector fields
            if (~ischar(element_list(i).value))
                element_flag(i) = 0;
            end
        otherwise
            % invalid MULTI flag
            element_flag(i) = 0;
    end
    % display error message if field ignored
    if (~element_flag(i))
        warning('MATLAB:guistruct', err_msg);
    end
end

% make sure something passed through to be edited
element_index = find(element_flag);
if (isempty(element_index))
    warning('MATLAB:guistruct', 'all values have been ignored, exiting ...')
    for i = 1 : nargout
        switch (i)
            case 1
                varargout{i} = edit_struct;
            case 2
                varargout{i} = 0;
            otherwise
                varargout{i} = [];
        end
    end
    return
else
    % MOD 6/4/04 SCM
    % account for optional sort field
    [element_sort, element_index] = sort(element_sort(element_index));
end

% determine layout of edit boxes on figure window
% calculate size & location of figure window
% things will be tight if more than 60 elements!
edit_col = ceil(length(element_index) / 20);
edit_row = ceil(length(element_index) / edit_col);
fig_height = min(0.80, (0.10 + 0.035 * edit_row));
fig_width = min(0.80, (0.05 + 0.250 * edit_col));
fig_pos = [(1 - fig_width)/2 (1 - fig_height)/2 fig_width fig_height];

% calculate size & spacing of edit boxes
% text label width = edit box width
% horizontal space = edit box width / 4
% vertical space = edit box height / 2
edit_width = 4 / (9 * edit_col + 1);
space_width = edit_width / 4;
edit_height = 2 / (3 * edit_row + 6);
space_height = edit_height / 2;

% calculate size & spacing of OK & Cancel buttons
button_height = 3 * edit_height / 2;
button_width = min(0.4, 3 * edit_width / 2);
button_left = (1 - 2 * button_width) / 3;
button_right = 2 * button_left + button_width;

% create a new figure window to hold the edit boxes
h_fig = figure('Units', 'normalized', ...
    'Position', fig_pos, ...
    'MenuBar', 'none', ...
    'Name', fig_title, ...
    'NumberTitle', 'off', ...
    'Resize', 'off', ...
    'Tag', '', ...
    'UserData', [], ...
    'CloseRequestFcn', 'set(gcf, ''Tag'', ''cancel'')');

% create array of edit boxes and text labels
% loop through array elements to create edit boxes
x_pos = space_width;
y_pos = 1;
enable_string = {'off', 'on'};
for i = 1 : length(element_index)
    y_pos = y_pos - edit_height - space_height;
    h_text(i) = uicontrol('Parent', h_fig, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [x_pos y_pos edit_width edit_height], ...
        'BackgroundColor', get(h_fig, 'Color'), ...
        'ForegroundColor', [0 0 0], ...
        'FontName', 'helvetica', ...
        'FontSize', 8, ...
        'HorizontalAlignment', 'right', ...
        'String', sprintf('%s :   ', element_list(element_index(i)).title));
    
    % create edit box or drop-down list depending on MULTI flag
    % MOD 6/4/04 SCM
    % account for optional enable field
    h_edit(i) = uicontrol('Parent', h_fig, ...
        'Units', 'normalized', ...
        'Position', [(x_pos + edit_width) y_pos edit_width edit_height], ...
        'BackgroundColor', [1 1 1], ...
        'ForegroundColor', [0 0 0], ...
        'Enable', enable_string{element_enable(element_index(i)) + 1}, ...
        'FontName', 'helvetica', ...
        'FontSize', 8, ...
        'UserData', element_list(element_index(i)), ...
        'Tag', sprintf('%d', element_index(i)));
    if (strcmp(element_list(element_index(i)).multi, 'enumerated'))
        set(h_edit(i), 'HorizontalAlignment', 'left', ...
            'Style', 'popupmenu',...
            'String', element_list(element_index(i)).format, ...
            'Value', strmatch(element_list(element_index(i)).value, element_list(element_index(i)).format, 'exact'), ...
            'Callback', '');
    else
        edit_string = rmblank(sprintf(element_list(element_index(i)).format, element_list(element_index(i)).value));
        % allow for multiline text if needed
        if (isempty(find(edit_string == sprintf('\n'))))
            max_value = 1;
        else
            max_value = 2;
        end
        set(h_edit(i), 'HorizontalAlignment', 'center', ...
            'Style', 'edit', ...
            'Min', 0, 'Max', max_value, ...
            'String', rmblank(sprintf(element_list(element_index(i)).format, element_list(element_index(i)).value)), ...
            'Callback', 'guistruct(gcbo)');
    end
    
    % check for next column
    if (mod(i, edit_row) == 0)
        x_pos = x_pos + 2 * edit_width + space_width;
        y_pos = 1;
    end
end

% create 'OK' & 'Cancel' buttons
% create separator
y_pos = space_height;
h_ok = uicontrol('Parent', h_fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [button_left y_pos button_width button_height], ...
    'Callback', 'set(gcf, ''Tag'', ''ok'')', ...
    'String', 'OK');

h_cancel = uicontrol('Parent', h_fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [button_right y_pos button_width button_height], ...
    'Callback', 'set(gcf, ''Tag'', ''cancel'')', ...
    'String', 'Cancel');

y_pos = y_pos + button_height + space_height;
h_frame = uicontrol('Parent', h_fig, ...
    'Style', 'frame', ...
    'Units', 'normalized', ...
    'Position', [0 y_pos 1 edit_height/20]);

% wait for user to click button or close edit figure
% copy structure values if selected
waitfor(h_fig, 'Tag');
edit_flag = strcmp(get(h_fig, 'Tag'), 'ok');
if (edit_flag)
    for i = 1 : length(h_edit)
        % update structure values from edit box UserData
        % store string for enumerated values
        % validation routine handles string conversions
        element_index = str2num(get(h_edit(i), 'Tag'));
        element_struct = get(h_edit(i), 'UserData');
        if (strcmp(element_struct.multi, 'enumerated'))
            element_struct.value = element_struct.format{get(h_edit(i), 'Value')};
        end
        
        % copy element values to appropriate structure type
        switch (struct_type)
            case 'regular'
                edit_struct.(element_struct.name) = element_struct.value;
            case 'native'
                edit_struct(element_index).value = element_struct.value;
            case 'PBM'
                pbm_struct = edit_struct.(element_struct.name);
                pbm_struct.v = element_struct.value;
                edit_struct.(element_struct.name) = pbm_struct;
        end
    end
end

% delete edit figure
if (istype(h_fig, 'figure'))
    delete(h_fig);
end

% return outputs if specified
for i = 1 : nargout
    switch (i)
        case 1
            varargout{i} = edit_struct;
        case 2
            varargout{i} = edit_flag;
        otherwise
            varargout{i} = [];
    end
end
return
