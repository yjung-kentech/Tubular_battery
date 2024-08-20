clear; clc; close all;

data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout.mat');

load(tubular_file);
tube_data = data;

load(cylinder_file);
cyl_data = data;

D_out_vec_tube = 2 * tube_data.R_out;
C_rate_vec_tube = tube_data.C_rate;

D_out_vec_cyl = 2 * cyl_data.R_out;
C_rate_vec_cyl = cyl_data.C_rate;

idx_4C_tube = find(C_rate_vec_tube == 4);
idx_6C_tube = find(C_rate_vec_tube == 6);

idx_4C_cyl = find(C_rate_vec_cyl == 4);
idx_6C_cyl = find(C_rate_vec_cyl == 6);

% Extract T_max and T_avg for 4C and 6C
T_max_4C_tube = tube_data.T_max(idx_4C_tube, :);
T_avg_4C_tube = tube_data.T_avg(idx_4C_tube, :);
T_max_6C_tube = tube_data.T_max(idx_6C_tube, :);
T_avg_6C_tube = tube_data.T_avg(idx_6C_tube, :);

T_max_4C_cyl = cyl_data.T_max(idx_4C_cyl, :);
T_avg_4C_cyl = cyl_data.T_avg(idx_4C_cyl, :);
T_max_6C_cyl = cyl_data.T_max(idx_6C_cyl, :);
T_avg_6C_cyl = cyl_data.T_avg(idx_6C_cyl, :);

% Plot 4C
subplot(2, 1, 1)
lw = 1; % Desired line width
color1 = [0.8500, 0.3250, 0.0980]; % Orange
color2 = [0, 0.4470, 0.7410]; % Blue

plot(D_out_vec_tube, T_max_4C_tube, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'DisplayName', 'Tube T_{max} 4C')
hold on
plot(D_out_vec_tube, T_avg_4C_tube, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'DisplayName', 'Tube T_{avg} 4C')
hold on
plot(D_out_vec_cyl, T_max_4C_cyl, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 's', 'DisplayName', 'Cylinder T_{max} 4C')
hold on
plot(D_out_vec_cyl, T_avg_4C_cyl, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 's', 'DisplayName', 'Cylinder T_{avg} 4C')
hold off


xlabel('D_{out} [mm]');
ylabel('T_{max} [degC]');
title('4C');
legend('Location', 'northwest');
grid on;

% Plot 6C
subplot(2, 1, 2)
plot(D_out_vec_tube, T_max_6C_tube, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'DisplayName', 'Tube T_{max} 6C')
hold on
plot(D_out_vec_tube, T_avg_6C_tube, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'DisplayName', 'Tube T_{avg} 6C')
hold on
plot(D_out_vec_cyl, T_max_6C_cyl, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 's', 'DisplayName', 'Cylinder T_{max} 6C')
hold on
plot(D_out_vec_cyl, T_avg_6C_cyl, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 's', 'DisplayName', 'Cylinder T_{avg} 6C')
hold off

xlabel('D_{out} [mm]');
ylabel('T_{max} [degC]');
title('6C');
legend('Location', 'northwest');
grid on;

set(gcf, 'Position', [100, 100, 600, 700]);

exportgraphics(gcf, 'figure2.png', 'Resolution', 300);