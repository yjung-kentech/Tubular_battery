clear;clc;close all

%% Read the data

data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
data_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_Result.mat');
load(data_file);

C_rate_vec = data.C_rate;
D_out_vec = 2 * data.R_out;

%% Caculate additional variables

% 1. Is SOC criterium met?
ismat_soc = data.SOC;

% 2. Is Lithium plating condition met?
Elpcut = 0;
ismat_nlp = double(data.Elp_min > Elpcut);
contour_nlp = contourf(D_out_vec, C_rate_vec, ismat_nlp, [0.5 0.5]); close
patch_nlp_x = [contour_nlp(1,2:end), D_out_vec(end,1), D_out_vec(1,1)];
patch_nlp_y = [contour_nlp(2,2:end), C_rate_vec(1,end), C_rate_vec(1,end)];

[unique_patch_nlp_x, unique_idx] = unique(patch_nlp_x);
unique_patch_nlp_y = patch_nlp_y(unique_idx);
patch_nlp_x_interp = linspace(min(unique_patch_nlp_x), max(unique_patch_nlp_y));
patch_nlp_y_interp = interp1(unique_patch_nlp_x, unique_patch_nlp_y, patch_nlp_x_interp, 'spline');

% 3. Is Temperature condition met?
T_allowed = 50;
ismat_Tmax = double(data.T_max < T_allowed);
contour_Tmax = contourf(D_out_vec, C_rate_vec, ismat_Tmax, [0.5 0.5]); close
patch_Tmax_x = contour_Tmax(1,2:end);
patch_Tmax_y = contour_Tmax(2,2:end);

[unique_patch_Tmax_x, unique_idx] = unique(patch_Tmax_x);
unique_patch_Tmax_y = patch_Tmax_y(unique_idx);
patch_Tmax_x_interp = linspace(min(unique_patch_Tmax_x), max(unique_patch_Tmax_x));
patch_Tmax_y_interp = interp1(unique_patch_Tmax_x, unique_patch_Tmax_y, patch_Tmax_x_interp, 'spline');


%% Plotting results

figure
 
contourf(D_out_vec, C_rate_vec, data.t95, 20, 'LineColor', 'none'); hold on
clim([min(data.t95(:)) max(data.t95(:))]);
[~, hElp] = contour(D_out_vec, C_rate_vec, data.Elp_min, [Elpcut, Elpcut], 'LineWidth', 2, 'LineColor', 'w'); hold on
[~, hTmax] = contour(D_out_vec, C_rate_vec, data.T_max, [T_allowed, T_allowed], 'LineWidth', 2, 'LineColor', 'r'); hold on

xlabel('D_{out} (mm)', 'FontWeight', 'bold')
ylabel('C-rate', 'FontWeight', 'bold')
hold on
h = colorbar;
ylabel(h, 't_{charge} (min)', 'FontWeight', 'bold');
titleHandle = title('Charging Time (min)');
set(titleHandle, 'FontWeight', 'bold', 'FontSize', 12);

x = 46;
y = 6;
xline(x, '--w', 'LineWidth', 1);
yline(y, '--w', 'LineWidth', 1);
plot(x, y, 'ro', 'MarkerFaceColor', 'r');


lgd = legend([hTmax, hElp], {'T_{max} = 50 ^oC', '\phi_{lp} = 0 V'}, 'Location', 'southeast');
set(lgd, 'Color', [0.8, 0.8, 0.8]);
set(lgd, 'EdgeColor', 'black');

