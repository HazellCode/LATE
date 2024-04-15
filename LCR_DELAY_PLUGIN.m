classdef LCR_DELAY_PLUGIN < audioPlugin
    %   LCR_DELAY_PLUGIN 
    %   LCR Delay - Based on Korg Triton
    %   Publish Date: 15th April
    %   SID: 2105221
    %   Three delay lines that are configurable
    
    properties
        fs = 0; % This will be defined in the reset function;
        tmax = 2; % TMAX in seconds
        tmax_s = 0; % TMAX in samples
        ddlL = 0; % This will be set in the reset function
        ddlR = 0; % This will be set in the reset function
        ddlC = 0; % This will be set in the reset function

        idxL = 1; % Left Delay Sample Index
        idxR = 1; % Right Delay Sample Index
        idxC = 1; % Centre Delay Sample Index

        
        % user modifiable time delay settings with a maxmium value of tmax
        tdelL = 20;
        tdelR = 1;
        tdelC = 100;

        sdelL = 1000;   % Left Sample Delay
        sdelR = 2000;   % Right Sample Delay
        sdelC = 1500;   % Centre Sample Delay

        % Center DDL Settings
        CENTRE_FB = 0.8; % Feedback
        CENTRE_HPF = 0; % HPF Storage
        CENTRE_LPF = 0; % LPF Storage
        CENTRE_ENABLE_HPF = true; 
        CENTRE_ENABLE_LPF = false;

        % Dry wet Log;
        Left_DryWet = 0.8;
        Right_DryWet = 0.8;
        Centre_DryWet = 0.8;
        Left_DryWet_Log = 0; % Store D/W As Log
        Right_DryWet_Log = 0; % Store D/W As Log
        Centre_DryWet_Log = 0; % Store D/W As Log

        % DDL STATE
        enbL = true; % Enable Left Delay
        enbR = true; % Enable Right Delay
        enbC = true; % Enable Centre Delay

        
        HPF = 0; % HPF Object
        HPF_cutoff = 1000; % HPF Cutoff
        LPF = 0; % LPF Object
        LPF_cutoff = 4000; % LPF Object

        left_output_gain_db = 0; % Left Output Gain (dB)
        centre_output_gain_db = 0; % Centre Output Gain (dB)
        right_output_gain_db = 0; % Right Output Gain (dB)
        
        left_output_gain = 1; % Left Output Gain (Linear 0-1)
        centre_output_gain = 1; % Centre Output Gain (Linear 0-1)
        right_output_gain = 1; % Right Output Gain (Linear 0-1)

        swap_outputs = false; % Swap delay to opposite sides

        
       
    end
    properties (Constant)
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('tdelL', 'Mapping', {'int',1,2000},'DisplayName','Time Delay Left', 'Layout', [2,1], 'Style', 'rotaryknob', 'DisplayNameLocation', 'above','Label','ms'), ...
            audioPluginParameter('tdelC', 'Mapping', {'int',1,2000},'DisplayName','Time Delay Centre', 'Layout', [2,3], 'Style', 'rotaryknob', 'DisplayNameLocation', 'above','Label','ms'), ...
            audioPluginParameter('tdelR', 'Mapping', {'int',1,2000},'DisplayName','Time Delay Right', 'Layout', [2,5], 'Style', 'rotaryknob', 'DisplayNameLocation', 'above','Label','ms'), ...
            audioPluginParameter('enbL','DisplayName','Left Delay On/Off', 'Layout', [4,1], 'Style', 'vrocker'), ...
            audioPluginParameter('enbC','DisplayName','Centre Delay On/Off', 'Layout', [4,3],'Style', 'vrocker'), ...
            audioPluginParameter('enbR','DisplayName','Right Delay On/Off', 'Layout', [4,5], 'Style', 'vrocker'), ...
            audioPluginParameter('CENTRE_FB', 'Mapping', {'lin',0,1},'DisplayName','Centre Feedback Amount', 'Layout', [7,3], 'Style', 'hslider', 'DisplayNameLocation', 'above'), ...
            audioPluginParameter('HPF_cutoff', 'Mapping', {'log',20,8000},'DisplayName','HPF Cutoff', 'Layout', [9,1], 'Style', 'rotaryknob', 'DisplayNameLocation', 'below','Label','Hz'), ...
            audioPluginParameter('LPF_cutoff', 'Mapping', {'log',2000,20000},'DisplayName','LPF Cutoff', 'Layout', [9,5], 'Style', 'rotaryknob', 'DisplayNameLocation', 'below','Label','Hz'), ...
            audioPluginParameter('CENTRE_ENABLE_HPF','DisplayName','Enable Centre HPF','Layout', [11,2], 'Style', 'vrocker', 'DisplayNameLocation', 'left'), ...
            audioPluginParameter('CENTRE_ENABLE_LPF','DisplayName','Enable Centre LPF', 'Layout', [11,4], 'Style', 'vrocker', 'DisplayNameLocation', 'right'), ...
            audioPluginParameter('Left_DryWet', 'Mapping', {'lin',0,1},'DisplayName','Left Dry/Wet', 'Layout', [13,1], 'DisplayNameLocation', 'below'), ...
            audioPluginParameter('Centre_DryWet', 'Mapping', {'lin',0,1},'DisplayName','Centre Dry/Wet',  'Layout', [13,3], 'DisplayNameLocation', 'below'), ...
            audioPluginParameter('Right_DryWet', 'Mapping', {'lin',0,1},'DisplayName','Right Dry/Wet',  'Layout', [13,5], 'DisplayNameLocation', 'below'), ...
            audioPluginParameter('left_output_gain_db','Mapping',{'pow',1/3,-140,32},'DisplayName','Left Output Gain',  'Layout', [15,1],'Style','rotaryknob', 'DisplayNameLocation', 'below','Label','dB'), ...
            audioPluginParameter('centre_output_gain_db','Mapping',{'pow',1/3,-140,32},'DisplayName','Centre Output Gain',  'Layout', [15,3],'Style','rotaryknob', 'DisplayNameLocation', 'below','Label','dB'), ...
            audioPluginParameter('right_output_gain_db','Mapping',{'pow',1/3,-140,32},'DisplayName','Right Output Gain',  'Layout', [15,5],'Style','rotaryknob', 'DisplayNameLocation', 'below','Label','dB'), ...
            audioPluginParameter('swap_outputs','DisplayName','Swap L/R Delay', 'Layout', [17,3], 'Style', 'vrocker'), ...
            audioPluginGridLayout('RowHeight', [25,125,1,100,60,25,50,5,100,20,100,60,100,40,100,40,100,40], 'ColumnWidth', [150,25,150,25,150], 'RowSpacing', 0),...
            'VendorName', 'Hazell Design', 'PluginName', 'LATE', 'VendorVersion', '1.1.3', 'InputChannels',2,'OutputChannels',2);
        
        % This is used to configure the UI with parameters
        % Each parameter will have:
        %  - name
        % - parameter to control
        % - scale
        % - position
        % -ui element style

    end
    properties (Dependent)
       
    end 
    methods
        function plugin = LCR_DELAY_PLUGIN()
            % Define HPF and LPF at plugin startup
            plugin.HPF = BW2(plugin.HPF_cutoff, 192000, "HPF");
            plugin.LPF = BW2(plugin.LPF_cutoff, 192000, "LPF");
        end 
        function out = process(plugin,in)
            % define length of buffer
            [N,M] = size(in);
            % Create output array
            out = zeros(N,M);
            % buffer time loop
            for n = 1:N
                % Inputs for delays
                LEFT = in(n,1);
                RIGHT = in(n,2);
                CENTRE = (LEFT + RIGHT) / 2; 
                
                if plugin.swap_outputs
                    % Put the left delay on the right channel and the right
                    % delay on the left channel

                    if plugin.enbL
                        % Is Left Delay Is Enabled add to DDL
                        LEFT_DEL = (plugin.ddlL(plugin.idxL));
                        plugin.ddlL(plugin.idxL) = LEFT;
                    else
                        % ensure variable is created even if Delay is
                        % disabled
                        LEFT_DEL = 0;
                    end

                    if plugin.enbR
                        % Is Right Delay Is Enabled add to DDL
                        RIGHT_DEL = (plugin.ddlR(plugin.idxR));
                        plugin.ddlR(plugin.idxR) = RIGHT;
                    else
                        % ensure variable is created even if Delay is
                        % disabled
                        RIGHT_DEL = 0;
                    end

                    if plugin.enbL && plugin.enbR
                        % IF LEFT AND RIGHT ARE ENABLED
                        % both sides swap
                        LEFT_OUTPUT = (RIGHT_DEL * (plugin.Right_DryWet_Log)) + (LEFT * (1-plugin.Left_DryWet_Log));
                        RIGHT_OUTPUT = (LEFT_DEL * (plugin.Left_DryWet_Log)) + (RIGHT * (1-plugin.Right_DryWet_Log));
                    elseif plugin.enbL && (~plugin.enbR)
                        % IF LEFT AND NOT RIGHT ARE ENABLED
                        % swap left onto right
                        LEFT_OUTPUT = LEFT;
                        RIGHT_OUTPUT = (LEFT_DEL * (plugin.Left_DryWet_Log)) + (RIGHT * (1-plugin.Right_DryWet_Log));
                    elseif (~plugin.enbL) && plugin.enbR
                        % IF NOT LEFT AND RIGHT ARE ENABLED
                        % swap right onto left
                        RIGHT_OUTPUT = RIGHT;
                        LEFT_OUTPUT = (RIGHT_DEL * (plugin.Right_DryWet_Log)) + (LEFT * (1-plugin.Left_DryWet_Log));
                    else
                        % IF NONE ARE ENABLED
                        LEFT_OUTPUT = LEFT;
                        RIGHT_OUTPUT= RIGHT;
                    end
                    
                else
                    if plugin.enbL
                        % If Left is enabled
                        LEFT_OUTPUT = (plugin.ddlL(plugin.idxL) * (plugin.Left_DryWet_Log)) + (LEFT * (1-plugin.Left_DryWet_Log));
                        plugin.ddlL(plugin.idxL) = LEFT;
                    else
                        % otherwise LEFT input passes straight through
                        LEFT_OUTPUT = LEFT;
                    end


                    if plugin.enbR
                        % If Right is enabled
                        RIGHT_OUTPUT = (plugin.ddlR(plugin.idxR) * (plugin.Right_DryWet_Log)) + (RIGHT * (1-plugin.Right_DryWet_Log));
                        plugin.ddlR(plugin.idxR) = RIGHT;
                    else
                        % otherwise RIGHT input passes straight through
                        RIGHT_OUTPUT = RIGHT;
                    end
                end
                
                
                if plugin.enbC
                    % If centre is enabled
                    % Centre Output
                    CENTRE_OUTPUT = (plugin.ddlC(plugin.idxC) * (plugin.Centre_DryWet_Log)) + (CENTRE * (1-plugin.Centre_DryWet_Log));
                    % Store last centre output for fb line
                    CENTRE_LAST = plugin.ddlC(plugin.idxC) * plugin.CENTRE_FB; 

                    % If HPF Enabled
                    if plugin.CENTRE_ENABLE_HPF
                        % Calculate HPF
                        plugin.CENTRE_HPF = plugin.HPF.calculate(CENTRE_LAST);
                        
                    else
                        % Otherwise pass through
                        plugin.CENTRE_HPF = CENTRE_LAST;
                    end
                    % If LPF enabled
                    if plugin.CENTRE_ENABLE_LPF
                        % Calculate LPF
                        plugin.CENTRE_LPF = plugin.LPF.calculate(plugin.CENTRE_HPF);
                    else
                        % Otherwise pass through
                        plugin.CENTRE_LPF = plugin.CENTRE_HPF;
                    end
                else
                    % Otherwise pass through
                    CENTRE_OUTPUT = CENTRE;
                end
                
                % Apply output gain to the outputs
                LEFT_OUTPUT = LEFT_OUTPUT * plugin.left_output_gain;
                CENTRE_OUTPUT = CENTRE_OUTPUT * plugin.centre_output_gain;
                RIGHT_OUTPUT = RIGHT_OUTPUT * plugin.right_output_gain;

                
                % Place centre output in delay line
                plugin.ddlC(plugin.idxC) = CENTRE + (plugin.CENTRE_LPF);


                % OUTPUT
                out(n,1) = (LEFT_OUTPUT * 0.5) + (CENTRE_OUTPUT * 0.5);
                out(n,2) = (RIGHT_OUTPUT * 0.5) + (CENTRE_OUTPUT * 0.5);
                
                
                

                %% INCREMENTORS - increments delay lines
                plugin.idxL = plugin.idxL + 1;
                if plugin.idxL > plugin.sdelL
                    plugin.idxL = 1; 
                end

                plugin.idxR = plugin.idxR + 1;
                if plugin.idxR > plugin.sdelR
                    plugin.idxR = 1; 
                end

                plugin.idxC = plugin.idxC + 1;
                if plugin.idxC > plugin.sdelC
                    plugin.idxC = 1; 
                end

            end

               
        end

        %% ON PARAMETER CHANGE
        function set.HPF_cutoff(plugin, val)
            plugin.HPF_cutoff = val;
            % Update Cutoff
            plugin.HPF.update(plugin.HPF_cutoff,plugin.fs)
        end

        function set.LPF_cutoff(plugin, val)
            plugin.LPF_cutoff = val;
            % Update Cutoff
            plugin.LPF.update(plugin.LPF_cutoff,plugin.fs)
        end

        function set.tdelL(plugin, val)
            plugin.tdelL = val;
            % Update Time Delay
            plugin.sdelL = round((plugin.tdelL/1000) * plugin.fs);
        end

        function set.tdelR(plugin, val)
            plugin.tdelR = val;
            % Update Time Delay
            plugin.sdelR = round((plugin.tdelR/1000) * plugin.fs);
        end

        function set.tdelC(plugin, val)
            plugin.tdelC = val;
            % Update Time Delay
            plugin.sdelC = round((plugin.tdelC/1000) * plugin.fs);
        end

        function set.Left_DryWet(plugin, val)
            plugin.Left_DryWet = val;
            % Calculate DryWet Log
            plugin.Left_DryWet_Log = (.001*10^(3*plugin.Left_DryWet));
        end

        function set.Right_DryWet(plugin, val)
            plugin.Right_DryWet = val;
            % Calculate DryWet Log
            plugin.Right_DryWet_Log = (.001*10^(3*plugin.Right_DryWet));
        end

        function set.Centre_DryWet(plugin, val)
            plugin.Centre_DryWet = val;
            % Calculate DryWet Log
            plugin.Centre_DryWet_Log = (.001*10^(3*plugin.Centre_DryWet));
        end

        function set.left_output_gain_db(plugin,val)
            plugin.left_output_gain_db = val;
            % Recalculate output gain
            plugin.left_output_gain = 10^(plugin.left_output_gain_db/20);
        end
        
        function set.centre_output_gain_db(plugin,val)
            plugin.centre_output_gain_db = val;
            % Recalculate output gain
            plugin.centre_output_gain = 10^(plugin.centre_output_gain_db/20);
        end

        function set.right_output_gain_db(plugin,val)
            plugin.right_output_gain_db = val;
            % Recalculate output gain
            plugin.right_output_gain = 10^(plugin.right_output_gain_db/20);
        end


       


        

        function reset(plugin)
            plugin.fs = getSampleRate(plugin); % Set Sample Rate
            plugin.tmax_s = plugin.tmax * plugin.fs; % Convert TMAX from seconds to samples

            %% DEFINE THE LENGTH OF THE DELAY LINES 
            % This logic will make sure that reglardless of the sample rate
            % the plugin will always allow for the sample delay length.
            plugin.ddlL = zeros(plugin.fs*2,1);
            plugin.ddlR = zeros(plugin.fs*2,1);
            plugin.ddlC = zeros(plugin.fs*2,1);


            % Define the Filters
            % Inital values set - will have to recalcualte everytime the
            % paramter is changed.
            % https://uk.mathworks.com/help/audio/ug/tips-and-tricks-for-plugin-authoring.html
            plugin.HPF.update(1000,plugin.fs) 
            plugin.LPF.update(4000,plugin.fs)
            
            plugin.Left_DryWet_Log = (.001*10^(3*plugin.Left_DryWet));
            plugin.Right_DryWet_Log = (.001*10^(3*plugin.Right_DryWet));
            
            % Calculate sample delay on startup
            plugin.sdelL = round((plugin.tdelL/1000) * plugin.fs);
            plugin.sdelR = round((plugin.tdelR/1000) * plugin.fs);
            plugin.sdelC = round((plugin.tdelC/1000) * plugin.fs);
            
        end
    end
end

