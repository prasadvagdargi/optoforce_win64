function magnitude_opto(t)
close all;
if strcmp(computer('arch'),'win32'),     addpath '.\mex_files\32bit'; end      % If the MATLAB is 32bit
if strcmp(computer('arch'),'win64'),     addpath '.\mex_files\64bit'; end      % If the MATLAB is 64bit

ports = OptoPorts(3);                   % For 3 axis sensors - Get an instance of the OptoPorts class (3 - only 3D sensors; 6 - only 6D sensors )

version = ports.getAPIversion;          % Get the API version (Major,Minor,Revision,Build)
pause(1)                                % To be sure about OptoPorts enumerated the sensor(s)
available_ports = ports.listPorts;      % Get the list of the available ports
if (isempty(available_ports)), disp('No DAQ is connected...'); else disp(available_ports);end;

if (ports.getLastSize()>0),             % Is there at least 1 available port?
    
    port = available_ports(1,:);        % If at least 1 port is available then select the first one
    
    daq = OptoDAQ();                    % Get an instance of the OptoDAQ class (this class handles the actual sensor reading)
    isOpen = daq.open(port,0);          % Open the previously selected port (the second argument:  0 - high-speed mode; 1 - slower debug mode)
    
    if (isOpen==1),
        
        speed = 1000;                   % Set the required DAQ's internal sampling speed (valid options: 1000Hz,333Hz, 100Hz, 30Hz)
        filter = 50;                    % Set the required DAQ's internal filtering-cutoff frequency (valid options: 0(No filtering),150Hz,50Hz, 15Hz)
        daq.sendConfig(speed,filter);   % Sends the required configuration
        
        channel = 1;                    % Some DAQ support multi-channel, othwerwise it must be 1
        output = daq.read3D(channel);   % For 3 axis sensors - Reads all the available samples (output.size) to empty the buffer
        %output = daq.read6D();         % For 6 axis sensors - Reads all the available samples (output.size) to empty the buffer
        
        elapsed_time = 0; received_samples = 0; n = 1;
        
        bias = [mean(output.Fx) mean(output.Fy) mean(output.Fz)];   % Initialize the variables
        F=[0 0 0];
        magBias=sqrt(F(end,1).^2+F(end,2).^2+F(end,3).^2);
        mag=0;
        
        f=figure;
        time_log(1)=0;
        % Create axes
        axes1 = axes('Parent',f);
        box(axes1,'on');
        grid(axes1,'on');
        hold(axes1,'on');
        
        px=plot(F(:,1),'r');
        hold on;
        py=plot(F(:,2),'g');
        pz=plot(F(:,3),'b');
        pmag=plot(mag,'k');
        
        
        
        % Create xlabel
        xlabel('Time (in s)');
        
        % Create ylabel
        ylabel('Force (in g.f.)');
        
        % Create title
        title('Optoforce Sensor readings');
        
        % Create legend
        legend1 = legend(axes1,'show');
        set(legend1,'Position',[0.915104166666666 0.77257525083612 0.0612839583980666 0.146599777034559]);
        
        set(px,'DisplayName','Fx','Color',[1 0 0]);
        set(py,'DisplayName','Fy','Color',[0 1 0]);
        set(pz,'DisplayName','Fz','Color',[0 0 1]);
        set(pmag,'DisplayName','Magnitude','Color',[0 0 0]);
        
        tic;
        
        while (toc<t && output.size>=0 ),        % Loop for 10sec (quit if any error)
            n = n+1;
            time_log(n)=toc;
            output = daq.read3D(channel);   % For 3 axis sensors - Reads all the available samples (output.size)
            %output = daq.read6D();         % For 6 axis sensors - Reads all the available samples (output.size)
            
            if (output.size==-2), disp('The DAQ has been disconnected... '); end;
            if (output.size==-3), disp('The selected DAQ channel does not exist... ');  end;
            
            % For 3 axis sensors - Display the most current Fx,Fy,Fz sensor values (all are in Counts, refer to the sensitivity report to convert it to N.)
            %[ output.Fx(end) output.Fy(end) output.Fz(end) ]
            
            % For 6 axis sensors - Display the most current Fx,Fy,Fz,Tx,Ty,Tz sensor values (all are in Counts, refer to the sensitivity report to convert it to N/Nm.)
            %[ output.Fx(end) output.Fy(end) output.Fz(end) output.Tx(end) output.Ty(end) output.Tz(end) ]
            
            F = [F;mean(output.Fx)-bias(1) mean(output.Fy)-bias(2) mean(output.Fz)-bias(3)];            % Fz stores all the received samples of output.Fz
            force=sqrt(F(end,1).^2+F(end,2).^2+F(end,3).^2)
            mag=[mag force];
            px.YData=F(:,1);
            py.YData=F(:,2);
            pz.YData=F(:,3);
            pmag.YData=mag;
            %
            px.XData=time_log;
            py.XData=time_log;
            pz.XData=time_log;
            pmag.XData=time_log;
            grid on;
            pause(0.001);
            %             loop_time =(toc(t0)-elapsed_time) * 1000;               % The current time required the loop to be iterated (should be 1000/sample_rate + 1-2 ms) without pause
            %            elapsed_time = toc(t0);                                 % Elapsed time since the beginning of the code
            %             received_samples = received_samples + output.size;      % All samples received since the beginning of the code
            %             sample_rate = received_samples / elapsed_time;          % Average sample rate since the beginning of the code (current received sample rate may by slower or faster due to the OS)
            %             fprintf('Elapsed time = %3.5f sec        Received samples =%7.0f        Sample rate (avarage) = %4.0f Hz       Current loop time  = %3.3f ms\n',elapsed_time,received_samples,sample_rate, loop_time);
            %
        end
        
        daq.close();                    % Close the already opened DAQ
        
    else
        disp('The DAQ could not be opened');
    end
    
end

clear daq;                              % Destroy the OptoDAQ class
clear ports;                            % Destroy the OptoPorts class