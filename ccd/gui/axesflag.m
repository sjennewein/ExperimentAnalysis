function [x_output, y_output] = axesflag(h_axes, x_input, y_input);

% AXESFLAG - checks if coordinates fall within axes limits
%
%    FLAG = AXESFLAG(H_AXES, X, Y) returns a flag to indicate whether
%    the coordinate (X, Y) falls within the axes limits of H_AXES.
%
%    [XN, YN] = AXESFLAG(H_AXES, X, Y) returns coordinates (XN, YN)
%    to force (X, Y) to fall within the axes limits of H_AXES.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: March 30, 1999

% check input arguments

if (nargin ~= 3)
   return
elseif (~istype(h_axes, 'axes'))
   return
elseif (~isnumeric(x_input) | (length(x_input) ~= 1))
   return
elseif (~isnumeric(y_input) | (length(y_input) ~= 1))
   return
end

% obtain axes limits

x_lim = get(h_axes, 'XLim');
y_lim = get(h_axes, 'YLim');

% if two outputs, return (XN, YN)
% otherwise, return axis flag

if (nargout == 2)
   x_output = min(max(x_input, x_lim(1)), x_lim(2));
   y_output = min(max(y_input, y_lim(1)), y_lim(2));
elseif ((x_input >= min(x_lim)) & (x_input <= max(x_lim)) & (y_input >= min(y_lim)) & (y_input <= max(y_lim)))
   x_output = 1;
else
   x_output = 0;
end
return
