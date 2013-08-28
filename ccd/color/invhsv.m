function color_map = invhsv(num_color);

% INVHSV - returns inverted HSV colormap
%
%    CMAP = INVHSV(NCOLOR) returns an inverted HSV colormap of length
%    NCOLOR.
%
%    CMAP = INVHSV returns the inverted HSV colormap having the same
%    length as the current colormap.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: April 11, 2000

% use current colormap size if none provided

if (nargin < 1)
   num_color = size(get(gcf, 'Colormap'), 1);
end

% return inverted HSV colormap

color_map = flipdim(hsv(num_color), 1);
return
