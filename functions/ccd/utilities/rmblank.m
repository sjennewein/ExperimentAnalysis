function out = rmblank(in);

% RMBLANK - remove leading and trailing blanks from a string
%
%    NEW = RMBLANK(OLD) removes leading and trailing blanks from OLD and
%    returns the string to NEW.

% By:   S.C. Molitor (smolitor@eng.utoledo.edu)
% Date: May 27, 2003

% validate arguments
out = '';
if (nargin ~= 1)
    warning('type ''help rmblank'' for syntax');
    return
elseif (isempty(in) | ~ischar(in))
    %warning('IN must be a string');
    return
end

% deblank both ends of IN
out = fliplr(deblank(fliplr(deblank(in))));
return
