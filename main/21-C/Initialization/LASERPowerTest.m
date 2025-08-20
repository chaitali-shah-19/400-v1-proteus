LPW = 0.4;
fileID = fopen('CurLaserPW.txt','w');
fprintf(fileID,'%.2f\n',LPW);
fclose(fileID);
py.Clicker.LPWAD(LPW);
