%  Maxwell McAllister, 10/15/2020
%  Send script, for Automizer, aka Host 1
%  For communication between PCs, replace '127.0.0.1' with
% the DNS or DHCP (?) host name or IP address of Host 2
u1 = udp('192.168.0.154', 'RemotePort', 9090, 'LocalPort', 2020);
fopen(u1); % open the port
% Loop to send messages; wait for response before going on
n = 10;
for (k = 1:n)
    % Send a message - k cast to uint8
    fwrite(u1, k);
    disp('Sent: "' + string(k) + '"') % debug
    % **Wait for reply before starting next cycle**
    while(u1.BytesAvailable == 0)
        % If no bytes in u1 buffer, wait 10ms then check again
        pause(0.01);
    end
    % Bytes now available - a reply has arrived
    host2Bytes = fread(u1);
    % Display the reply
    disp('Received:')
    disp( string(host2Bytes) )
    disp('')
    pause(2)  % delay for visibility
end

fclose(u1); % close the port when you're fully done with it