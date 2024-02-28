clear;clc;close all

% Initiate comsol
import com.comsol.model.*
import com.comsol.model.util.*



%% Inputs

COM_filepath = 'C:\Users\user\Desktop\Tubular cell';
COM_filename = 'JYR_cell_0228.mph';
% COM_filename = 'JYR_cell_cylinder.mph'; % Cylinder
COM_fullfile = fullfile(COM_filepath, COM_filename);

result_filename = 'Tubular_Sweep_Crate_Rout_Result.mat';
% result_filename = 'Cylinder_Sweep_Crate_Rout_Result.mat';


model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

mphnavigator;



%% Sweep

C_rate_vec = 1:2; % [1:0.2:12]; 
D_out_vec = 10:5:15; % 
N = length(C_rate_vec);
M = length(D_out_vec);

% Secure memory
T_max = zeros(N,M);
E_lp = zeros(N,M);
SOC = cell(N,M);
t = cell(N,M);
t95 = zeros(N,M);

tic1 =tic; % begin time  for entire sweep

for i = 1:N

    C_rate = C_rate_vec(i);

    for j = 1:M

        D_out = D_out_vec(j);

        % Display calculation status
        fprintf('Current case: %u / %u and %u / %u. \n',...
                i,N,j,M)
        
        tic2 = tic; % begin time  for each case

        % Load model to reset to initial state
        % model = mphload(COM_fullfile);

        % Parameter setting in .mph

        model.param.set('C_rate', C_rate);
        model.param.set('D_out', D_out);

        % Run mph model
        model.study('std1').run

        t_cal = toc(tic2);
 

        % Extract results
        [T_max(i, j), max_index] = max(mphglobal(model, 'T_max', 'unit', 'Celsius'));
        E_lp(i,j) = min(mphglobal(model, 'E_lp'));
        SOC{i,j} = mphglobal(model,'SOC');
        t{i,j} = mphglobal(model, 't', 'unit', 'min');

        % Calculate charging times
        t95(i,j) = interp1(SOC{i,j}, t{i,j}, 0.95);


        % output update  
        fprintf('Done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
            t_cal,(i-1)*M + j,N*M,round(100*((i-1)*M + j)/(N*M)))

        fprintf('E_lp: %f, T_max: %f at time %f minutes.\n', E_lp(i, j), T_max(i, j), t{i, j}(max_index));


    end

end

% Save file
% save(result_filename, 'data', 'C_rate', 'D_out', 'T_max', 'E_lp', 'SOC', 't', 't95')

t_total=toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n',t_total/3600)