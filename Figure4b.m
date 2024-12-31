clear; clc; close all;

%% Apparent Energy Density
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_1202.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

R_out_values = [23, 30, 40];
R_in_values = 2:10;

% Initialize a matrix to store results
rho_app_results = zeros(length(R_in_values), length(R_out_values));
rho_app_cyl_results = zeros(length(R_in_values), length(R_out_values));

for i = 1:length(R_out_values)
    R_out = R_out_values(i);
    R_out_str = [num2str(R_out) '[mm]'];
    
    for j = 1:length(R_in_values)
        R_in = R_in_values(j);
        R_in_str = [num2str(R_in) '[mm]'];

        % Set the parameters in COMSOL
        model.param.set('R_out', R_out_str);
        model.param.set('R_in', R_in_str);

        % Get the value of cell2D_Q directly from the parameters
        rho_app = model.param.evaluate('rho_app*2.7778e-7');
        rho_app_cylin = model.param.evaluate('rho_app_cylin*2.7778e-7');

        % Store the result
        rho_app_results(j, i) = rho_app;
        rho_app_cyl_results(j, i) = rho_app_cylin;

    end
end

%% Charging Time (Cylinder)
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_1202.mat');

load(cylinder_file);
cylinder_data = data;

C_rate_vec_cylinder = cylinder_data.C_rate;
D_out_vec_cylinder = 2 * cylinder_data.R_out;

% 등고선 좌표 추출 및 정렬 및 보간 (Cylinder)

Elpcut = 0;
T_allowed = 45;

M_Elp_cylinder = contour(D_out_vec_cylinder, C_rate_vec_cylinder, cylinder_data.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x_cylinder = M_Elp_cylinder(1, 2:end);
Elp_y_cylinder = M_Elp_cylinder(2, 2:end);

M_Tmax_cylinder = contour(D_out_vec_cylinder, C_rate_vec_cylinder, cylinder_data.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x_cylinder = M_Tmax_cylinder(1, 2:end);
Tmax_y_cylinder = M_Tmax_cylinder(2, 2:end);

[Elp_x_cylinder, idx] = sort(Elp_x_cylinder);
Elp_y_cylinder = Elp_y_cylinder(idx);

[Tmax_x_cylinder, idx] = sort(Tmax_x_cylinder);
Tmax_y_cylinder = Tmax_y_cylinder(idx);

Elp_xq_cylinder = min(Elp_x_cylinder):1:max(Elp_x_cylinder);
Elp_yq_cylinder = interp1(Elp_x_cylinder, Elp_y_cylinder, Elp_xq_cylinder, 'linear');

Tmax_xq_cylinder = 30:1:max(Tmax_x_cylinder);
Tmax_yq_cylinder = interp1(Tmax_x_cylinder, Tmax_y_cylinder, Tmax_xq_cylinder, 'linear');

% Merging coordinates and selecting the minimum y-value for each x-value (Cylinder)

all_x_cylinder = unique([Elp_xq_cylinder, Tmax_xq_cylinder]);
min_y_cylinder = arrayfun(@(x) min([interp1(Elp_x_cylinder, Elp_y_cylinder, x, 'linear', inf), interp1(Tmax_x_cylinder, Tmax_y_cylinder, x, 'linear', inf)]), all_x_cylinder);

desired_R_out = [23, 30, 40];
desired_D_out = 2 * desired_R_out;

min_y_at_desired_D_out = interp1(all_x_cylinder, min_y_cylinder, desired_D_out, 'linear', 'extrap');
t95_at_desired_points = arrayfun(@(x, y) interp2(D_out_vec_cylinder, C_rate_vec_cylinder, cylinder_data.t95, x, y, 'linear', inf), desired_D_out, min_y_at_desired_D_out);

point_names = {'Point 46', 'Point 60', 'Point 80'};
desired_points = struct('name', {}, 'D_out', {}, 'C_rate', {}, 't95', {});
for i = 1:length(desired_R_out)
    desired_points(i).name = point_names{i};
    desired_points(i).D_out = desired_D_out(i);
    desired_points(i).C_rate = min_y_at_desired_D_out(i);
    desired_points(i).t95 = t95_at_desired_points(i);
end

% Display
% for i = 1:length(desired_R_out)
%     fprintf('At R_out = %d (D_out = %d):\n', desired_R_out(i), desired_D_out(i));
%     fprintf('Minimum C-rate satisfying constraints: %.2f\n', min_y_at_desired_D_out(i));
%     fprintf('Corresponding t95: %.2f minutes\n\n', t95_at_desired_points(i));
% end


%% Charging Time (Tubular)
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
file1 = fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_46.mat');
file2 = fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_60.mat');
file3 = fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_80.mat');

load(file1);
data1 = data;

load(file2);
data2 = data;

load(file3);
data3 = data;

C_rate_vec1 = data1.C_rate;
C_rate_vec2 = data2.C_rate;
C_rate_vec3 = data3.C_rate;

D_in_vec1 = 2 * data1.R_in;
D_in_vec2 = 2 * data2.R_in;
D_in_vec3 = 2 * data3.R_in;

% 추가 변수 계산
Elpcut = 0;
T_allowed = 45;

ismat_soc1 = data1.SOC;
ismat_nlp1 = double(data1.Elp_min > Elpcut);
ismat_Tmax1 = double(data1.T_max < T_allowed);

ismat_soc2 = data2.SOC;
ismat_nlp2 = double(data2.Elp_min > Elpcut);
ismat_Tmax2 = double(data2.T_max < T_allowed);

ismat_soc3 = data3.SOC;
ismat_nlp3 = double(data3.Elp_min > Elpcut);
ismat_Tmax3 = double(data3.T_max < T_allowed);

% 등고선 좌표 추출 및 정렬 및 보간 (data1)
M_Elp1 = contour(D_in_vec1, C_rate_vec1, data1.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x1 = M_Elp1(1, 2:end);
Elp_y1 = M_Elp1(2, 2:end);

M_Tmax1 = contour(D_in_vec1, C_rate_vec1, data1.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x1 = M_Tmax1(1, 2:end);
Tmax_y1 = M_Tmax1(2, 2:end);

[Elp_x1, idx] = sort(Elp_x1);
Elp_y1 = Elp_y1(idx);
[Tmax_x1, idx] = sort(Tmax_x1);
Tmax_y1 = Tmax_y1(idx); 
    
Elp_xq1 = min(Elp_x1):1:max(Elp_x1);
Elp_yq1 = interp1(Elp_x1, Elp_y1, Elp_xq1, 'linear');

Tmax_xq1 = min(Tmax_x1):1:max(Tmax_x1);
Tmax_yq1 = interp1(Tmax_x1, Tmax_y1, Tmax_xq1, 'linear');

% 등고선 좌표 추출 및 정렬 및 보간 (data2)
M_Elp2 = contour(D_in_vec2, C_rate_vec2, data2.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x2 = M_Elp2(1, 2:end);
Elp_y2 = M_Elp2(2, 2:end);

M_Tmax2 = contour(D_in_vec2, C_rate_vec2, data2.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x2 = M_Tmax2(1, 2:end);
Tmax_y2 = M_Tmax2(2, 2:end);

[Elp_x2, idx] = sort(Elp_x2);
Elp_y2 = Elp_y2(idx);
[Tmax_x2, idx] = sort(Tmax_x2);
Tmax_y2 = Tmax_y2(idx); 
    
Elp_xq2 = min(Elp_x2):1:max(Elp_x2);
Elp_yq2 = interp1(Elp_x2, Elp_y2, Elp_xq2, 'linear');

Tmax_xq2 = min(Tmax_x2):1:max(Tmax_x2);
Tmax_yq2 = interp1(Tmax_x2, Tmax_y2, Tmax_xq2, 'linear');

% 등고선 좌표 추출 및 정렬 및 보간 (data3)
M_Elp3 = contour(D_in_vec3, C_rate_vec3, data3.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x3 = M_Elp3(1, 2:end);
Elp_y3 = M_Elp3(2, 2:end);

M_Tmax3 = contour(D_in_vec3, C_rate_vec3, data3.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x3 = M_Tmax3(1, 2:end);
Tmax_y3 = M_Tmax3(2, 2:end);

[Elp_x3, idx] = sort(Elp_x3);
Elp_y3 = Elp_y3(idx);
[Tmax_x3, idx] = sort(Tmax_x3);
Tmax_y3 = Tmax_y3(idx); 
    
Elp_xq3 = min(Elp_x3):1:max(Elp_x3);
Elp_yq3 = interp1(Elp_x3, Elp_y3, Elp_xq3, 'linear');

Tmax_xq3 = min(Tmax_x3):1:max(Tmax_x3);
Tmax_yq3 = interp1(Tmax_x3, Tmax_y3, Tmax_xq3, 'linear');

% Merging coordinates and selecting the minimum y-value for each x-value
all_x1 = unique([Elp_xq1, Tmax_xq1]);
min_y1 = arrayfun(@(x) min([interp1(Elp_x1, Elp_y1, x, 'linear', inf), interp1(Tmax_x1, Tmax_y1, x, 'linear', inf)]), all_x1);
min_y_coordinates1 = [all_x1; min_y1];

all_x2 = unique([Elp_xq2, Tmax_xq2]);
min_y2 = arrayfun(@(x) min([interp1(Elp_x2, Elp_y2, x, 'linear', inf), interp1(Tmax_x2, Tmax_y2, x, 'linear', inf)]), all_x2);
min_y_coordinates2 = [all_x2; min_y2];

all_x3 = unique([Elp_xq3, Tmax_xq3]);
min_y3 = arrayfun(@(x) min([interp1(Elp_x3, Elp_y3, x, 'linear', inf), interp1(Tmax_x3, Tmax_y3, x, 'linear', inf)]), all_x3);
min_y_coordinates3 = [all_x3; min_y3];

% Interpolating charging time using min_y values
charging_time1= arrayfun(@(x, y) interp2(D_in_vec1, C_rate_vec1, data1.t95, x, y, 'linear', inf), all_x1, min_y1);
charging_time_coordinates1 = [all_x1; charging_time1];

charging_time2= arrayfun(@(x, y) interp2(D_in_vec2, C_rate_vec2, data2.t95, x, y, 'linear', inf), all_x2, min_y2);
charging_time_coordinates2 = [all_x2; charging_time2];

charging_time3= arrayfun(@(x, y) interp2(D_in_vec3, C_rate_vec3, data3.t95, x, y, 'linear', inf), all_x3, min_y3);
charging_time_coordinates3 = [all_x3; charging_time3];  

%% Plot the results

figure;
lw = 1;
hold on;

color1 = [0.9290 0.6940 0.1250]; % Yellow
color2 = [0.4940 0.1840 0.5560]; % Purple
color3 = [0.4660 0.6740 0.1880]; % Green

colors = [color1; color2; color3];
charging_time_coordinates = {charging_time_coordinates1, charging_time_coordinates2, charging_time_coordinates3};


yyaxis left;

% Cylindrical cell
plot(0, rho_app_cyl_results(:, 1), 'Color', color1, 'Marker', 'x', 'LineWidth', 1, 'LineStyle', 'none');
plot(0, rho_app_cyl_results(:, 2), 'Color', color2, 'Marker', 'x', 'LineWidth', 1, 'LineStyle', 'none');
plot(0, rho_app_cyl_results(:, 3), 'Color', color3, 'Marker', 'x', 'LineWidth', 1, 'LineStyle', 'none');

legend({'', '', ''}); 

yyaxis right;
plot(0, desired_points(1).t95, 'Color', color1, 'Marker', 'o', 'LineWidth', 1, 'LineStyle', 'none');
plot(0, desired_points(2).t95, 'Color', color2, 'Marker', 'o', 'LineWidth', 1, 'LineStyle', 'none');
plot(0, desired_points(3).t95, 'Color', color3, 'Marker', 'o', 'LineWidth', 1, 'LineStyle', 'none');

legend({'', '', ''}); 

yyaxis left;

% Tubular cell
for i = 1:length(R_out_values)
    
    plot(R_in_values * 2, rho_app_results(:, i), 'Color', colors(mod(i - 1, size(colors, 1)) + 1, :), 'LineStyle', '-', 'Marker', 'x', ...
        'LineWidth', lw, 'DisplayName', ['\rho_{E} ' num2str(2 * R_out_values(i)), 'mm']);
end

% Set Y-axis label
ylabel('Apparent Energy Density [kWh/m^3]', 'FontSize', 10);
ylim([620 800]);

ax = gca;
ax.YColor = 'k';

yyaxis right;

for i = 1:length(R_out_values)
    marker_spacing = 2;
    num_data_points = length(charging_time_coordinates{i}(1,3:end));
    marker_indices = 1:marker_spacing:num_data_points;
    plot(charging_time_coordinates{i}(1,3:end), charging_time_coordinates{i}(2,3:end), 'Color', colors(mod(i - 1, size(colors, 1)) + 1, :), ...
        'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'LineWidth', lw, 'DisplayName', ['t_{chg} ' num2str(2 * R_out_values(i)), 'mm']);
end

xlabel('D_{in} [mm]', 'FontSize', 10);
ylabel('Charging Time [min]', 'FontSize', 10);
ylim([5 35]);
ax.YColor = 'k';

legend('Location','northeast', 'FontSize', 8, 'NumColumns', 2);
grid on;
hold off;

ax = gca;
ax.Box ='on';

exportgraphics(gcf, 'figure4b_1230.png', 'Resolution', 300);

%% D_in 3mm, 4mm, 5mm 일 떄 energy density, charging time 계산

% Define the specific D_in values you want to investigate
D_in_targets = [10 15 20];

% Initialize matrices to store results
energy_density_results = zeros(length(D_in_targets), length(R_out_values));
charging_time_results = zeros(length(D_in_targets), length(R_out_values));

% Calculate energy density and charging time for each R_out at specified D_in values
for i = 1:length(R_out_values)
    % Interpolate energy density at specified D_in values for tubular cells
    energy_density_results(:, i) = interp1(R_in_values * 2, rho_app_results(:, i), D_in_targets, 'linear', 'extrap');
    
    % Interpolate charging time at specified D_in values for tubular cells
    charging_time_results(:, i) = interp1(charging_time_coordinates{i}(1, :), charging_time_coordinates{i}(2, :), D_in_targets, 'linear', 'extrap');
end

% Display the results
for i = 1:length(R_out_values)
    fprintf('Results for D_out = %d mm (R_out = %d mm):\n', 2 * R_out_values(i), R_out_values(i));
    for j = 1:length(D_in_targets)
        fprintf('  D_in = %d mm:\n', D_in_targets(j));
        fprintf('    Energy Density: %.3f kWh/m^3\n', energy_density_results(j, i));
        fprintf('    Charging Time: %.3f min\n', charging_time_results(j, i));
    end
    fprintf('\n');
end

