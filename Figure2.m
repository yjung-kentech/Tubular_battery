clear; clc; close all;

% 데이터 경로 설정
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout_1202.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_1202.mat');

% 데이터 로드
load(tubular_file);
tube_data = data;

load(cylinder_file);
cyl_data = data;

% D_out과 C_rate 추출
D_out_vec_tube = 2 * tube_data.R_out;
C_rate_vec_tube = tube_data.C_rate;

D_out_vec_cyl = 2 * cyl_data.R_out;
C_rate_vec_cyl = cyl_data.C_rate;

% 4C와 6C 인덱스 찾기
idx_4C_tube = find(C_rate_vec_tube == 4);
idx_6C_tube = find(C_rate_vec_tube == 6);

idx_4C_cyl = find(C_rate_vec_cyl == 4);
idx_6C_cyl = find(C_rate_vec_cyl == 6);

% 4C 및 6C의 T_max와 T_avg 추출
T_max_4C_tube = tube_data.T_max(idx_4C_tube, :);
T_avg_4C_tube = tube_data.T_avg(idx_4C_tube, :);
T_max_6C_tube = tube_data.T_max(idx_6C_tube, :);
T_avg_6C_tube = tube_data.T_avg(idx_6C_tube, :);

T_max_4C_cyl = cyl_data.T_max(idx_4C_cyl, :);
T_avg_4C_cyl = cyl_data.T_avg(idx_4C_cyl, :);
T_max_6C_cyl = cyl_data.T_max(idx_6C_cyl, :);
T_avg_6C_cyl = cyl_data.T_avg(idx_6C_cyl, :);

% 원하는 마커 간격 정의 (예: 5mm)
desired_marker_interval = 5; % mm

% 보간을 위한 등간격 D_out 벡터 생성 (예: 1mm 간격)
interp_interval = 1; % mm
D_out_interp_tube = min(D_out_vec_tube):interp_interval:max(D_out_vec_tube);
D_out_interp_cyl = min(D_out_vec_cyl):interp_interval:max(D_out_vec_cyl);

% 4C 데이터 보간
T_max_4C_tube_interp = interp1(D_out_vec_tube, T_max_4C_tube, D_out_interp_tube, 'linear');
T_avg_4C_tube_interp = interp1(D_out_vec_tube, T_avg_4C_tube, D_out_interp_tube, 'linear');

T_max_4C_cyl_interp = interp1(D_out_vec_cyl, T_max_4C_cyl, D_out_interp_cyl, 'linear');
T_avg_4C_cyl_interp = interp1(D_out_vec_cyl, T_avg_4C_cyl, D_out_interp_cyl, 'linear');

% 6C 데이터 보간
T_max_6C_tube_interp = interp1(D_out_vec_tube, T_max_6C_tube, D_out_interp_tube, 'linear');
T_avg_6C_tube_interp = interp1(D_out_vec_tube, T_avg_6C_tube, D_out_interp_tube, 'linear');

T_max_6C_cyl_interp = interp1(D_out_vec_cyl, T_max_6C_cyl, D_out_interp_cyl, 'linear');
T_avg_6C_cyl_interp = interp1(D_out_vec_cyl, T_avg_6C_cyl, D_out_interp_cyl, 'linear');

% 보간된 데이터로 마커 인덱스 계산
marker_douts_tube = min(D_out_interp_tube):desired_marker_interval:max(D_out_interp_tube);
marker_indices_tube = arrayfun(@(x) find(abs(D_out_interp_tube - x) == min(abs(D_out_interp_tube - x)), 1), marker_douts_tube);

marker_douts_cyl = min(D_out_interp_cyl):desired_marker_interval:max(D_out_interp_cyl);
marker_indices_cyl = arrayfun(@(x) find(abs(D_out_interp_cyl - x) == min(abs(D_out_interp_cyl - x)), 1), marker_douts_cyl);

% 중복 인덱스 제거 및 정렬
marker_indices_tube = unique(marker_indices_tube);
marker_indices_cyl = unique(marker_indices_cyl);

% 플롯 설정
figure;

% 4C 플롯
subplot(2, 1, 1)
lw = 1; % 선 너비
color1 = [0.8500, 0.3250, 0.0980]; % 오렌지
color2 = [0, 0.4470, 0.7410]; % 파랑

% 튜브 T_max 보간 데이터 플롯
plot(D_out_interp_tube, T_max_4C_tube_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{max}')
hold on
% 튜브 T_avg 보간 데이터 플롯
plot(D_out_interp_tube, T_avg_4C_tube_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{avg}')
% 실린더 T_max 보간 데이터 플롯
plot(D_out_interp_cyl, T_max_4C_cyl_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{max}')
% 실린더 T_avg 보간 데이터 플롯
plot(D_out_interp_cyl, T_avg_4C_cyl_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{avg}')
hold off

xlabel('D_{out} [mm]', 'FontSize', 10);
ylabel('Temperature [^oC]', 'FontSize', 10);
ylim([20 100]);
title('4C', 'FontSize', 11);
legend('Location', 'northwest');
grid on;

% 라벨 a 추가
text(min(D_out_interp_tube)-10, max(T_max_4C_tube_interp)+20, 'a', ...
     'FontSize', 15, 'FontWeight', 'bold', 'Clipping', 'off')

% 6C 플롯
subplot(2, 1, 2)
% 튜브 T_max 보간 데이터 플롯
plot(D_out_interp_tube, T_max_6C_tube_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{max}')
hold on
% 튜브 T_avg 보간 데이터 플롯
plot(D_out_interp_tube, T_avg_6C_tube_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{avg}')
% 실린더 T_max 보간 데이터 플롯
plot(D_out_interp_cyl, T_max_6C_cyl_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{max}')
% 실린더 T_avg 보간 데이터 플롯
plot(D_out_interp_cyl, T_avg_6C_cyl_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{avg}')
hold off

xlabel('D_{out} [mm]', 'FontSize', 10);
ylabel('Temperature [^oC]', 'FontSize', 10);
ylim([20 100]);
title('6C', 'FontSize', 11);
legend('Location', 'northwest');
grid on;

% 라벨 b 추가
text(min(D_out_interp_tube)-10, max(T_max_4C_tube_interp)+20, 'b', ...
     'FontSize', 15, 'FontWeight', 'bold', 'Clipping', 'off')

% 그림 크기 설정
set(gcf, 'Position', [100, 100, 600, 700]);

% 그림 저장
exportgraphics(gcf, 'figure2_1202.png', 'Resolution', 300);

%% D_out 10mm, 80mm에서의 온도

% 찾고자 하는 D_out 값 설정
D_out_target = [10, 80]; % mm

% 튜블러 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (4C)
idx_tube_10_4C = find(abs(D_out_interp_tube - D_out_target(1)) == min(abs(D_out_interp_tube - D_out_target(1))), 1);
idx_tube_80_4C = find(abs(D_out_interp_tube - D_out_target(2)) == min(abs(D_out_interp_tube - D_out_target(2))), 1);

% 튜블러 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (6C)
idx_tube_10_6C = find(abs(D_out_interp_tube - D_out_target(1)) == min(abs(D_out_interp_tube - D_out_target(1))), 1);
idx_tube_80_6C = find(abs(D_out_interp_tube - D_out_target(2)) == min(abs(D_out_interp_tube - D_out_target(2))), 1);

% 실린더 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (4C)
idx_cyl_10_4C = find(abs(D_out_interp_cyl - D_out_target(1)) == min(abs(D_out_interp_cyl - D_out_target(1))), 1);
idx_cyl_80_4C = find(abs(D_out_interp_cyl - D_out_target(2)) == min(abs(D_out_interp_cyl - D_out_target(2))), 1);

% 실린더 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (6C)
idx_cyl_10_6C = find(abs(D_out_interp_cyl - D_out_target(1)) == min(abs(D_out_interp_cyl - D_out_target(1))), 1);
idx_cyl_80_6C = find(abs(D_out_interp_cyl - D_out_target(2)) == min(abs(D_out_interp_cyl - D_out_target(2))), 1);

% 각 셀의 Tmax와 Tavg 값을 출력
fprintf('4C Condition:\n');
fprintf('Tubular Cell:\n');
fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube_10_4C), T_avg_4C_tube_interp(idx_tube_10_4C));
fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube_80_4C), T_avg_4C_tube_interp(idx_tube_80_4C));

fprintf('Cylindrical Cell:\n');
fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl_10_4C), T_avg_4C_cyl_interp(idx_cyl_10_4C));
fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl_80_4C), T_avg_4C_cyl_interp(idx_cyl_80_4C));

fprintf('\n6C Condition:\n');
fprintf('Tubular Cell:\n');
fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_tube_interp(idx_tube_10_6C), T_avg_6C_tube_interp(idx_tube_10_6C));
fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_tube_interp(idx_tube_80_6C), T_avg_6C_tube_interp(idx_tube_80_6C));

fprintf('Cylindrical Cell:\n');
fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_cyl_interp(idx_cyl_10_6C), T_avg_6C_cyl_interp(idx_cyl_10_6C));
fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_cyl_interp(idx_cyl_80_6C), T_avg_6C_cyl_interp(idx_cyl_80_6C));

