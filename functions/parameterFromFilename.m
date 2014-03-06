function  [names, values, units]  = parameterFromFilename( filename )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    
    input = lower(filename);
    [~,name,~] = fileparts(input);
    
    delimited = strsplit(name,'_');
    headerLength = numel(delimited{1}) + 1;
    parameterList = name(headerLength:end);
    parameters = regexpi(parameterList, '(_\w+?_\d+?(\.?\d+?)*[a-zµ]+)','tokens');
    
    names = cell(1,numel(parameters));
    values = zeros(1,numel(parameters));
    units = cell(1,numel(parameters));
    
    for i = 1:numel(parameters)
        match = regexpi(parameters{i},'_(\w+?)_(\d+?(\.?\d+?)*)([a-zµ]+)','tokens');
        names{i} = match{1}{1}{1};
        values(i) = str2double(match{1}{1}{2});
        units{i} = match{1}{1}{3};
    end
end

