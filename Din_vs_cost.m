clear; clc; close all;

% Define fixed D_out values in mm
D_out_values_mm = [46, 60, 80]; % [mm]

% Define R_in values in mm
R_in_values_mm = 0:0.5:10; % [mm]
D_in_values_mm = 2 * R_in_values_mm; % [mm]

% Preallocate result arrays for each D_out
c_cell_46 = zeros(size(R_in_values_mm));      % [$/kWh]
c_cell_60 = zeros(size(R_in_values_mm));      % [$/kWh]
c_cell_80 = zeros(size(R_in_values_mm));      % [$/kWh]
C_cell_46 = zeros(size(R_in_values_mm));      % [$]
C_cell_60 = zeros(size(R_in_values_mm));      % [$]
C_cell_80 = zeros(size(R_in_values_mm));      % [$]

% Constants
C_JR = 77244.5;               % [$/m³]
C_const = 0.510586145;        % [$]
E_cell_factor = 813.1;        % [kWh/m³]

% Fixed Parameters
h_jr = 2;                      % [mm]

% Define colors for plotting
color1 = [0.9290, 0.6940, 0.1250]; % Yellow - 46 mm
color2 = [0.4940, 0.1840, 0.5560]; % Purple - 60 mm
color3 = [0.4660, 0.6740, 0.1880]; % Green - 80 mm

% Create figure
figure;
hold on;

% Initialize yyaxis
yyaxis left;
xlabel('D_{in} [mm]', 'FontSize', 10);
xlim([4 20]);
ylabel('c_{cell} [$/kWh]', 'FontSize', 10);
ylim([96 103]);
set(gca, 'YColor', 'k');
grid on;
box on;

% Prepare for right y-axis
yyaxis right;
ylabel('C_{cell} [$]', 'FontSize', 10);
ylim([5 45]);
set(gca, 'YColor', 'k');
grid on;
box on;

% Loop over each D_out and compute c_cell and C_cell
for j = 1:length(D_out_values_mm)
    D_out_mm = D_out_values_mm(j);
    R_out_mm = D_out_mm / 2; % [mm]
    R_out = R_out_mm / 1000; % [m]
    
    % Compute H_jr based on the given relationship
    H_jr_mm = (15/14)*R_out_mm + 55.5 - 2*h_jr; % [mm]
    H_jr = H_jr_mm / 1000; % [m]
    
    % Select appropriate variables based on D_out
    switch D_out_mm
        case 46
            c_cell = @() c_cell_46;
            C_cell_var = @() C_cell_46;
            color = color1;
        case 60
            c_cell = @() c_cell_60;
            C_cell_var = @() C_cell_60;
            color = color2;
        case 80
            c_cell = @() c_cell_80;
            C_cell_var = @() C_cell_80;
            color = color3;
        otherwise
            error('Unexpected D_out value.');
    end
    
    % Loop over each R_in
    for i = 1:length(R_in_values_mm)
        R_in_mm = R_in_values_mm(i);
        R_in = R_in_mm / 1000; % [m]
        
        % Volume of Jelly Roll
        V_jr = pi * (R_out^2 - R_in^2) * H_jr; % [m³]
        
        % Calculate C_cell and E_cell
        C_cell_val = C_JR * V_jr + C_const;     % [$]
        E_cell = E_cell_factor * V_jr;          % [kWh]
        
        % Calculate c_cell
        current_c_cell = C_cell_val / E_cell;   % [$/kWh]
        
        % Assign to the appropriate preallocated array
        switch D_out_mm
            case 46
                c_cell_46(i) = current_c_cell;
                C_cell_46(i) = C_cell_val;
            case 60
                c_cell_60(i) = current_c_cell;
                C_cell_60(i) = C_cell_val;
            case 80
                c_cell_80(i) = current_c_cell;
                C_cell_80(i) = C_cell_val;
        end
    end
    
    % Plot c_cell on left y-axis
    lw = 1;
    marker_indices = find(mod(D_in_values_mm, 2) == 0);

    yyaxis left;
    switch D_out_mm
        case 46
            plot(D_in_values_mm, c_cell_46, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'DisplayName', 'c_{cell} 46mm');
        case 60
            plot(D_in_values_mm, c_cell_60, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'DisplayName', 'c_{cell} 60mm');
        case 80
            plot(D_in_values_mm, c_cell_80, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'DisplayName', 'c_{cell} 80mm');
    end
    
    % Plot C_cell on right y-axis
    yyaxis right;
    switch D_out_mm
        case 46
            plot(D_in_values_mm, C_cell_46, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_indices, 'DisplayName', 'C_{cell} 46 mm');
        case 60
            plot(D_in_values_mm, C_cell_60, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_indices, 'DisplayName', 'C_{cell} 60 mm');
        case 80
            plot(D_in_values_mm, C_cell_80, 'Color', color, ...
                'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_indices, 'DisplayName', 'C_{cell} 80 mm');
    end
end


% Combine legends
legend_entries = {
    'c_{cell} 46mm', 'c_{cell} 60mm', ...
    'c_{cell} 80mm', 'C_{cell} 46mm', ...
    'C_{cell} 60mm', 'C_{cell} 80mm'
};
legend(legend_entries, 'Location', 'northeast', 'NumColumns', 2, 'FontSize', 8);

% Save the figure
exportgraphics(gcf, 'figure4e.png', 'Resolution', 300);

hold off;

