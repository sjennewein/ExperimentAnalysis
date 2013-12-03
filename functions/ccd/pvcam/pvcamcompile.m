function [] = pvcamcompile(source_path)

% PVCAMCOMPILE - script to compile PVCAM DLLs
%
%    PVCAMCOMPILE(PATH) compiles the PVCAM code in the source directory.

% 3/9/07 SCM

if (nargin ~= 1)
    warning('MATLAB:pvcamcompile', 'type ''help pvcamcompile'' for syntax');
    return
elseif (~exist(source_path, 'dir'))
    warning('MATLAB:pvcamcompile', 'path %s does not exist', source_path);
    return
end

% compile files
old_path = pwd;
cd(source_path)
file_list = {'pvcamacq', 'pvcamclose', 'pvcamget', 'pvcamicl', 'pvcamopen', 'pvcamset', 'pvcamshutter'};
for i = 1 : length(file_list)
    cell_args = {sprintf('-L%s', source_path), '-lpvcam32'};
    if (strcmp(file_list{i}, 'pvcamicl'))
        cell_args{end + 1} = '-lpv_icl32';
    end
    
    % to compile the modified pvcamacq you need to enter 
    % mex -v -L -lpvcam32 pvcamacq.c pvcamutil.c "C:\Program Files\MATLAB\R2011b\extern\lib\win32\microsoft\libut.lib"
    
    %cell_args{end + 1} = '-output';
    %cell_args{end + 1} = sprintf('%s.dll', file_list{i});
    cell_args{end + 1} = sprintf('%s.c', file_list{i});
    cell_args{end + 1} = 'pvcamutil.c';
    cell_args
    mex( cell_args{:});
end
cd(old_path)
return
