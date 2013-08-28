function new_val = chkvarargin(inp_cell, inp_index, inp_class, inp_size, inp_name, def_val);

% CHKVARARGIN - validates arguments passed via VARARGIN cell array
%
%    NEW = CHKVARARGIN(VARARGIN, INDEX, CLASS, SIZE, NAME, DEF) checks
%    that VARARGIN{INDEX} is variable of specified CLASS and SIZE.  If
%    not, NEW is returned, has CLASS and SIZE, and is initialized to
%    default values provided in DEF.

% 5/22/03 SCM
% MOD 1/6/04 SCM to handle strings

% initialize output
% validate arguments
new_val = [];
if (nargin ~= 6)
    warning('type ''help chkvarargin'' for syntax');
    return
elseif (~isscalar(inp_index))
    warning('INDEX must be a scalar');
    return
elseif (~ischar(inp_class) | isempty(inp_class))
    warning('CLASS must be a string');
    return
elseif (~isnumeric(inp_size) | (length(inp_size) < 2))
    warning('SIZE must be a numeric vector');
    return
elseif (~ischar(inp_name) | isempty(inp_name))
    warning('NAME must be a string');
    return
end

% create default output if needed
% check default value is appropriate
switch (lower(inp_class))
    
    case {'double', 'logical', 'single', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'}
        if (isscalar(def_val))
            new_val = feval(inp_class, double(def_val) * ones(inp_size));
        else
            warning(sprintf('DEF must be a scalar for %s input', upper(inp_class)));
            return
        end
        
    case 'char'
        % make sure default string has correct number of rows
        if (ischar(def_val) & (size(def_val, 1) == inp_size(1)))
            new_val = def_val;
        else
            warning(sprintf('DEF must be a character array with %d rows for CHAR input', inp_size(1)));
            return
        end
        
    case 'cell'
        if (iscell(def_val) & all(size(def_val) == inp_size))
            new_val = def_val;
        else
            new_val = cell(inp_size);
            [new_val{:}] = deal(def_val);
        end
        
    otherwise
        warning(sprintf('cannot initialize %s variables', upper(inp_class)));
        return
end

% return default if VARARGIN too short
% return default if VARARGIN(INDEX) not appropriate type or size
% otherwise return old value
if (~iscell(inp_cell))
    %warning('VARARGIN must be a cell array');
elseif (length(inp_cell) < inp_index)
    %warning(sprintf('VARARGIN has length %d, should be at least %d', length(inp_cell), inp_index));
elseif (isempty(inp_cell{inp_index}))
    %warning(sprintf('%s is empty', upper(inp_name)));
elseif (~isa(inp_cell{inp_index}, lower(inp_class)))
    warning(sprintf('%s is %s, should be %s', upper(inp_name), upper(class(inp_cell{inp_index})), upper(inp_class)));
elseif (ischar(inp_cell{inp_index}) & (size(inp_cell{inp_index}, 1) ~= inp_size(1)))
    warning(sprintf('%s has %s rows, should have %s', upper(inp_name), size(inp_cell{inp_index}, 1), inp_size(1)));
elseif (ischar(inp_cell{inp_index}))
    new_val = inp_cell{inp_index};
elseif (prod(size(inp_cell{inp_index})) ~= prod(inp_size))
    warning(sprintf('%s has size [%s], should be [%s]', upper(inp_name), int2str(size(inp_cell{inp_index})), int2str(inp_size)));
else
    new_val = reshape(inp_cell{inp_index}, inp_size);
end
return
