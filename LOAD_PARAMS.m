close all; clc;        


% Specify the directory containing the files
folderPath = 'D:\Files\TA\Matlab2\param';  % Update with your directory path

% Get a list of all .mat files in the directory
fileList = dir(fullfile(folderPath, '*.mat'));

% Load Validation
validation = 0;

% Initialize an empty struct to store the data
params = struct();

% Loop through each file in the list
for i = 1:length(fileList)
    % Get the full path of the file
    filePath = fullfile(folderPath, fileList(i).name)
    
    % Load the file
    fileData = load(filePath);
    
    % Use the filename (without extension) as the field name
    [~, name, ~] = fileparts(fileList(i).name);
    underscore_positions = strfind(name, '_');  % Find positions of underscores
    name = name(1:underscore_positions(1) - 1);  % Extract substring up to second underscore
    
    param = fileData.param
    
    for j = 1:round(length(fileData.param)/4)
        k = fileData.param(j*4 - 3);
        omega_n = fileData.param(j*4 - 2);
        zeta = fileData.param(j*4 - 1);
        td = abs(fileData.param(j*4));
        
        params.(name).(sprintf('num%d',j)) = [k * omega_n^2];
        params.(name).(sprintf('den%d',j)) = [1, 2 * zeta * omega_n, omega_n^2];
        tf(params.(name).(sprintf('num%d',j)),params.(name).(sprintf('den%d',j)));
        params.(name).(sprintf('td%d',j)) = td;
        params.(name).(sprintf('N%d',j)) = fileData.nonLinearFunction(j);     
    end
    params.(name).('bg') = fileData.param(end) ;
    
    if validation == 1
        filePath = strrep(filePath, 'param', 'data');  % Replace 'param' with 'data'
        filePath = strrep(filePath, '.mat', '_data.mat');  % Replace '.mat' with '_data.mat'
        
        % Load the file
        load(filePath);
        [y_sim, ave_fit, fit] = Simulate(name, params, data);
        fit
        t = data.SamplingInstants;
            
        fig = figure('Position', [0, 0, 600, 600]); % Adjusted to fit all subplots

        % Output subplot (600x300)
        subplot(4, 1, 1,'Position', [0.1, 0.71, 0.85, 0.25]); % Top subplot
        plot(t, data.y, 'r-', 'LineWidth', 1.5); % Actual output in red
        hold on;
        plot(t, y_sim, 'b--', 'LineWidth', 1.5); % Simulated output in blue
        hold off;
        legend({'Y_{act}', ['Y_{est} (Fit: ' num2str(fit, '%.2f') '%)']}, 'Location', 'best');
        xlabel('Time(s)');
        ylabel('Y_i');

        % Input subplots (600x100 each)
        for i = 1:min(3, size(data.u, 2)) % Handle up to 3 inputs
            subplot(4, 1, i + 1, 'Position', [0.1, 0.67-0.17*i, 0.85, 0.1]); % Subplots 2, 3, and 4
            plot(t, data.u(:, i), 'k-', 'LineWidth', 1.5); % Input in black
            xlabel('Time(s)');
            ylabel(['U_i_,_',num2str(i)]);
        end

        % Save the figure
        saveDir = 'figure\'; % Change this to your desired path
        result = split(data.user.title, ' '); % Split the string at ' '
        fileName = fullfile(saveDir, [result{1}, '.png']); % Combine directory and filename
        saveas(fig, fileName); % Save as PNG
    end
    
end

% Display the resulting struct
disp(params);


%%

filename = 'data/data.xlsx'; % Replace with your XLSX file path
dataTable = readtable(filename, 'Sheet', 'FIC3134_2');
    
% Extract relevant columns
time = dataTable.Time; % Time column
inputData = [dataTable.Q5A, dataTable.L5A, dataTable.V5A, dataTable.Q6A, dataTable.L6A, dataTable.V6A, dataTable.omega_casA, dataTable.omega_manA]; % Input data columns
outputData = [dataTable.Q4B,dataTable.Y]; % Output data columns
outputData2 = [dataTable.P2A,dataTable.P3A,dataTable.Q4A]; % Output data columns

samples = length(outputData);
t = 0:10:10*(samples+999);

inputData = [ones(1000,8).*inputData(1,:); inputData]; % Input data columns
inputData = [t', inputData]; % Input data columns
outputData = [ones(1000,2).*outputData(1,:); outputData]; % Output data columns
outputData = [t', outputData]; % Output data columns
outputData2 = [ones(1000,3).*outputData2(1,:); outputData2]; % Output data columns
outputData2 = [t', outputData2]; % Output data columns

% L5A = [ones(1000,1).*inputData(1,1); inputData(:,1)];
% V5A = [ones(1000,1).*inputData(1,2); inputData(:,2)];
% omega_casA = [ones(1000,1).*inputData(1,3); inputData(:,3)];
% omega_manA = [ones(1000,1).*inputData(1,4); inputData(:,4)];
% Y = [ones(1000,1).*outputData(1,1); inputData(:,1)];
% 
% L5A = [t',L5A];

%%

function [y_sim, ave_fit, fit] = Simulate(name, params, data)    
                        
            % Get the size of iddata object
            [samples, numOutputs, numInputs] = size(data);
            
            Ts = data.Ts;  % Sampling time
            S = samples + 1000;  % Number of data points
            t = (0:S-1) * Ts;  % Time vector from 0 to (N-1)*Ts
            y_actual = data.y(:, 1);  % Output signal from iddata
        
            % initialize y_sim and error
            y_sim = params.(name).('bg')*ones(S - 1000, numOutputs);
            
            % Loop through each input
            for i = 1:numInputs

                % Create transfer function Gn
                G = tf(params.(name).(sprintf('num%d',i)), params.(name).(sprintf('den%d',i)), 'InputDelay', params.(name).(sprintf('td%d',i)));


                % Simulate response for each input
                u_extended = [data.u(1,i) * ones(1000, 1); data.u(:,i)];  % Extend input with initial values
                [y_temp, ~] = lsim(G, u_extended, t);  % Simulate response for input j
                y_temp = y_temp(1000 + 1:end);  % Trim initial values


                str = string(params.(name).(sprintf('N%d',i)));
                str = strrep(str, 'u1', 'data.u(:,1)');
                str = strrep(str, 'u2', 'data.u(:,2)');
                str = strrep(str, 'u3', 'data.u(:,3)');
                str = strrep(str, '^', '.^');
                F = eval(str);


                % Add response to output
                y_sim = y_sim + F .* y_temp;
            end
            
            % Assuming data1 and data2 are defined
%             fit = 100 * (1 - norm(y_actual - y_sim) / norm(y_actual - mean(y_actual)));
            fit = 100 * (1 - sum((y_actual - y_sim).^2) / sum((y_actual - mean(y_actual)).^2));

            V = round(0.01 * samples);
            ave_fit = 100 * (1 - norm(y_actual(V:end) - y_sim(V:end)) / norm(y_actual(V:end) - mean(y_actual(V:end))));

        end