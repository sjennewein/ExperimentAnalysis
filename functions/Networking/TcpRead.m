function message = TcpRead( tcpStream )
%TCPREAD This function reads the stream from a C# BinaryStreamWriter
%   The expected protocol looks like:
%   First byte tells the amount of bytes to read
%   All other bytes are payload

import java.net.Socket
import java.io.*


if(isa(tcpStream, 'java.net.SocketInputStream') == 0)
    message = 'Not the right data type!';
    return;
end

d_tcpStream = DataInputStream(tcpStream);

%maximum message is 256 byte at the moment
message = zeros(1,1024,'uint8');
run = 1;
totalBytesToRead = 0;
BytesRead = 0;
loopCycles = 0;
maxLoopCycles = 100;

%check buffer until all expected bytes are read
while(run == 1)
    bytesAvailable = tcpStream.available;
    
    %if new data is available read it
    if(bytesAvailable > 0)        
        
        %if it's the first packet arriving strip off the first
        %byte and retrieve the information about the length
        if(totalBytesToRead == 0)
            totalBytesToRead = d_tcpStream.readByte;
            bytesAvailable = bytesAvailable - 1;            
        end
        
        %read the data
        for i = 1:bytesAvailable
            message(BytesRead + i) = d_tcpStream.readByte;
        end        
        BytesRead = BytesRead + bytesAvailable;
        loopCycles = 0;
    end
    
    %check if all data has been read and you have tried at least
    %10 times to get data    
    if(BytesRead >= totalBytesToRead && loopCycles > 9)
        run = 0;
    end
    
    %makes sure that the loop is left after a certain 
    %amount of attempts to read data
    if(loopCycles > maxLoopCycles)
        run = 0;
    end
    
    loopCycles = loopCycles + 1;
end
message = char(message(1:totalBytesToRead));
end

