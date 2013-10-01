function status= TcpWrite( tcpStream, message )
%TCPWRITE Writes the protocol expected by a C# BinaryStreamReader
%   The expected protocol looks like:
%   First byte tells the amount of bytes to read
%   All other bytes are payload

import java.net.Socket
import java.io.*


if(isa(tcpStream, 'java.net.SocketOutputStream') == 0)
    disp('error');
    status = 0;
    return;
end

d_TcpStream = DataOutputStream(tcpStream);

%get the length of the payload in byte and put it in the first
%of the message
message = strcat(char(numel(message)),message);

%send message
d_TcpStream.writeBytes(char(message));
d_TcpStream.flush;

status = 1;
end

