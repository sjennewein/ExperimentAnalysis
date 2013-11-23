function ver_num = getversion();

% GETVERSION - convert MATLAB version info into number
%
%    NVER = GETVERSION returns a number to for the current MATLAB version.
%    Note versions before 2006a
% 3/29/06 SCM

% obtain MATLAB version number
% remove multiple decimal points
ver_struct = ver('matlab');
dec_pt_loc = strfind(ver_struct.Version, '.');
ver_struct.Version = strrep(ver_struct.Version, '.', '');
if (~isempty(dec_pt_loc))
    ver_struct.Version = [ver_struct.Version(1 : dec_pt_loc(1) - 1) '.' ver_struct.Version(dec_pt_loc(1) : end)];
end
ver_num = str2num(ver_struct.Version);
return
