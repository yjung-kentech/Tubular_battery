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
data.Tout_bottom = zeros(1, length(V_in_values));
data.Tout_jr_bottom = zeros(1, length(V_in_values));
data.Tout_side = zeros(1, length(V_in_values));

for i = 1:length(V_in_values)
    V_in = V_in_values(i);
    V_in_str = [num2str(V_in) '[m/s]'];

    model.param.set('C_rate', C_rate);
    model.param.set('R_out', R_out_str);
    model.param.set('R_in', R_in_str);
    model.param.set('V_in', V_in_str);

    model.study('std1').run;

    % Store the maximum value for each parameter
    data.Tout_bottom(i) = max(mphglobal(model, 'Tout_bottom', 'unit', 'degC'));
    data.Tout_jr_bottom(i) = max(mphglobal(model, 'Tout_jr_bottom', 'unit', 'degC'));
    data.Tout_side(i) = max(mphglobal(model, 'Tout_side', 'unit', 'degC'));
end

% Save results to .mat file
save('Coolant_Tout.mat', 'V_in_values', 'data');

% data_dir = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
% data_file = fullfile(data_dir, 'Coolant_Tout.mat');
% load(data_file, 'V_in_values', 'data');

% Interpolation
V_in_interp = linspace(min(V_in_values), max(V_in_values), 100);

T_bottom_interp = interp1(V_in_values, data.Tout_bottom, V_in_interp, 'spline');
T_jr_bottom_interp = interp1(V_in_values, data.Tout_jr_bottom, V_in_interp, 'spline');
T_side_interp = interp1(V_in_values, data.Tout_side, V_in_interp, 'spline');

% Plot
color1 = [0.8500, 0.3250, 0.0980]; % Orange
color2 = [0, 0.4470, 0.7410]; % Blue

figure;
plot(V_in_interp, T_bottom_interp, 'Color', color1, 'DisplayName', 'Tout_{bottom}', 'LineWidth', 1);
hold on;
plot(V_in_interp, T_jr_bottom_interp, 'Color', color1, 'LineStyle', '--', 'DisplayName', 'Tout jr_{bottom}', 'LineWidth', 1);
plot(V_in_interp, T_side_interp, 'Color', color2, 'DisplayName', 'Tout_{side}', 'LineWidth', 1);

xlabel('Velocity [m/s]');
ylabel('Temperature [degC]')
legend('Location', 'best');
title('Coolant T_{out}');
grid on;
box on;
hold off;

exportgraphics(gcf, 'coolant Tout.png', 'Resolution', 300);
