clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'Tubular pack_8cell';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

model.study('std1').run

% 결과 저장 또는 처리
time = mphglobal(model, 't', 'unit', 'min');

% Average Temperature
Tavg_cell1 = mphglobal(model, 'Tavg_cell1', 'unit', 'degC');
Tavg_cell2 = mphglobal(model, 'Tavg_cell2', 'unit', 'degC');
Tavg_cell3 = mphglobal(model, 'Tavg_cell3', 'unit', 'degC');
Tavg_cell4 = mphglobal(model, 'Tavg_cell4', 'unit', 'degC');
Tavg_cell5 = mphglobal(model, 'Tavg_cell5', 'unit', 'degC');
Tavg_cell6 = mphglobal(model, 'Tavg_cell6', 'unit', 'degC');
Tavg_cell7 = mphglobal(model, 'Tavg_cell7', 'unit', 'degC');
Tavg_cell8 = mphglobal(model, 'Tavg_cell8', 'unit', 'degC');

% Maximum Temeprature
Tmax_cell1 = mphglobal(model, 'Tmax_cell1', 'unit', 'degC');
Tmax_cell2 = mphglobal(model, 'Tmax_cell2', 'unit', 'degC');
Tmax_cell3 = mphglobal(model, 'Tmax_cell3', 'unit', 'degC');
Tmax_cell4 = mphglobal(model, 'Tmax_cell4', 'unit', 'degC');
Tmax_cell5 = mphglobal(model, 'Tmax_cell5', 'unit', 'degC');
Tmax_cell6 = mphglobal(model, 'Tmax_cell6', 'unit', 'degC');
Tmax_cell7 = mphglobal(model, 'Tmax_cell7', 'unit', 'degC');
Tmax_cell8 = mphglobal(model, 'Tmax_cell8', 'unit', 'degC');

save('cell_temp_difference.mat', 'time', 'Tavg_cell1', 'Tavg_cell2', 'Tavg_cell3', ...
    'Tavg_cell4', 'Tavg_cell5', 'Tavg_cell6', 'Tavg_cell7', 'Tavg_cell8', ...
    'Tmax_cell1', 'Tmax_cell2', 'Tmax_cell3', 'Tmax_cell4', ...
    'Tmax_cell5', 'Tmax_cell6', 'Tmax_cell7', 'Tmax_cell8');

load('cell_temp_difference.mat');

% Tmax 및 Tavg 중 최대 및 최소 값 찾기
Tavg_all = [Tavg_cell1'; Tavg_cell2'; Tavg_cell3'; Tavg_cell4'; Tavg_cell5'; Tavg_cell6'; Tavg_cell7'; Tavg_cell8'];
Tmax_all = [Tmax_cell1'; Tmax_cell2'; Tmax_cell3'; Tmax_cell4'; Tmax_cell5'; Tmax_cell6'; Tmax_cell7'; Tmax_cell8'];

[max_Tavg, max_Tavg_idx] = max(mean(Tavg_all, 2));
[min_Tavg, min_Tavg_idx] = min(mean(Tavg_all, 2));
[max_Tmax, max_Tmax_idx] = max(mean(Tmax_all, 2));
[min_Tmax, min_Tmax_idx] = min(mean(Tmax_all, 2));

% 8개의 색상 집합
color_map_tmax = [...
    0.3, 0.6, 0.5;   % Muted Teal Green
    0.6, 0.3, 0.8;   % Lavender
    0.3, 0.8, 0.3;   % Mint Green
    0.9, 0.7, 0.2;   % Warm Gold
    0.3, 0.8, 0.8;   % Light Cyan
    0.8, 0.4, 0.3;   % Coral
    0.6, 0.8, 0.7    % Soft Sage Green
    70/255, 130/255, 180/255;  % Deep Sky Blue
];

% 8개의 색상 집합
color_map_tavg = [...
    0.7, 0.6, 0.9;   % Pastel Lavender
    0.2, 0.6, 0.8;   % Sky Blue
    0.7, 0.3, 0.8;   % Medium Purple
    0.4, 0.8, 0.4;   % Pale Green
    0.9, 0.8, 0.2;   % Soft Yellow
    0.6, 0.9, 0.9;   % Turquoise
    0.8, 0.6, 0.8;   % Lilac
    0.9, 0.5, 0.3    % Peach
];

% 그래프 그리기
figure;
lw = 0.55;        % 일반 선의 두께
bold_lw = 1.15; % 굵은 선의 두께

hold on;

% Tmax 및 Tavg 플롯

for i = 1:size(Tmax_all, 1)
    % 최대 온도 플롯
    if i == max_Tmax_idx
        plot(time, Tmax_all(i, :), 'Color', color_map_tmax(i, :), 'LineWidth', bold_lw, 'DisplayName', ['Tmax Cell ', num2str(i), ' (Max)']);
    elseif i == min_Tmax_idx
        plot(time, Tmax_all(i, :), 'Color', color_map_tmax(i, :), 'LineWidth', bold_lw, 'DisplayName', ['Tmax Cell ', num2str(i), ' (Min)']);
    else
        plot(time, Tmax_all(i, :), 'Color', color_map_tmax(i, :), 'LineWidth', lw, 'DisplayName', ['Tmax Cell ', num2str(i)]);
    end
end

for i = 1:size(Tavg_all, 1)
    % 평균 온도 플롯
    if i == max_Tavg_idx
        plot(time, Tavg_all(i, :), 'Color', color_map_tavg(i, :), 'LineWidth', bold_lw, 'DisplayName', ['Tavg Cell ', num2str(i), ' (Max)']);
    elseif i == min_Tavg_idx
        plot(time, Tavg_all(i, :), 'Color', color_map_tavg(i, :), 'LineWidth', bold_lw, 'DisplayName', ['Tavg Cell ', num2str(i), ' (Min)']);
    else
        plot(time, Tavg_all(i, :), 'Color', color_map_tavg(i, :), 'LineWidth', lw, 'DisplayName', ['Tavg Cell ', num2str(i)]);
    end
end

box on;

hold off;

% 범례 및 라벨 설정
legend('show', 'Location', 'best');
title('Temperature Difference Between Cells');
xlabel('Time [min]');
ylabel('Temperature [degC]');
grid on;

% 그래프 저장
exportgraphics(gcf, '셀간온도편차.png', 'Resolution', 300);
