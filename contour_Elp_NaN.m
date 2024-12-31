clear; clc; close all;

%% Load the data
data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
data_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout_1227.mat'); % 1202
load(data_file);

C_rate_vec = data.C_rate;
D_out_vec = 2 * data.R_out;

%% Generate a higher resolution grid for interpolation
D_out_high_res = linspace(min(D_out_vec), max(D_out_vec), 500);    % 500 포인트로 세밀한 그리드 생성
C_rate_high_res = linspace(min(C_rate_vec), max(C_rate_vec), 500);

% 2D 그리드 보간
[D_out_grid, C_rate_grid] = meshgrid(D_out_vec, C_rate_vec); 
[D_out_high_grid, C_rate_high_grid] = meshgrid(D_out_high_res, C_rate_high_res);

% Tmax와 Elp_min 데이터 보간
T_max_smooth = interp2(D_out_grid, C_rate_grid, data.T_max, D_out_high_grid, C_rate_high_grid, 'spline');
Elp_min_smooth = interp2(D_out_grid, C_rate_grid, data.Elp_min, D_out_high_grid, C_rate_high_grid, 'spline');

%% Tmax 값을 NaN으로 처리 (100도 이상)
T_allowed = 100;                  
T_max_smooth(T_max_smooth > T_allowed) = NaN;

%% Elp_min에서 Tmax가 NaN인 부분을 NaN으로 처리
Elp_min_smooth(isnan(T_max_smooth)) = NaN;  % Tmax에서 NaN인 구간을 Elp_min에도 반영

%% Plotting results

% Elp_min 그래프 그리기
figure
cmin = min(Elp_min_smooth(:));   % Elp_min의 최소값
cmax = max(Elp_min_smooth(:));   % Elp_min의 최대값
numContours = 20;  % 등고선의 개수

contourf(D_out_high_res, C_rate_high_res, Elp_min_smooth, linspace(cmin, cmax, numContours), 'LineColor', 'none');
clim([cmin cmax]);
colorbar;
hold on;

nan_mask = isnan(T_max_smooth);
[~, hNaN] = contourf(D_out_high_res, C_rate_high_res, double(nan_mask), [0.5 1.5], 'LineColor', 'none');
set(hNaN, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none');

% Tmax = 45도와 lithium plating 등고선 추가
Elpcut = 0;  % Lithium plating 임계값 설정
[~, hElp] = contour(D_out_vec, C_rate_vec, data.Elp_min, [Elpcut, Elpcut], 'LineWidth', 2, 'LineColor', 'w');  % Elp 등고선
[~, hTmax] = contour(D_out_high_res, C_rate_high_res, T_max_smooth, [45, 45], 'LineWidth', 2, 'LineColor', 'r');  % Tmax 45도 등고선

% 축 및 레이블 설정
xlabel('D_{out} [mm]', 'FontSize', 10);
ylabel('C-rate', 'FontSize', 10);
h = colorbar;
ylabel(h, '\phi_{lp} [V]', 'FontSize', 10);
titleHandle = title('Lithium Plating Potential (Tube)'); % Cylinder, Tube 이름 바꾸기
set(titleHandle, 'FontWeight', 'bold', 'FontSize', 11);

% 관심 지점 하이라이트
x = 46; y = 6;
xline(x, '--w', 'LineWidth', 1);
yline(y, '--w', 'LineWidth', 1);
plot(x, y, 'ro', 'MarkerFaceColor', 'r');

% 범례 추가
lgd = legend([hTmax, hElp], {'T_{max} = 45 ^oC', '\phi_{lp} = 0 V'}, 'Location', 'northeast');
set(lgd, 'Color', [0.8, 0.8, 0.8]);
set(lgd, 'EdgeColor', 'black');

% 그래프를 파일로 저장
exportgraphics(gcf, 'Tubular_contour_Elp_1227.png', 'Resolution', 300);

hold off;
