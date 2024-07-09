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
I_cc_matrix = zeros(length(T_vec), length(I_vec));

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
        V = mphglobal(model, 'E_cell');
        qh = mphgloabl(model, 'q_h');
        
        % Calculate I_cc
        i_1C_1D = 46.022; % A/m²
        A_jr = 0.74471; % m²
        I_cc = I * i_1C_1D * A_jr;

        % Save I_cc to matrix
        I_cc_matrix(i, j) = I_cc;

        % Calculate R, unit Ω
        R = (V - OCV) / I_cc;

        % Interpolate R values to SOC_vec
        SOC_vec = [0:0.05:SOC(end) SOC(end)];
        R_vec = interp1(SOC, R, SOC_vec, 'linear', 'extrap');
        qh_vec = interp1(SOC, qh, SOC_vec, 'linear', 'extrap');

        % Append to data_table_R
        data_table_R = [data_table_R; table(T*ones(size(SOC_vec')), I*ones(size(SOC_vec')), SOC_vec', R_vec', qh_vec', ...
            'VariableNames',{'T', 'I', 'SOC', 'R', 'q_h'})];
       
    end
end

% Save the tables to txt files
writetable(data_table_R, 'R, qh(SOC, T, I).txt', 'Delimiter', '\t');
