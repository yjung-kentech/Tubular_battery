clear; clc; close all;

%% 데이터 읽기
data_dir = 'C:\Users\user\Desktop\Tubular cell';
data_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout_Result.mat');
load(data_file);

C_rate_vec = data.C_rate;
D_out_vec = 2 * data.R_out;

%% 추가 변수 계산
% 1. SOC 기준 충족 여부
ismat_soc = data.SOC;

% 2. 리튬 플레이트 조건 충족 여부
Elpcut = 0;
ismat_nlp = double(data.Elp_min > Elpcut);

% 3. 온도 조건 충족 여부
T_allowed = 50;
ismat_Tmax = double(data.T_max < T_allowed);

%% 등고선 좌표 추출
% Elp_min = Elpcut에 대한 등고선 좌표 추출
M_Elp = contour(D_out_vec, C_rate_vec, data.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x = M_Elp(1, 2:end);
Elp_y = M_Elp(2, 2:end);

% T_max = T_allowed에 대한 등고선 좌표 추출
M_Tmax = contour(D_out_vec, C_rate_vec, data.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x = M_Tmax(1, 2:end);
Tmax_y = M_Tmax(2, 2:end);

%% 좌표 정렬 및 보간
% Elp 좌표 정렬
[Elp_x, idx] = sort(Elp_x);
Elp_y = Elp_y(idx);

% Tmax 좌표 정렬
[Tmax_x, idx] = sort(Tmax_x);
Tmax_y = Tmax_y(idx);

% 보간을 통한 좌표 간격 1로 만들기
Elp_xq = min(Elp_x):1:max(Elp_x);
Elp_yq = interp1(Elp_x, Elp_y, Elp_xq, 'linear');

Tmax_xq = 30:1:max(Tmax_x);
Tmax_yq = interp1(Tmax_x, Tmax_y, Tmax_xq, 'linear');

Elp_coordinates = [Elp_xq; Elp_yq];
Tmax_coordinates = [Tmax_xq; Tmax_yq];

%% Merging coordinates and selecting the minimum y-value for each x-value
all_x = unique([Elp_xq, Tmax_xq]);
min_y = arrayfun(@(x) min([interp1(Elp_x, Elp_y, x, 'linear', inf), interp1(Tmax_x, Tmax_y, x, 'linear', inf)]), all_x);
min_y_coordinates = [all_x; min_y];

%% Interpolating charging time using min_y values
charging_time = arrayfun(@(x, y) interp2(D_out_vec, C_rate_vec, data.t95, x, y, 'linear', inf), all_x, min_y);

charging_time_coordinates = [all_x; charging_time];

%% Plot
figure
plot(charging_time_coordinates(1,:), charging_time_coordinates(2,:), 'r', 'LineWidth', 1);
xlabel('D_{out} (mm)', 'FontWeight', 'bold');
ylabel('Charging Time (min)', 'FontWeight', 'bold');
title('Optimal Battery Diameter')

% grid on;

legend('Tubular Curve', 'Location', 'northwest', 'FontWeight', 'bold', 'FontSize', 10);
legend boxon;
