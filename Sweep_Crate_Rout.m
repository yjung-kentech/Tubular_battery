clear; clc; close all

% Initiate comsol
import com.comsol.model.*
import com.comsol.model.util.*

%% Inputs
COM_filepath = 'C:\Users\user\Desktop\Tubular cell';
COM_filename = 'JYR_cell_0228.mph';
% COM_filename = 'JYR_cell_cylinder.mph'; % Cylinder
COM_fullfile = fullfile(COM_filepath, COM_filename);

result_filename = 'Tubular_Sweep_Crate_Rout_Result_.mat';
% result_filename = 'Cylinder_Sweep_Crate_Rout_Result_.mat';

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

mphnavigator;

%% Sweep
C_rate_vec = 1:12; % [1:0.2:12];
R_out_vec = 5:2.5:40;
N = length(C_rate_vec);
M = length(R_out_vec);

% Load progress information if available
if exist(result_filename, 'file')
    load(result_filename, 'data');
    resume_flag = true;
else
    data.C_rate = C_rate_vec;
    data.R_out = R_out_vec;
    data.T_max_total = cell(N, M);
    data.T_avg_total = cell(N, M);
    data.E_lp_total = cell(N, M);
    data.SOC = cell(N, M);
    data.t = cell(N, M);

    data.T_max = zeros(N, M);
    data.T_avg = zeros(N, M);
    data.E_lp = zeros(N, M);
    data.t95 = zeros(N, M);

    data.last_i = 1;
    data.last_j = 1;
    resume_flag = false;
    
end

tic1 = tic;

for i = data.last_i:N
    current_C_rate = C_rate_vec(i);

    for j = data.last_j:M
        current_R_out = R_out_vec(j);

        fprintf('Current case: %u / %u and %u / %u. \n', i, N, j, M)

        tic2 = tic;

        R_out_str = [num2str(current_R_out) '[mm]'];
        model.param.set('C_rate', current_C_rate);
        model.param.set('R_out', R_out_str);

        model.study('std1').run

        t_cal = toc(tic2);

        data.T_max_total{i, j} = mphglobal(model, 'T_max', 'unit', 'degC');
        data.T_avg_total{i, j} = mphglobal(model, 'T_avg', 'unit', 'degC');
        data.E_lp_total{i, j} = mphglobal(model, 'E_lp');

        data.T_max(i, j) = max(mphglobal(model, 'T_max', 'unit', 'degC'));
        data.T_avg(i, j) = max(mphglobal(model, 'T_avg', 'unit', 'degC'));
        data.E_lp(i, j) = min(mphglobal(model, 'E_lp'));

        [data.SOC{i, j}, unique_idx] = unique(mphglobal(model, 'SOC'));
        t_values = mphglobal(model, 't', 'unit', 'min');

        data.t{i, j} = t_values(unique_idx);

        data.t95(i, j) = interp1(data.SOC{i, j}, data.t{i, j}, 0.95);

        fprintf('Done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
            t_cal, (i - 1) * M + j, N * M, round(100 * ((i - 1) * M + j) / (N * M)))

        fprintf('E_lp: %f, T_max: %f, T_avg: %f at time %f minutes.\n',  data.E_lp(i, j), data.T_max(i, j), data.T_avg(i, j), data.t95(i, j));

        % Update last_i and last_j for resuming
        data.last_i = i;
        data.last_j = j + 1;

        save(result_filename, 'data');

    end
    data.last_j = 1; % Reset last_j for the next iteration
end

t_total = toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n', t_total / 3600)
