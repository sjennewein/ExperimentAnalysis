function message = TcpRead( tcpStream )
%TCPREAD This function reads the stream from a C# BinaryStreamWriter
%   The expected protocol looks like:
%   First byte tells the amount of bytes to read
%   All other bytes are payload

import java.net.Socket
import java.io.*


if(isa(tcpStream, 'java.net.SocketInputStream') == 0)
    message = 'Not the right Datatype!';
    return;
end

d_tcpStream = DataInputStream(tcpStream);

%maximum message is 4kB at the moment
message = zeros(1,4096,'uint8');
run = 1;
totalBytesToRead = 0;
BytesRead = 0;

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
    end
    
    %check if all data has been read
    if(BytesRead == totalBytesToRead )
        run = 0;
    end
end
message = char(message(1:totalBytesToRead));
end

