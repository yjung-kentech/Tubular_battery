clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_0909.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

R_out_values = [23, 30, 40];
R_in_values = 1:10;

% Initialize a matrix to store results
rho_app_results = zeros(length(R_in_values), length(R_out_values));

for i = 1:length(R_out_values)
    R_out = R_out_values(i);
    R_out_str = [num2str(R_out) '[mm]'];
    
    for j = 1:length(R_in_values)
        R_in = R_in_values(j);
        R_in_str = [num2str(R_in) '[mm]'];

        % Set the parameters in COMSOL
        model.param.set('R_out', R_out_str);
        model.param.set('R_in', R_in_str);

        % Get the value of cell2D_Q directly from the parameters
        rho_app = model.param.evaluate('rho_app*2.7778e-7');
        rho_app_cylin = model.param.evaluate('rho_app_cylin*2.7778e-7');

        % Store the result
        rho_app_results(j, i) = rho_app;
    end
end

% Plot the results
figure;
hold on;
color1 = [0, 0.4470, 0.7410]; % Blue

plot([0, max(R_in_values*2)], [rho_app_cylin, rho_app_cylin], 'Color', color1, 'DisplayName', 'Cylindrical cell', 'LineWidth', 1);

for i = 1:length(R_out_values)
    plot(R_in_values*2, rho_app_results(:, i), 'DisplayName', ['D_{out} = ' num2str(2*R_out_values(i)) ' mm'], 'LineWidth', 1);
end

xlabel('D_{in} [mm]');
ylabel('Apparent energy density [kWh/m^3]');
legend('Location', 'southwest');
title('Apparent energy density');
grid on;
hold off;

ax = gca;
ax.Box ='on';

exportgraphics(gcf, 'figure5.png', 'Resolution', 300);