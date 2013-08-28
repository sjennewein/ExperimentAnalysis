function content = readDat(fileName)
% Read .dat file 
%
fid = fopen(fileName);
content = struct();
content.test = fread(fid, 10, 'float');

end