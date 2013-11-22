function color_map = invgray(num_color);

% INVGRAY - returns inverted grayscale colormap
%
%    CMAP = INVGRAY(NCOLOR) returns an inverted grayscale (white to black)
%    colormap of length NCOLOR.
%
%    CMAP = INVGRAY returns the inverted grayscale colormap having the
%    same length as the current colormap.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: January 25, 1999

% use current colormap size if none provided

if (nargin < 1)
   num_color = size(get(gcf, 'Colormap'), 1);
end

% return inverted gray colormap

color_map = flipdim(gray(num_color), 1);
return
