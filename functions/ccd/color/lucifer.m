function color_map = lucifer(num_color);

% LUCIFER - returns PBM's Lucifer Yellow colormap
%
%    CMAP = LUCIFER(NCOLOR) returns PBM's Lucifer Yellow colormap of
%    length NCOLOR.
%
%    CMAP = LUCIFER returns the Lucifer Yellow colormap having the
%    same length as the current colormap.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: January 25, 1999

% use current colormap size if none provided

if (nargin < 1)
   num_color = size(get(gcf, 'Colormap'), 1);
end

% red: (0, 0) -> (num_color/2, 0) -> (num_color, 1)

r = zeros(1, floor(num_color/2));
if (mod(num_color, 2) == 0)
   r = [r (2 : 2 : num_color)/num_color]';
else
   r = [r (1 : 2 : num_color)/num_color]';
end

% green: (0, 0) -> (num_color, 1)

g = (0 : (num_color - 1))'/(num_color - 1);

% blue: (0, 0 -> (num_color, 0)

b = 0.0*g;

% assign RGB components to colormap & return

color_map = [r g b];
return
