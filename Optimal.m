clear; clc; close all

%% 데이터 읽기
data_dir = 'C:\Users\user\Desktop\Tubular cell';
data_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_Result.mat');
load(data_file);

C_rate_vec = data.C_rate;
D_out_vec = 2 * data.R_out;

%% 추가 변수 계산

% 2. 리튬 도금 조건 충족 여부 확인
Elpcut = 0;
ismat_nlp = double(data.Elp_min > Elpcut);
contour_nlp = contourf(D_out_vec, C_rate_vec, ismat_nlp, [0.5 0.5]); close
patch_nlp_x = [contour_nlp(1,2:end), D_out_vec(end,1), D_out_vec(1,1)];
patch_nlp_y = [contour_nlp(2,2:end), C_rate_vec(1,end), C_rate_vec(1,end)];

[unique_patch_nlp_x, unique_idx] = unique(patch_nlp_x);
unique_patch_nlp_y = patch_nlp_y(unique_idx);
patch_nlp_x_interp = linspace(min(unique_patch_nlp_x), max(unique_patch_nlp_x));
patch_nlp_y_interp = interp1(unique_patch_nlp_x, unique_patch_nlp_y, patch_nlp_x_interp, 'spline');

% 3. 온도 조건 충족 여부 확인
T_allowed = 50;
ismat_Tmax = double(data.T_max < T_allowed);
contour_Tmax = contourf(D_out_vec, C_rate_vec, ismat_Tmax, [0.5 0.5]); close
patch_Tmax_x = contour_Tmax(1,2:end);
patch_Tmax_y = contour_Tmax(2,2:end);

[unique_patch_Tmax_x, unique_idx] = unique(patch_Tmax_x);
unique_patch_Tmax_y = patch_Tmax_y(unique_idx);
patch_Tmax_x_interp = linspace(min(unique_patch_Tmax_x), max(unique_patch_Tmax_x));
patch_Tmax_y_interp = interp1(unique_patch_Tmax_x, unique_patch_Tmax_y, patch_Tmax_x_interp, 'spline');

%% Tubular Curve 추출
Tubular_x = min(patch_Tmax_x_interp, patch_nlp_x_interp);
Tubular_y = min(patch_Tmax_y_interp, patch_nlp_y_interp);

%% 등고선 행렬에서 Charging Time 데이터 추출
contour_data = contourc(D_out_vec, C_rate_vec, data.t95);
charging_time_x = [];
charging_time_y = [];
index = 1;

while index < size(contour_data, 2)
    num_points = contour_data(2, index);
    contour_level = contour_data(1, index);
    x_values = contour_data(1, index + 1:index + num_points);
    y_values = contour_data(2, index + 1:index + num_points);
    
    % Extracting points that match Tubular curve
    for i = 1:length(Tubular_x)
        distances = sqrt((x_values - Tubular_x(i)).^2 + (y_values - Tubular_y(i)).^2);
        [~, min_idx] = min(distances);
        charging_time_x = [charging_time_x, Tubular_x(i)];
        charging_time_y = [charging_time_y, contour_level];
    end
    
    index = index + num_points + 1;
end

%% 오른쪽 플롯 그리기
figure
plot(charging_time_x, charging_time_y, 'b-', 'LineWidth', 2); % Tubular curve

xlabel('D_{out} (mm)', 'FontWeight', 'bold')
ylabel('Charging Time (min)', 'FontWeight', 'bold')
title('Optimal Battery Diameter', 'FontWeight', 'bold', 'FontSize', 12);
legend({'Tubular Curve'}, 'Location', 'northwest');

hold off