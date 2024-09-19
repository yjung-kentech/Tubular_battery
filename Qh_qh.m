clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_1cell_isothermal.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% Parameters
T_vec = 25; % Temperature values
I_vec = [0.1 0.5 1 2 4 6 8 10 12]; % Current values

% Initialize data structures
data_table_R = table();
I_cc_matrix = zeros(length(T_vec), length(I_vec));
Qh_avg_matrix = zeros(length(T_vec), length(I_vec)); % Qh 평균값 저장하는 매트릭스

for i = 1:length(T_vec)
    for j = 1:length(I_vec)
        T = T_vec(i);
        I = I_vec(j);

        % Set parameters in COMSOL model
        model.param.set('T0', sprintf('%g[degC]', T));
        model.param.set('C_rate', I);
        V_jr = model.param.evaluate('V_jr');
        vfactor = model.param.evaluate('vfactor');
        
        % Run COMSOL study
        model.study('std1').run;

        % Extract data from COMSOL model
        SOC = mphglobal(model, 'SOC');
        OCV = mphglobal(model, 'OCV');
        V = mphglobal(model, 'E_cell');
        qh = mphglobal(model, 'q_h'); % 공간적 분포를 포함하는 qh
        I_cell = mphglobal(model, 'I_cell');
        
        % Calculate I_cc
        i_1C_1D = 46.022; % A/m²
        A_jr = 0.74471; % m²
        I_cc = I * i_1C_1D * A_jr;

        % Save I_cc to matrix
        I_cc_matrix(i, j) = I_cc;

        % Calculate R, unit Ω
        R = (V - OCV) / I_cc;
        Qh = (I_cell.^2 .* R / V_jr)/vfactor;

        % Ensure unique SOC values for interpolation
        [SOC_unique, unique_idx] = unique(SOC);
        Qh_unique = Qh(unique_idx);
        qh_unique = qh(unique_idx);

        % Calculate spatial average for each unique SOC value
        % Assumes qh is a spatial distribution for a fixed SOC
        Qh_avg = arrayfun(@(s) mean(qh(SOC == s)), SOC_unique);

        % Interpolate Qh values to SOC_vec
        SOC_vec = [0:0.01:0.1 0.15:0.05:SOC_unique(end) SOC_unique(end)];
        Qh_vec = interp1(SOC_unique, Qh_avg, SOC_vec, 'linear', 'extrap');
        qh_vec = interp1(SOC_unique, qh_unique, SOC_vec, 'linear', 'extrap');

        % Append to data_table_R
        data_table_R = [data_table_R; table(T*ones(size(SOC_vec')), I*ones(size(SOC_vec')), SOC_vec', Qh_vec', qh_vec', ...
            'VariableNames',{'T', 'I', 'SOC', 'Qh', 'qh'})];
        
    end
end

% Save the tables to txt files
writetable(data_table_R, 'R_25_(T, I, SOC).txt', 'Delimiter', '\t');
