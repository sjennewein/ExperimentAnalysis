function new_struct = defstruc(old_struct, field_name, default_value);

% DEFSTRUC - initialize structure with default values if needed
%
%    NEW = DEFSTRUC(OLD, FIELD, DEFAULT) insures that all fields in the
%    cell array FIELD are present in OLD.  If not present, these fields are
%    added to NEW and initialized with values in the cell array DEFAULT.
%
%    If OLD is a structure array and new fields are to be added, the value
%    of FIELD is set to the specified value in DEFAULT for each member of
%    the structure array.

% By:   S.C. Molitor (smolitor@eng.utoledo.edu)
% Date: April 14, 2000
% MOD 1/5/04 SCM

% validate arguments
if (nargin ~= 3)
    warning('type ''help defstruc'' for syntax');
    return
elseif (~isempty(old_struct) & ~isstruct(old_struct))
    warning('OLD must be a structure or an empty variable');
    return
elseif (~iscellstr(field_name))
    return
elseif (~iscell(default_value))
    return
else
    num_field = min(length(field_name), length(default_value));
end

% make copy of structure for output
% check for field existence
% create field with default value if field doesn't exist
new_struct = old_struct;
for i = 1 : num_field
    if (~isfield(new_struct, field_name{i}))
        if (length(new_struct) > 1)
            for j = 1 : length(new_struct)
                new_struct(j).(field_name{i}) = default_value{i};
            end
        else
            new_struct.(field_name{i}) = default_value{i};
        end
    end
end
return
