clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'Tubular pack_8cell';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

C_rate = 5;
R_out = 23;
R_in = 2;

R_out_str = [num2str(R_out) '[mm]'];
R_in_str = [num2str(R_in) '[mm]'];

V_in_values = 0.1:0.3:4;

% Initialize structures to store results
data.T_max = zeros(1, length(V_in_values));
data.T_avg = zeros(1, length(V_in_values));
data.P_outlet = zeros(1, length(V_in_values));
data.P_inlet = zeros(1, length(V_in_values));

for i = 1:length(V_in_values)
    V_in = V_in_values(i);
    V_in_str = [num2str(V_in) '[m/s]'];

    model.param.set('C_rate', C_rate);
    model.param.set('R_out', R_out_str);
    model.param.set('R_in', R_in_str);
    model.param.set('V_in', V_in_str);

    model.study('std1').run;

    % Store the maximum value for each parameter
    data.T_max(i) = max(mphglobal(model, 'T_max', 'unit', 'degC'));
    data.T_avg(i) = max(mphglobal(model, 'T_avg', 'unit', 'degC'));
    data.Pin_top(i) = max(mphglobal(model, 'Pin_top', 'unit', 'Pa'));
    data.Pin_side(i) = max(mphglobal(model, 'Pin_side', 'unit', 'Pa'));
end

% Save results to .mat file
save('velocity_temp_pressure.mat', 'V_in_values', 'data');

% data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
% data_file = fullfile(data_dir, 'velocity_temp_pressure.mat');
% load(data_file, 'V_in_values', 'data');

% Interpolation
V_in_interp = linspace(min(V_in_values), max(V_in_values), 100);

T_max_interp = interp1(V_in_values, data.T_max, V_in_interp, 'spline');
T_avg_interp = interp1(V_in_values, data.T_avg, V_in_interp, 'spline');
Pin_top_interp = interp1(V_in_values, data.Pin_top, V_in_interp, 'spline');
Pin_side_interp = interp1(V_in_values, data.Pin_side, V_in_interp, 'spline');

% Plot
color1 = [0.8500, 0.3250, 0.0980]; % Orange
color2 = [0, 0.4470, 0.7410]; % Blue

figure;
yyaxis left;
plot(V_in_interp, T_max_interp, 'Color', color1, 'DisplayName', 'T_{max}', 'LineWidth', 1);
hold on;
plot(V_in_interp, T_avg_interp, 'Color', color1, 'LineStyle', '--', 'DisplayName', 'T_{avg}', 'LineWidth', 1);
ylabel('Temperature [°C]');
ylim([min(T_avg_interp), max(T_max_interp)]);
set(gca, 'YColor', color1);

yyaxis right;
plot(V_in_interp, Pin_top_interp, 'Color', color2, 'DisplayName', 'P_{in\_top}', 'LineWidth', 1);
plot(V_in_interp, Pin_side_interp, 'Color', color2, 'LineStyle', '--', 'DisplayName', 'P_{in\_side}', 'LineWidth', 1);
ylabel('Pressure [Pa]');
xlim([0.1, 4]);
ylim([min(Pin_side_interp), max(Pin_side_interp)]);
set(gca, 'YColor', color2);

xlabel('Velocity [m/s]');
legend('Location', 'best');
title('Velocity vs. Temp & Pressure');
grid on;
hold off;

exportgraphics(gcf, 'velocity_vs_temp&pressure.png', 'Resolution', 300);

