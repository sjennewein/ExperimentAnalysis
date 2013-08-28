function color_map = spectrum(num_color);

% SPECTRUM - returns AIW spectrum colormap
%
%    CMAP = SPECTRUM(NCOLOR) returns the AIW spectrum colormap of
%    length NCOLOR.
%
%    CMAP = SPECTRUM returns the AIW spectrum colormap having the
%    same length as the current colormap.

% By:   S.C. Molitor (smolitor@bme.jhu.edu)
% Date: January 25, 1999

% use current colormap size if none provided

if (nargin < 1)
   num_color = size(get(gcf, 'Colormap'), 1);
end

% red: (0, 1) -> (num_color/8, 0) -> (num_color, 1)

red_index = round(num_color/8);
r = [((red_index - 1) : -1 : 0)/(red_index - 1) (1 : 1 : (num_color - red_index))/(num_color - red_index)]';

% green: (0, 0) -> (num_color/2, 1) -> (num_color, 0)

if (mod(num_color, 2) == 0)
   g = [(0 : 2 : (num_color - 2)) ((num_color - 2) : -2 : 0)]'/(num_color - 2);
else
   g = [(0 : 2 : (num_color - 1)) ((num_color - 3) : -2 : 0)]'/(num_color - 1);
end

% blue: (0, 1) -> (num_color, 0)

b = ((num_color - 1) : -1 : 0)'/(num_color - 1);

% assign RGB components to colormap & return

color_map = [r g b];
return
