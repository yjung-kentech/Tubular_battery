clear; clc; close all;

% Define R_out values in mm
R_out_values_mm = 5:0.5:40; % [mm]

% Preallocate result arrays
c_cell_tube = zeros(length(R_out_values_mm), 1);        % [$/kWh] for Tube
c_cell_cylinder = zeros(length(R_out_values_mm), 1);    % [$/kWh] for Cylinder
C_cell_tube = zeros(length(R_out_values_mm), 1);        % [$] for Tube
C_cell_cylinder = zeros(length(R_out_values_mm), 1);    % [$] for Cylinder

% Constants
C_JR = 77244.5;               % [$/m³]
C_const = 0.510586145;        % [$]
E_cell_factor = 813.1;        % [kWh/m³]

% Fixed Parameters for model1 (Tube)
R_in_tube_mm = 3;              % [mm]
R_in_tube = R_in_tube_mm / 1000; % [m]

% Loop over R_out values
for i = 1:length(R_out_values_mm)
    R_out_mm = R_out_values_mm(i);
    R_out = R_out_mm / 1000; % [m]
    
    %% Compute H_jr based on the given relationship
    % H_jr = (15/14)*x + 55.5 - 2*h_jr, where h_jr = 2 mm
    h_jr = 2; % [mm]
    H_jr_mm = (15/14)*R_out_mm + 55.5 - 2*h_jr; % [mm]
    H_jr = H_jr_mm / 1000; % [m]
    
    %% Model1 (Tube) Calculations
    % Volume of Jelly Roll for Tube
    V_jr_tube = pi * (R_out^2 - (R_in_tube_mm/1000)^2) * H_jr; % [m³]
    
    % Calculate C_cell and E_cell for Tube
    C_cell_tube_val = C_JR * V_jr_tube + C_const;         % [$]
    E_cell_tube = E_cell_factor * V_jr_tube;              % [kWh]
    c_cell_tube(i) = C_cell_tube_val / E_cell_tube;       % [$/kWh]
    
    % Store C_cell_tube
    C_cell_tube(i) = C_cell_tube_val;                     % [$]
    
    %% Model2 (Cylinder) Calculations
    % Determine R_in for Cylinder based on R_out
    if R_out_mm <= 9
        R_in_cyl_mm = 1; % [mm]
    elseif R_out_mm <= 23
        R_in_cyl_mm = 1 + (R_out_mm - 9) / 14; % [mm]
    else
        R_in_cyl_mm = 2; % [mm]
    end
    R_in_cyl = R_in_cyl_mm / 1000; % [m]
    
    % Volume of Jelly Roll for Cylinder
    V_jr_cyl = pi * (R_out^2 - R_in_cyl^2) * H_jr;    % [m³]
    
    % Calculate C_cell and E_cell for Cylinder
    C_cell_cyl_val = C_JR * V_jr_cyl + C_const;           % [$]
    E_cell_cyl = E_cell_factor * V_jr_cyl;                % [kWh]
    c_cell_cylinder(i) = C_cell_cyl_val / E_cell_cyl;    % [$/kWh]
    
    % Store C_cell_cylinder
    C_cell_cylinder(i) = C_cell_cyl_val;                  % [$]
    
    % Display progress
    fprintf('Processed R_out = %d mm (R_in_cyl = %.2f mm), H_jr = %.3f m\n', ...
        R_out_mm, R_in_cyl_mm, H_jr);
end

%% Prepare Data for Plotting
D_out_mm = 2 * R_out_values_mm; % [mm]
marker_indices = find(mod(D_out_mm, 5) == 0);

%% Plot c_cell vs D_out
lw = 1; % Desired line width
color1 = [0.8500, 0.3250, 0.0980]; % Orange
color2 = [0, 0.4470, 0.7410]; % Blue

yyaxis left;
plot(D_out_mm, c_cell_tube, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'DisplayName', 'c_{cell} Tube');
hold on
plot(D_out_mm, c_cell_cylinder, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_indices, 'DisplayName', 'c_{cell} Cylinder');
ylabel('c_{cell} [$/kWh]', 'FontSize', 10);
ylim([80 150]);
set(gca, 'YColor', 'k');

yyaxis right;
plot(D_out_mm, C_cell_tube, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_indices, 'DisplayName', 'C_{cell} Tube');
plot(D_out_mm, C_cell_cylinder, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_indices, 'DisplayName', 'C_{cell} Cylinder');
hold off
ylabel('C_{cell} [$]', 'FontSize', 10);
set(gca, 'YColor', 'k');

xlabel('D_{out} [mm]', 'FontSize', 10);
legend('Location', 'southeast', 'NumColumns', 2, 'FontSize', 8);
grid on;

exportgraphics(gcf, 'figure4b.png', 'Resolution', 300);