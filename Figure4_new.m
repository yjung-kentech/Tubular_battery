clear; clc; close all;

%% 데이터 읽기
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout_0819.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_0909.mat');

load(tubular_file);
tubular_data = data;

load(cylinder_file);
cylinder_data = data;

%% 변수 설정
C_rate_vec_tubular = tubular_data.C_rate;
D_out_vec_tubular = 2 * tubular_data.R_out;

C_rate_vec_cylinder = cylinder_data.C_rate;
D_out_vec_cylinder = 2 * cylinder_data.R_out;

%% 추가 변수 계산 (Tubular)
ismat_soc_tubular = tubular_data.SOC;
Elpcut = 0;
ismat_nlp_tubular = double(tubular_data.Elp_min > Elpcut);
T_allowed = 50;
ismat_Tmax_tubular = double(tubular_data.T_max < T_allowed);

%% 추가 변수 계산 (Cylinder)
ismat_soc_cylinder = cylinder_data.SOC;
ismat_nlp_cylinder = double(cylinder_data.Elp_min > Elpcut);
ismat_Tmax_cylinder = double(cylinder_data.T_max < T_allowed);

%% 등고선 좌표 추출 및 정렬 및 보간 (Tubular)
M_Elp_tubular = contour(D_out_vec_tubular, C_rate_vec_tubular, tubular_data.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x_tubular = M_Elp_tubular(1, 2:end);
Elp_y_tubular = M_Elp_tubular(2, 2:end);

M_Tmax_tubular = contour(D_out_vec_tubular, C_rate_vec_tubular, tubular_data.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x_tubular = M_Tmax_tubular(1, 2:end);
Tmax_y_tubular = M_Tmax_tubular(2, 2:end);

[Elp_x_tubular, idx] = sort(Elp_x_tubular);
Elp_y_tubular = Elp_y_tubular(idx);

[Tmax_x_tubular, idx] = sort(Tmax_x_tubular);
Tmax_y_tubular = Tmax_y_tubular(idx);

Elp_xq_tubular = min(Elp_x_tubular):1:max(Elp_x_tubular);
Elp_yq_tubular = interp1(Elp_x_tubular, Elp_y_tubular, Elp_xq_tubular, 'linear');

Tmax_xq_tubular = 30:1:max(Tmax_x_tubular);
Tmax_yq_tubular = interp1(Tmax_x_tubular, Tmax_y_tubular, Tmax_xq_tubular, 'linear');

%% 등고선 좌표 추출 및 정렬 및 보간 (Cylinder)
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

%% Merging coordinates and selecting the minimum y-value for each x-value (Tubular)
all_x_tubular = unique([Elp_xq_tubular, Tmax_xq_tubular]);
min_y_tubular = arrayfun(@(x) min([interp1(Elp_x_tubular, Elp_y_tubular, x, 'linear', inf), interp1(Tmax_x_tubular, Tmax_y_tubular, x, 'linear', inf)]), all_x_tubular);
min_y_coordinates_tubular = [all_x_tubular; min_y_tubular];

%% Merging coordinates and selecting the minimum y-value for each x-value (Cylinder)
all_x_cylinder = unique([Elp_xq_cylinder, Tmax_xq_cylinder]);
min_y_cylinder = arrayfun(@(x) min([interp1(Elp_x_cylinder, Elp_y_cylinder, x, 'linear', inf), interp1(Tmax_x_cylinder, Tmax_y_cylinder, x, 'linear', inf)]), all_x_cylinder);
min_y_coordinates_cylinder = [all_x_cylinder; min_y_cylinder];

%% Interpolating charging time using min_y values (Tubular)
charging_time_tubular = arrayfun(@(x, y) interp2(D_out_vec_tubular, C_rate_vec_tubular, tubular_data.t95, x, y, 'linear', inf), all_x_tubular, min_y_tubular);
charging_time_coordinates_tubular = [all_x_tubular; charging_time_tubular];

%% Interpolating charging time using min_y values (Cylinder)
charging_time_cylinder = arrayfun(@(x, y) interp2(D_out_vec_cylinder, C_rate_vec_cylinder, cylinder_data.t95, x, y, 'linear', inf), all_x_cylinder, min_y_cylinder);
charging_time_coordinates_cylinder = [all_x_cylinder; charging_time_cylinder];

%% Apparent energy density 추가
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_0909.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

R_out_values = 5:1:40;
R_in = 2;

% Initialize a matrix to store results
rho_app_results = zeros(1, length(R_out_values));

for i = 1:length(R_out_values)
    R_out = R_out_values(i);
    R_out_str = [num2str(R_out) '[mm]'];
    R_in_str = [num2str(R_in) '[mm]'];

    % Set the parameters in COMSOL
    model.param.set('R_out', R_out_str);
    model.param.set('R_in', R_in_str);

    % Get the value of cell2D_Q directly from the parameters
    rho_app = model.param.evaluate('rho_app*2.7778e-7');
    rho_app_cylin = model.param.evaluate('rho_app_cylin*2.7778e-7');

    % Store the result
    rho_app_results(i) = rho_app;
end

%% Plot
figure;

lw = 1;
color1 = [0.8500, 0.3250, 0.0980]; % Orange
color2 = [0, 0.4470, 0.7410]; % Blue
color3 = [0.4660 0.6740 0.1880]; % Green

% Charging Time Plot
yyaxis left;
plot(charging_time_coordinates_tubular(1,:), charging_time_coordinates_tubular(2,:), 'Color', color1, 'LineStyle', '-', 'LineWidth', lw, 'DisplayName', 'Tubular cell');
hold on;
plot(charging_time_coordinates_cylinder(1,:), charging_time_coordinates_cylinder(2,:), 'Color', color2, 'LineStyle', '-', 'LineWidth', lw, 'DisplayName', 'Cylindrical cell');
xlabel('D_{out} [mm]', 'FontSize', 10);
ylabel('Charging Time [min]', 'FontSize', 10);
grid on;
ax = gca;
ax.YColor = 'k';

yyaxis right;
plot(R_out_values*2, rho_app_results(1,:), 'Color', color3, 'LineWidth', lw, 'DisplayName', 'Apparent energy density');
ylabel('Apparent Energy Density [kWh/m^3]', 'FontSize', 10);
ax.YColor = color3;

legend('Location', 'southeast');
legend boxon;
% title('Optimal Battery Diameter and Energy Density Comparison', 'FontWeight', 'bold', 'FontSize', 11);


exportgraphics(gcf, 'figure4_new.png', 'Resolution', 300);
