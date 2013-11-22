function [axis_ptr, axis_flag] = ptrpos(h_fig, h_axes, ptr_type)

% PTRPOS - obtains the pointer position relative to the axes
%
%    [PTR, FLAG] = PTRPOS(H_FIG, H_AXES) returns the coordinates
%    of the current pointer position within the figure window H_FIG
%    relative to the axes specified by the object handle H_AXES.  The
%    (X, Y) pointer coordinates are returned as the row vector PTR,
%    and FLAG is a logical value to indicate whether or not the
%    pointer is within axes limits.
%
%    [...] = PTRPOS(H_FIG, H_AXES, 'image') returns coordinates
%    suitable for image data.  The coordinates are rounded to
%    the nearest integer, and the value of FLAG is calculated
%    to prevent pointer values exceeding image indices.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: May 17, 1999

% check input arguments
if ((nargin < 2) || (nargin > 3))
    return
elseif (~istype(h_fig, 'figure'))
    return
elseif (~istype(h_axes, 'axes'))
    return
elseif (nargin == 2)
    ptr_type = '';
elseif (~ischar(ptr_type))
    return
end

% determine pointer position normalized to the screen size
scr_size = get(0, 'ScreenSize');
ptr_pos = get(0, 'PointerLocation');
ptr_x = (ptr_pos(1) - scr_size(1))/scr_size(3);
ptr_y = (ptr_pos(2) - scr_size(2))/scr_size(4);

% determine the axis position normalized to the screen size
figure_pos = get(h_fig, 'Position');
axis_pos = get(h_axes, 'Position');
axis_x1 = figure_pos(1) + axis_pos(1)*figure_pos(3);
axis_x2 = axis_x1 + axis_pos(3)*figure_pos(3);
axis_y1 = figure_pos(2) + axis_pos(2)*figure_pos(4);
axis_y2 = axis_y1 + axis_pos(4)*figure_pos(4);

% normalize pointer X coordinate relative to X axis limits
% account for reversed X axis direction
x_lim = get(h_axes, 'XLim');
if (strcmp(get(h_axes, 'XDir'), 'reverse'))
    axis_ptr(1) = x_lim(2) + (x_lim(1) - x_lim(2))*(ptr_x - axis_x1)/(axis_x2 - axis_x1);
else
    axis_ptr(1) = x_lim(1) + (x_lim(2) - x_lim(1))*(ptr_x - axis_x1)/(axis_x2 - axis_x1);
end

% normalize pointer Y coordinate relative to Y axis limits
% account for reversed Y axis direction
y_lim = get(h_axes, 'YLim');
if (strcmp(get(h_axes, 'YDir'), 'reverse'))
    axis_ptr(2) = y_lim(2) + (y_lim(1) - y_lim(2))*(ptr_y - axis_y1)/(axis_y2 - axis_y1);
else
    axis_ptr(2) = y_lim(1) + (y_lim(2) - y_lim(1))*(ptr_y - axis_y1)/(axis_y2 - axis_y1);
end

% determine whether pointer falls within axis range
% round to nearest integer to prevent out of range pixel indices
if (strcmp(ptr_type, 'image'))
    axis_ptr = round(axis_ptr);
    if ((axis_ptr(1) >= ceil(x_lim(1))) && (axis_ptr(1) <= floor(x_lim(2))) && ...
            (axis_ptr(2) >= ceil(y_lim(1))) && (axis_ptr(2) <= floor(y_lim(2))))
        axis_flag = 1;
    else
        axis_flag = 0;
    end
else
    if ((axis_ptr(1) >= x_lim(1)) && (axis_ptr(1) <= x_lim(2)) && ...
            (axis_ptr(2) >= y_lim(1)) && (axis_ptr(2) <= y_lim(2)))
        axis_flag = 1;
    else
        axis_flag = 0;
    end
end
return
