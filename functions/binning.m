function binned = binning( data, binsize )
%BINNING Bin data from TimeHarp
%   Detailed explanation goes here
binned = zeros(1,ceil(numel(data)/binsize));
count = 1;
for i=1:binsize:numel(data)
    tempData = 0;    
    for j=0:binsize
        if(i+j > numel(data))
            binsize = j;
            break;
        end
        tempData = tempData + data(i+j);        
    end
    tempData = tempData / binsize;    
    binned(count) = tempData;
    count = count + 1;
end

end

