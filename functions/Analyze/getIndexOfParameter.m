function index = getIndexOfParameter( parameterName, parameterList )
%getIndexOfParameter returns the index of the named parameter
    if(~iscell(parameterList))
        error('parameterList must be a cell vector!');
    end
    
    index = 0;
    for iParameter = 1:numel(parameterList)
        if(strcmp(parameterList{iParameter}, parameterName))
            index = iParameter;
            break;
        end
    end
    if(index == 0)
        error('Parameter not found');
    end    

end

