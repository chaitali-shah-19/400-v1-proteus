      
% It is recommended to disconnect from instrumet at the end
    rc = admin.CloseInstrument(instId);
    
    % Close the administrator at the end ...
    admin.Close();