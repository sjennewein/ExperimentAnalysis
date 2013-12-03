function [ folder ] = FolderOfTheDay( )
%FOLDEROFTHEDAY Summary of this function goes here
%   Detailed explanation goes here
    namedMonth = {'Janvier' 'Fevrier' 'Mars' ...
                  'Avril' 'Mai' 'Juin' 'Juillet' ...
                  'Aout' 'Septembre' 'Octobre' ...
                  'Novembre' 'Decembre'};
    base = 'D:\Manipe';
    datetime = num2cell(clock);
    [year month day hour minute second] = datetime{:};
    folder = strcat(base, '\', int2str(year),'\', namedMonth{month}, '\', ...
             int2str(year), int2str(month), int2str(day), '\');
         
    if(exist(folder,'dir') ~= 7)
        mkdir(folder);
    end
end

