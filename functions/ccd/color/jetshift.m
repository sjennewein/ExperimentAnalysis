function color_map = jetshift(num_color);

% JETSHIFT - returns a red-shifted JET colormap
%
%    CMAP = JETSHIFT(NCOLOR) returns a red-shifted JET colormap of
%    length NCOLOR.
%
%    CMAP = JETSHIFT returns the red-shifted JET colormap having the
%    same length as the current colormap.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: April 11, 2000

% use current colormap size if none provided

if (nargin < 1)
   num_color = size(get(gcf, 'Colormap'), 1);
end

% modified from JET.M code

num_quarter = max(round(num_color/4), 1);
x = (1 : num_quarter)'/num_quarter;
y = (num_quarter/2 : num_quarter)'/num_quarter;
z = (0 : num_quarter/2)'/num_quarter;
e = ones(length(x), 1);


r = [flipud(z); 0*x; x; e; flipud(y)];
g = [0*y; x; e; flipud(x); 0*y];
b = [y; e; flipud(x); 0*e; 0*y];

color_map = [r g b];
while size(color_map, 1) > num_color
   color_map(1, :) = [];
   if (size(color_map, 1) > num_color)
      color_map(size(color_map, 1), :) = [];
   end
end
