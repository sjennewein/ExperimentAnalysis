function content = readThd(fileName)
%READTHD Read interactive file from TimeHarp
%
fid = fopen(fileName);

content = struct();
content.Ident = char(fread(fid,16,'char'));
content.FormatVersion = deblank(char(fread(fid,6, 'char')));


content.CreatorName = char(fread(fid, 18, 'char'));
content.CreatorVersion = char(fread(fid, 12, 'char'));
content.FileTime = char(fread(fid, 18, 'char'));
content.CRLF = char(fread(fid, 2, 'char'));
content.Comment = char(fread(fid, 256, 'char'));
content.NumberOfChannels = fread(fid, 1, 'int32');
content.NumberOfCurves = fread(fid, 1, 'int32');
content.BitsPerChannel = fread(fid, 1, 'int32');
content.RoutingChannels = fread(fid, 1, 'int32');
content.NumberOfBoards = fread(fid, 1, 'int32');
content.ActiveCurve = fread(fid, 1, 'int32');
content.MeasurementMode = fread(fid, 1, 'int32');
content.SubMode = fread(fid, 1, 'int32');
content.RangeNo = fread(fid, 1, 'int32');
content.Offset = fread(fid, 1, 'int32');
content.AcquisitionTime = fread(fid, 1, 'int32');
content.StopAt = fread(fid, 1, 'int32');
content.StopOnOvfl = fread(fid, 1, 'int32');
content.Restart = fread(fid, 1, 'int32');
content.DispLinLog = fread(fid, 1, 'int32');
content.DispTimeAxisFrom = fread(fid, 1, 'int32');
content.DispTimeAxisTo = fread(fid, 1, 'int32');
content.DispCountAxisFrom = fread(fid, 1, 'int32');
content.DispCountAxisTo = fread(fid, 1, 'int32');
for i = 1:8
    content.DispCurveMapTo(i) = fread(fid, 1, 'int32');
    content.DispCurveShow(i) = fread(fid, 1, 'int32');
end;
for i = 1:3
    content.ParamStart(i) = fread(fid, 1, 'float');
    content.ParamStep(i) = fread(fid, 1, 'float');
    content.ParamEnd(i) = fread(fid, 1, 'float');
end;
content.RepeatMode = fread(fid, 1, 'int32');
content.RepeatsPerCurve = fread(fid, 1, 'int32');
content.RepeatTime = fread(fid, 1, 'int32');
content.RepeatWait = fread(fid, 1, 'int32');
content.ScriptName = char(fread(fid, 20, 'char'));
content.HardwareIdent = char(fread(fid, 16, 'char'));
content.HardwareVersion = char(fread(fid, 8, 'char'));
content.Board_BoardSerial = fread(fid, 1, 'int32');
content.Board_CFDZeroCross = fread(fid, 1, 'int32');
content.Board_CFDDiscriminatorMin = fread(fid, 1, 'int32');
content.Board_SYNCLevel = fread(fid, 1, 'int32');
content.Board_CurveOffset = fread(fid, 1, 'int32');
content.Board_Resolution = fread(fid, 1, 'float');

for i = 1:content.NumberOfCurves
    content.CurveIndex(i) = fread(fid, 1, 'int32');
    TimeOfRecording(i) = fread(fid, 1, 'uint');
    TimeOfRecording(i) = TimeOfRecording(i)/24/60/60+25569+693960;
    content.TimeOfRecording(i) = TimeOfRecording(i);
    content.BoardSerial(i) = fread(fid, 1, 'int32');
    content.CFDZeroCross(i) = fread(fid, 1, 'int32');
    content.CFDDiscriminatorMin(i) = fread(fid, 1, 'int32');
    content.SYNCLevel(i) = fread(fid, 1, 'int32');
    content.CurveOffset(i) = fread(fid, 1, 'int32');
    content.RoutingChannel(i) = fread(fid, 1, 'int32');
    content.SubMode(i) = fread(fid, 1, 'int32');
    content.MeasMode(i) = fread(fid, 1, 'int32');
    content.P1(i) = fread(fid, 1, 'float');
    content.P2(i) = fread(fid, 1, 'float');
    content.P3(i) = fread(fid, 1, 'float');
    content.RangeNo(i) = fread(fid, 1, 'int32');
    content.Offset(i) = fread(fid, 1, 'int32');
    content.AcquisitionTime(i) = fread(fid, 1, 'int32');
    content.StopAfter(i) = fread(fid, 1, 'int32');
    content.StopReason(i) = fread(fid, 1, 'int32');
    content.SyncRate(i) = fread(fid, 1, 'int32');
    content.CFDCountRate(i) = fread(fid, 1, 'int32');
    content.TDCCountRate(i) = fread(fid, 1, 'int32');
    content.IntegralCount(i) = fread(fid, 1, 'int32');
    content.Resolution(i) = fread(fid, 1, 'float');
    content.Extdev(i) = fread(fid, 1, 'int32');
    content.Reserved(i) = fread(fid, 1, 'int32');
    
    for j = 1:content.NumberOfChannels
        content.Counts(i,j) = fread(fid, 1, 'uint32');
    end;    
end;
end


