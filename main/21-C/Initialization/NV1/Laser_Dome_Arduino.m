classdef Laser_Dome_Arduino
    properties
        arduinoCom1
        arduinoCom2
        arduinoCom3
        port_name1
        port_name2
        port_name3
    end
    methods

        function obj=Laser_Dome_Arduino(port_name1,port_name2,port_name3)
            obj.arduinoCom1 = serial(port_name1,'BaudRate',9600);
            obj.arduinoCom2 = serial(port_name2,'BaudRate',9600);
            obj.arduinoCom3 = serial(port_name3,'BaudRate',9600);
            fopen(obj.arduinoCom1);
            fopen(obj.arduinoCom2);
            fopen(obj.arduinoCom3);
        end

        function all_lasers_off(obj)
            mastervectorboard1 = [1 0 0 0 0 0 0 0 0 0 0 0 0];
            mastervectorboard2 = [2 0 0 0 0 0 0 0 0 0 0 0 0];
            mastervectorboard3 = [3 0 0 0 0 0 0 0 0 0 0 0 0];
            disp ('Turning off Lasers');
            obj.send_arduino(mastervectorboard1,mastervectorboard2,mastervectorboard3);
        end

        function send_arduino(obj,x1,x2,x3)
            string_nospaces = strrep(mat2str(x1),' ','');
            sendData1 = strcat('<', string_nospaces(3:14), '>');
            string_nospaces = strrep(mat2str(x2),' ','');
            sendData2 = strcat('<', string_nospaces(3:14), '>');
            string_nospaces = strrep(mat2str(x3),' ','');
            sendData3 = strcat('<', string_nospaces(3:14), '>');    
            fprintf(obj.arduinoCom1,'%s',sendData1);
            las1=fscanf(obj.arduinoCom1);
            fprintf(obj.arduinoCom2,'%s',sendData2);
            las2=fscanf(obj.arduinoCom2);           
            fprintf(obj.arduinoCom3,'%s',sendData3);
            las3=fscanf(obj.arduinoCom3);
        end

        function read_arduino(obj)
            las1=fscanf(obj.arduinoCom1);
            pause(1);
            las2=fscanf(obj.arduinoCom2);
            pause(1);
            las3=fscanf(obj.arduinoCom3);
            pause(1);
            disp(['Laser Board 1:' las1 '\n']);
            disp(['Laser Board 2:' las2 '\n']);
            disp(['Laser Board 3:' las3 '\n']);
        end

        function close_arduino(obj)
            serialObj = instrfind;
            s=size(serialObj);
            for i=1:s(1,2)
                fclose(serialObj(i));
            end
        end

        function read_laserdomegui(obj, laser_count)
            if laser_count < 43
                mastervectorboard1 = [1 0 0 0 0 0 0 0 0 0 0 0 0];
                mastervectorboard2 = [2 0 0 0 0 0 0 0 0 0 0 0 0];
                mastervectorboard3 = [3 0 0 0 0 0 0 0 0 0 0 0 0];
                msglaserdome = 'Reading Laser Dome GUI';
                disp(msglaserdome)
                load('boardconfig.mat');
                mastervectorboard1;
                mastervectorboard2;
                mastervectorboard3;
            end
            obj.send_arduino(mastervectorboard1,mastervectorboard2,mastervectorboard3);
        end
        
        function lasernumber(obj, laser_num)
%             global brokenLasers
%             brokenLasers = 0;
            mat = [1 0 0 0 0 0 0 0 0 0 0 0 0; 
                   2 0 0 0 0 0 0 0 0 0 0 0 0; 
                   3 0 0 0 0 0 0 0 0 0 0 0 0];
            disp ('Turning ON Laser');
                for i = laser_num
%                     if (ismember(i, brokenLasers))
%                         continue
%                     end
                    fid = fopen('lasernumbers_v1.txt');
                    C = cell2mat(textscan(fid,'%d'));
                    boardnum = C(2*i - 1);
                    lasernum = C(2*i);
                    mat(boardnum, lasernum + 1) = 1;
                end
            mastervectorboard1 = mat(1,:);
            mastervectorboard2 = mat(2,:);
            mastervectorboard3 = mat(3,:);
            obj.send_arduino(mastervectorboard1, mastervectorboard2, mastervectorboard3);
        end
        
        function orderlasers(obj, laser_count)
%             global brokenLasers
            mat = [1 0 0 0 0 0 0 0 0 0 0 0 0; 
                   2 0 0 0 0 0 0 0 0 0 0 0 0; 
                   3 0 0 0 0 0 0 0 0 0 0 0 0];
            disp ('Turning ON Laser');
                for i = 1:laser_count
%                     if (ismember(i, brokenLasers))
%                         continue
%                     end
                    fid = fopen('lasernumbers_v1.txt');
                    C = cell2mat(textscan(fid,'%d'));
                    boardnum = C(2*i - 1);
                    lasernum = C(2*i);
                    mat(boardnum, lasernum + 1) = 1;
                end
            mastervectorboard1 = mat(1,:);
            mastervectorboard2 = mat(2,:);
            mastervectorboard3 = mat(3,:);
            obj.send_arduino(mastervectorboard1, mastervectorboard2, mastervectorboard3);
        end
    end
end