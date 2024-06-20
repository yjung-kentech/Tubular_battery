clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular cell';
COM_filename = 'JYR_1cell_isothermal.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% Parameters
T_vec = [10 20 30 40 50 70 90]; % Temperature values
I_vec = [0.1 0.5 1 2 4 6 8 10 12]; % Current values

% Initialize data structures
data_table_R = table();
data_table_OCV = table();
data_table_Elp = table();

for i = 1:length(T_vec)
    for j = 1:length(I_vec)
        T = T_vec(i);
        I = I_vec(j);

        % Set parameters in COMSOL model
        model.param.set('T0', sprintf('%g[degC]', T));
        model.param.set('C_rate', I);

        % Run COMSOL study
        model.study('std1').run

        % Extract data from COMSOL model
        SOC = mphglobal(model, 'SOC');
        OCV = mphglobal(model, 'OCV');
        E_lp = mphglobal(model, 'E_lp');
        V = mphglobal(model, 'E_cell');

        % Calculate R
        R = (V - OCV) / I;

        % Interpolate R values to SOC_vec
        SOC_vec = [0.5 5:5:SOC(end)];

        for k = 1:length(SOC_vec)
            SOC_val = SOC_vec(k);
            R_val = interp1(SOC, R, SOC_val);

            data_table_R = [data_table_R; table(T, I, SOC_val, R_val, ...
                'VariableNames', {'T', 'I', 'SOC', 'R'})];
        end

            % Append to tables
            data_table_OCV = [data_table_OCV; table(SOC, OCV, 'VariableNames', {'SOC', 'OCV'})];
            data_table_Elp = [data_table_Elp; table(SOC, E_lp, 'VariableNames', {'SOC', 'E_lp'})];

    end
end

% Save the tables to txt files
writetable(data_table_R, 'R(T, I, SOC).txt', 'Delimiter', '\t');
writetable(data_table_OCV, '(SOC, OCV).txt', 'Delimiter', '\t');
writetable(data_table_Elp, '(SOC, E_lp).txt', 'Delimiter', '\t');
