function [new_value, select_flag] = guilist(list_title, list_string, old_value);

% GUILIST - select item from a list with the provided parameters
%
%    [NEWVAL, FLAG] = GUILIST(TITLE, LIST, OLDVAL) creates a figure
%    window named TITLE containing a list box whose items are provided
%    by the cell array LIST.  The item OLDVAL is initially highlighted,
%    and the selected value is stored in NEWVAL.  FLAG indicates how
%    the list was exited (0 if Cancel, 1 if OK).

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: April 20, 1999

% check input parameters

if (nargin ~= 3)
   return
elseif (~ischar(list_title))
   return
elseif (~iscell(list_string))
   return
elseif (~ischar(old_value))
   return
end

% determine size & position of list box figure

max_char = size(char(list_string), 2);
max_line = size(char(list_string), 1);
list_width = min(max((0.04 + 0.008525 * max_char), 0.15), 0.8);
list_height = min(max((0.05 + 0.01872 * max_line), 0.2), 0.8);
list_pos = [(1 - list_width)/2 (1 - list_height)/2 list_width list_height];

% determine initial item to highlight

list_find = find(strcmp(list_string, old_value) == 1);
if (isempty(list_find))
   list_value = 1;
else
   list_value = list_find(1);
end

% create a new figure window to hold the list box

h_fig = figure('Color', [0.8 0.8 0.8], ...
   'Units', 'normalized', ...
   'Position', list_pos, ...
   'MenuBar', 'none', ...
   'Name', list_title, ...
   'NumberTitle', 'off', ...
   'CloseRequestFcn', 'set(gcf, ''UserData'', 0)');

% create a list box with the items provided

h_listbox = uicontrol('Parent', h_fig, ...
   'Style', 'listbox',...
   'Units', 'normalized', ...
   'Position', [0.05 0.15 0.90 0.825], ...
   'BackgroundColor', [1 1 1], ...
   'Min', 1, 'Max', 2, ...
   'Value', list_value, ...
   'String', list_string, ...
   'FontName', 'Courier', ...
   'FontSize', 12);

% create 'OK' & 'Cancel' buttons

h_ok = uicontrol('Parent', h_fig, ...
   'Style', 'pushbutton', ...
   'Units', 'normalized', ...
   'Position', [0.05 0.025 0.425 0.10], ...
   'Callback', 'set(gcf, ''UserData'', 1)', ...
   'String', 'OK');

h_cancel = uicontrol('Parent', h_fig, ...
   'Style', 'pushbutton', ...
   'Units', 'normalized', ...
   'Position', [0.525 0.025 0.425 0.10], ...
   'Callback', 'set(gcf, ''UserData'', 0)', ...
   'String', 'Cancel');

% wait for user to click button or close list figure
% store user selection & delete list figure

waitfor(h_fig, 'UserData');
new_value = list_string{get(h_listbox, 'Value')};
select_flag = get(h_fig, 'UserData');
if (ishandle(h_fig))
   delete(h_fig);
end
return
