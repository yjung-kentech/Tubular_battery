clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_0814.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

R_out_values = [23, 30, 40];
R_in_values = 1:10;

% Initialize a matrix to store results
Q_cell_results = zeros(length(R_in_values), length(R_out_values));

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
        Q_cell = model.param.evaluate('cell2D_Q');

        % Store the result
        Q_cell_results(j, i) = Q_cell;
    end
end

% Normalization of Q_cell_results so that each graph starts at 1
Q_cell_results_normalized = Q_cell_results ./ Q_cell_results(1, :);

% Plot the normalized results
figure;
hold on;
for i = 1:length(R_out_values)
    plot(R_in_values*2, Q_cell_results_normalized(:, i), 'DisplayName', ['D_{out} = ' num2str(2*R_out_values(i)) ' mm'], 'LineWidth', 1);
end
xlabel('D_{in} [mm]');
ylabel('Normalized Cell Capacity');
legend('Location', 'best');
title('Normalized Cell Capacity vs. D_{in} for different D_{out} values');
grid on;
hold off;

ax = gca;
ax.Box = 'on';

exportgraphics(gcf, 'figure1_normalized.png', 'Resolution', 300);
