function message = TcpRead( tcpStream )
%TCPREAD This function reads the stream from C# 
%   The expected protocol looks like:
%   First 4 byte tells the amount of bytes to read
%   All other bytes are payload

import java.net.Socket
import java.io.*

if(isa(tcpStream, 'java.net.SocketInputStream') == 0)
    message = 'Not the right data type!';
    return;
end

d_tcpStream = DataInputStream(tcpStream);

header = zeros(1,4,'uint8');
BytesRead = 1;

% read the header of the packet
while(BytesRead < 4)
    BytesAvailable = tcpStream.available;
    if(BytesAvailable > 0)
        header(BytesRead) =  abs(d_tcpStream.readByte);
        BytesRead = BytesRead + 1;
    end       
end

%it seems that there are null byte terminations so here we read it
 d_tcpStream.readByte;

BytesRead = 1;
totalBytesToRead = typecast(header, 'uint32');
message = zeros(1,totalBytesToRead,'uint8');

%check buffer until all expected bytes are read
while(BytesRead < totalBytesToRead + 1)
    BytesAvailable = tcpStream.available;    
    %read the data         
    if(BytesAvailable > 0)        
        message(BytesRead) = d_tcpStream.readByte;
        BytesRead = BytesRead + 1;      
    end
end

message = char(message(1:totalBytesToRead ));
end