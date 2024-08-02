clear; clc; close all;

%% 데이터 읽기
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout.mat');

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

%% Plot
figure
plot(charging_time_coordinates_tubular(1,:), charging_time_coordinates_tubular(2,:), 'r', 'LineWidth', 1, 'DisplayName', 'Tubular Curve');
hold on;
plot(charging_time_coordinates_cylinder(1,:), charging_time_coordinates_cylinder(2,:), 'b', 'LineWidth', 1, 'DisplayName', 'Cylinder Curve');
xlabel('D_{out} (mm)', 'FontWeight', 'bold');
ylabel('Charging Time (min)', 'FontWeight', 'bold');
title('Optimal Battery Diameter', 'FontSize', 12);

legend('show', 'Location', 'northwest', 'FontWeight', 'bold', 'FontSize', 10);
legend boxon;

grid on;
