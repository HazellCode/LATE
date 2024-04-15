classdef BW2 < handle
    % Bi Quad Filters
    % Using Will Pirkles Filter Design (11.3.2.4) - Desiging Audio Effect
    % Plugins
    properties (Access=public)
        fc = 0; % cutoff
        fs = 0; % sample rate
        % Filter Coefficient Storage Values
         C = 0; 
        a0 = 0;
        a1 = 0;
        a2 = 0;
        b1 = 0;
        b2 = 0;
        c0 = 0;
        d0 = 0;
        theta = 0;
        omega = 0;
        k = 0;
        delta = 0;


        x = 0;
        % Delay lines
        ddl1 = 0;
        ddl2 = 0;
        ddl3 = 0;
        ddl4 = 0;
        % Filter Type storage
        filter_type = '';
    end
    methods
        function obj = BW2(fc_in,fs_in, filter_type)
            % define filter type
            obj.filter_type = filter_type;
            % calculate coefficients
            obj.update(fc_in,fs_in);

            
            
        end
        
        function out = calculate(obj, x_in)
            % Run every block cycle - calcualte filter
            out = (x_in * obj.a0) + (obj.a1 * obj.ddl1) + (obj.a2 * obj.ddl2) -(obj.b1 * obj.ddl3) -(obj.b2*obj.ddl4);
            obj.ddl2 = obj.ddl1;
            obj.ddl1 = x_in;
            obj.ddl4 = obj.ddl3;
            obj.ddl3 = out;
        end
        

        function update(obj, fc_in,fs_in)
            obj.fc = fc_in;
            obj.fs = fs_in;
            % Set the Coefficients
            if obj.filter_type == "HPF"
                % DEFINE COEFFICIENTS FOR THE HIGH PASS FILTER
                obj.C = tan((pi * obj.fc) / obj.fs);
                obj.a0 = 1 / (1 + (sqrt(2) * obj.C) + obj.C^2);
                obj.a1 = (-2 * obj.a0);
                obj.a2 = obj.a0;
                obj.b1 = 2 * obj.a0 * (obj.C^2 - 1);
                obj.b2 = obj.a0 * (1 - (sqrt(2) * obj.C) + obj.C^2);
                obj.c0 = 1.0;
                obj.d0 = 0;
            elseif obj.filter_type == "LPF"
                % DEFINE COEFFICIENTS FOR THE LOW PASS FILTER
                obj.C = 1 / tan((pi * obj.fc) / obj.fs);
                obj.a0 = 1 / (1 + (sqrt(2) * obj.C) + obj.C^2);
                obj.a1 = (2 * obj.a0);
                obj.a2 = obj.a0;
                obj.b1 = 2 * obj.a0 * (1 - obj.C^2);
                obj.b2 = obj.a0 * (1 - (sqrt(2) * obj.C) + obj.C^2);
                obj.c0 = 1.0;
                obj.d0 = 0;
            elseif obj.filter_type == "HPF_LR4"
                % LR4 Filter - NOT USED
                obj.theta = (pi * obj.fc) / obj.fs;
                obj.omega = pi * obj.fc;
                obj.k = obj.omega / tan(obj.theta);
                obj.delta = (obj.k^2) + (obj.omega^2) + 2*obj.k*obj.omega;
                obj.a0 = (obj.k^2) / obj.delta;
                obj.a1 = (-2*(obj.k^2)) / obj.delta;
                obj.a2 = (obj.k^2) / obj.delta;
                obj.b1 = ((-2 * (obj.k^2)) + (2*(obj.omega^2))) / obj.delta;
                obj.b2 = ((-2*obj.k*obj.omega) + (obj.k^2) + (obj.omega^2)) / obj.delta;
                obj.c0 = 1;
                obj.d0 = 0;
            elseif obj.filter_type == "LPF_LR4"
                % LR4 Filter - NOT USED
                obj.theta = (pi * obj.fc) / obj.fs;
                obj.omega = pi * obj.fc;
                obj.k = obj.omega / tan(obj.theta);
                obj.delta = (obj.k^2) + (obj.omega^2) + 2*obj.k*obj.omega;
                obj.a0 = (obj.omega^2) / obj.delta;
                obj.a1 = 2 * ((obj.omega ^ 2) / obj.delta);
                obj.a2 = (obj.omega ^ 2) / obj.delta;
                obj.b1 = ((-2 * (obj.k^2)) + (2*(obj.omega^2))) / obj.delta;
                obj.b2 = ((-2*obj.k*obj.omega) + (obj.k^2) + (obj.omega^2)) / obj.delta;
                obj.c0 = 1;
                obj.d0 = 0;
            end
        end
        
    end
end