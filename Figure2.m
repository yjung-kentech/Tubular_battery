clear; clc; close all;

data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
data_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout.mat');
load(data_file);

D_out_vec = 2 * data.R_out;
C_rate_vec = data.C_rate;

idx_4C = find(C_rate_vec == 4);
idx_6C = find(C_rate_vec == 6);

% Extract T_max and T_avg for 4C and 6C
T_max_4C = data.T_max(idx_4C, :);
T_avg_4C = data.T_avg(idx_4C, :);
T_max_6C = data.T_max(idx_6C, :);
T_avg_6C = data.T_avg(idx_6C, :);

% Plot 4C
figure;
red = [0.8500, 0.3250, 0.0980];
blue = [0, 0.4470, 0.7410];

plot(D_out_vec, T_max_4C, 'red', 'LineWidth', 1, 'DisplayName', 'T_{max} 4C')
hold on
plot(D_out_vec, T_avg_4C, 'blue', 'LineWidth', 1, 'DisplayName', 'T_{avg} 4C')
hold off

xlabel('D_{out} [mm]');
ylabel('T_{max} [degC]');
title('4C');
legend('Location', 'best');
grid on;

% Plot 6C
figure;

plot(D_out_vec, T_max_6C, 'red', 'LineWidth', 1, 'DisplayName', 'T_{max} 6C')
hold on
plot(D_out_vec, T_avg_6C, 'blue', 'LineWidth', 1, 'DisplayName', 'T_{avg} 6C')
hold off

xlabel('D_{out} [mm]');
ylabel('T_{max} [degC]');
title('6C');
legend('Location', 'best');
grid on;