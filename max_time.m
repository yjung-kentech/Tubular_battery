clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cylinder_cell_0909.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

% Set parameters
C_rate = [2 6 10];
R_out = [10.5 23 35];
% R_in = 2;

% Load the model only once
model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% Prepare to save results
fileID = fopen('max_time_results_cylinder.txt', 'w');

% Loop through C_rate and R_out values
for i = 1:length(C_rate)
    for j = 1:length(R_out)

        % Convert parameters to string format for COMSOL
        R_out_str = [num2str(R_out(j)) '[mm]'];
        % R_in_str = [num2str(R_in) '[mm]'];

        % Set the parameters in the model
        model.param.set('C_rate', C_rate(i));
        model.param.set('R_out', R_out_str);
        % model.param.set('R_in', R_in_str);

        % Run the study
        model.study('std1').run;

        % Retrieve global variables after the study
        time_s = mphglobal(model, 't', 'unit', 's');
        T_max = mphglobal(model, 'T_max', 'unit', 'degC');

        % Find max T_max and the corresponding time
        [max_val, idx] = max(T_max);
        max_time_s = time_s(idx); % Max time in seconds
        max_time_min = max_time_s / 60; % Convert to minutes

        % Save the results to file
        fprintf(fileID, 'C_rate = %d, R_out = %.1f mm, R_in = %.1f mm\n', C_rate(i), R_out(j));
        fprintf(fileID, 'Max Temperature: %.2f degC\n', max_val);
        fprintf(fileID, 'Time of Max Temperature: %.2f seconds (%.2f minutes)\n', max_time_s, max_time_min);
        fprintf(fileID, '--------------------------------------------\n');

        % Display the results in MATLAB console
        disp(['C_rate = ', num2str(C_rate(i)), ', R_out = ', num2str(R_out(j)), ' mm']);
           % , R_in = ', num2str(R_in), ' mm']);
        disp(['Max Temperature: ', num2str(max_val), ' degC']);
        disp(['Time of Max Temperature: ', num2str(max_time_s), ' seconds (', num2str(max_time_min), ' minutes)']);
        disp('--------------------------------------------');
    end
end

% Close the file after saving all results
fclose(fileID);
