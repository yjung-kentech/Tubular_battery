clear;clc;close all

% 데이터 로드
data_dir = 'C:\Users\user\Desktop\Tubular cell';
data_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_Result.mat');
load(data_file);

C_rate_vec = data.C_rate;
D_out_vec = 2 * data.R_out;

% 최대 온도 데이터
T_max_data = data.T_max;

% 등고선 데이터 추출 (T_max = 50°C)
T_allowed = 50;
contour_data = contourc(D_out_vec, C_rate_vec, T_max_data, [T_allowed T_allowed]);

% 등고선 데이터에서 특정 높이(Z 값)에 해당하는 점 추출
i = 1;
x_points = [];
y_points = [];
while i < size(contour_data, 2)
    Z_level = contour_data(1, i); % 등고선의 높이
    num_points = contour_data(2, i); % 곡지점 개수
    
    if Z_level == T_allowed
        x_points = [x_points contour_data(1, i+1:i+num_points)];
        y_points = [y_points contour_data(2, i+1:i+num_points)];
    end
    
    i = i + num_points + 1;
end

% 추출된 점의 크기 확인
% if isempty(x_points) || isempty(y_points)
%     error('No points found for the specified T_max level. Adjust the T_allowed value.');
% end

% 충전 시간 데이터 추출
charging_time_data = data.t95;
charging_time_points = [];
valid_x_points = [];

for k = 1:length(x_points)
    [~, idx_D_out] = min(abs(D_out_vec - x_points(k)));
    [~, idx_C_rate] = min(abs(C_rate_vec - y_points(k)));
    
    if idx_D_out <= size(charging_time_data, 1) && idx_C_rate <= size(charging_time_data, 2)
        charging_time_points = [charging_time_points; charging_time_data(idx_D_out, idx_C_rate)];
        valid_x_points = [valid_x_points; x_points(k)];
    else
        warning('Index exceeds matrix dimensions at D_out = %f, C_rate = %f', x_points(k), y_points(k));
    end
end

% 유효한 점의 크기 확인
if isempty(valid_x_points) || isempty(charging_time_points)
    error('No valid points found for the specified T_max level within the matrix dimensions.');
end

% 데이터 시각화
figure;

% 추출한 점들을 사용하여 곡선 맞추기
fit_result = polyfit(valid_x_points, charging_time_points, 2); % 2차 다항식 맞춤
curve_x = linspace(min(valid_x_points), max(valid_x_points), 100);
curve_y = polyval(fit_result, curve_x);

% 맞춘 곡선 플롯
plot(curve_x, curve_y, 'b-', 'DisplayName', 'Tubular Curve');
hold on;

% 원래 데이터 포인트도 시각화
scatter(valid_x_points, charging_time_points, 'bo', 'DisplayName', 'Tubular Points');

xlabel('D_{out} (mm)', 'FontWeight', 'bold');
ylabel('Charging Time (min)', 'FontWeight', 'bold');
title('Optimal Battery Diameter', 'FontWeight', 'bold');
legend('Location', 'northwest');
grid on;
hold off;