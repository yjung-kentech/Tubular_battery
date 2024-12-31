clear; clc; close all;

%% 1. c_cell 계산 (Tube / Cylinder)

% 반지름 범위 (mm)
R_out_values_mm = 5:0.5:40; 
R_out_values    = R_out_values_mm / 1000;  % [m]
D_out_mm        = 2 * R_out_values_mm;     % [mm]

% 상수 정의
C_JR          = 77244.5;      % [$/m³]
C_const       = 0.510586145;  % [$]
E_cell_factor = 813.1;        % [kWh/m³]
R_in_tube_mm  = 3;            % [mm]
h_jr          = 2;            % [mm]

% 결과 저장용
c_cell_tube      = zeros(length(R_out_values_mm),1);
c_cell_cylinder  = zeros(length(R_out_values_mm),1);
C_cell_tube      = zeros(length(R_out_values_mm),1);
C_cell_cylinder  = zeros(length(R_out_values_mm),1);

% 반복문으로 각 D_out에 대해 부피, 비용 계산
for i = 1:length(R_out_values_mm)
    R_out_mm = R_out_values_mm(i);
    R_out    = R_out_values(i);
    
    % (1) 유효 길이(H_jr) 계산
    H_jr_mm = (15/14)*R_out_mm + 55.5 - 2*h_jr; 
    H_jr    = H_jr_mm / 1000;  % [m]
    
    % (2) Tube 케이스
    V_tube      = pi*(R_out^2 - (R_in_tube_mm/1000)^2)*H_jr;   % [m³]
    cost_tube   = C_JR * V_tube + C_const;                     % [$]
    energy_tube = E_cell_factor * V_tube;                     % [kWh]
    
    C_cell_tube(i) = cost_tube;                % (각 셀의 총 비용)
    c_cell_tube(i) = cost_tube / energy_tube;  % (단위 kWh당 비용)
    
    % (3) Cylinder 케이스
    if R_out_mm <= 9
        R_in_cyl_mm = 1;
    elseif R_out_mm <= 23
        R_in_cyl_mm = 1 + (R_out_mm - 9)/14;  % 1mm ~ 2mm 사이 선형 증분
    else
        R_in_cyl_mm = 2;
    end
    
    R_in_cyl   = R_in_cyl_mm/1000;
    V_cyl      = pi*(R_out^2 - R_in_cyl^2)*H_jr;
    cost_cyl   = C_JR * V_cyl + C_const;
    energy_cyl = E_cell_factor * V_cyl;
    
    C_cell_cylinder(i) = cost_cyl;               
    c_cell_cylinder(i) = cost_cyl / energy_cyl;  
end

%% 2. 시뮬레이션 데이터 로드 + 등고선 기반 t95(충전시간) 추출

data_dir       = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
tubular_file   = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout_1202.mat');
cylinder_file  = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout_1202.mat');

% 파일 로드
load(tubular_file);   tubular_data   = data;
load(cylinder_file);  cylinder_data  = data;

% 등고선 기준값
Elpcut    = 0;
T_allowed = 45;

% --------------------- Tubular ---------------------
M_Elp_tub = contour(2*tubular_data.R_out, tubular_data.C_rate, ...
                    tubular_data.Elp_min, [Elpcut, Elpcut]);
Elp_x_tub = M_Elp_tub(1,2:end);
Elp_y_tub = M_Elp_tub(2,2:end);

M_Tmax_tub = contour(2*tubular_data.R_out, tubular_data.C_rate, ...
                     tubular_data.T_max, [T_allowed, T_allowed]);
Tmax_x_tub = M_Tmax_tub(1,2:end);
Tmax_y_tub = M_Tmax_tub(2,2:end);

[Elp_x_tub, idx]  = sort(Elp_x_tub);
Elp_y_tub         = Elp_y_tub(idx);
[Tmax_x_tub, idx] = sort(Tmax_x_tub);
Tmax_y_tub        = Tmax_y_tub(idx);

Elp_xq_tub  = min(Elp_x_tub):1:max(Elp_x_tub);
Elp_yq_tub  = interp1(Elp_x_tub, Elp_y_tub, Elp_xq_tub, 'linear');

Tmax_xq_tub = 30:1:max(Tmax_x_tub);
Tmax_yq_tub = interp1(Tmax_x_tub, Tmax_y_tub, Tmax_xq_tub, 'linear');

all_x_tub = unique([Elp_xq_tub, Tmax_xq_tub]);
min_y_tub = arrayfun(@(x) min([ ...
    interp1(Elp_x_tub,  Elp_y_tub,   x, 'linear', inf), ...
    interp1(Tmax_x_tub, Tmax_y_tub,  x, 'linear', inf)]), ...
    all_x_tub);

charging_time_tub = arrayfun(@(xx, yy) ...
    interp2(2*tubular_data.R_out, tubular_data.C_rate, tubular_data.t95, ...
    xx, yy, 'linear', inf), ...
    all_x_tub, min_y_tub);

charging_time_coordinates_tub = [all_x_tub; charging_time_tub];  % (D_out, t95)

% --------------------- Cylinder ---------------------
M_Elp_cyl = contour(2*cylinder_data.R_out, cylinder_data.C_rate, ...
                    cylinder_data.Elp_min, [Elpcut, Elpcut]);
Elp_x_cyl = M_Elp_cyl(1,2:end);
Elp_y_cyl = M_Elp_cyl(2,2:end);

M_Tmax_cyl = contour(2*cylinder_data.R_out, cylinder_data.C_rate, ...
                     cylinder_data.T_max, [T_allowed, T_allowed]);
Tmax_x_cyl = M_Tmax_cyl(1,2:end);
Tmax_y_cyl = M_Tmax_cyl(2,2:end);

[Elp_x_cyl, idx]  = sort(Elp_x_cyl);
Elp_y_cyl         = Elp_y_cyl(idx);
[Tmax_x_cyl, idx] = sort(Tmax_x_cyl);
Tmax_y_cyl        = Tmax_y_cyl(idx);

Elp_xq_cyl  = min(Elp_x_cyl):1:max(Elp_x_cyl);
Elp_yq_cyl  = interp1(Elp_x_cyl, Elp_y_cyl, Elp_xq_cyl, 'linear');

Tmax_xq_cyl = 30:1:max(Tmax_x_cyl);
Tmax_yq_cyl = interp1(Tmax_x_cyl, Tmax_y_cyl, Tmax_xq_cyl, 'linear');

all_x_cyl = unique([Elp_xq_cyl, Tmax_xq_cyl]);
min_y_cyl = arrayfun(@(x) min([ ...
    interp1(Elp_x_cyl,  Elp_y_cyl,   x, 'linear', inf), ...
    interp1(Tmax_x_cyl, Tmax_y_cyl,  x, 'linear', inf)]), ...
    all_x_cyl);

charging_time_cyl = arrayfun(@(xx, yy) ...
    interp2(2*cylinder_data.R_out, cylinder_data.C_rate, cylinder_data.t95, ...
    xx, yy, 'linear', inf), ...
    all_x_cyl, min_y_cyl);

charging_time_coordinates_cyl = [all_x_cyl; charging_time_cyl];

%% 3. (D_out -> c_cell / C_cell) 매칭

% [Tubular]
D_out_tub  = charging_time_coordinates_tub(1,:);
T_chg_tub  = charging_time_coordinates_tub(2,:);
c_tub_interp = interp1(D_out_mm, c_cell_tube,  D_out_tub, 'linear', 'extrap');
C_tub_interp = interp1(D_out_mm, C_cell_tube,  D_out_tub, 'linear', 'extrap');

% [Cylinder]
D_out_cyl  = charging_time_coordinates_cyl(1,:);
T_chg_cyl  = charging_time_coordinates_cyl(2,:);
c_cyl_interp = interp1(D_out_mm, c_cell_cylinder, D_out_cyl, 'linear', 'extrap');
C_cyl_interp = interp1(D_out_mm, C_cell_cylinder, D_out_cyl, 'linear', 'extrap');

% 유효 범위 (x축 한계)
valid_tub_times = T_chg_tub(~isinf(T_chg_tub));
valid_cyl_times = T_chg_cyl(~isinf(T_chg_cyl));
if isempty(valid_tub_times), min_tub = inf; else, min_tub = min(valid_tub_times); end
if isempty(valid_cyl_times), min_cyl = inf; else, min_cyl = min(valid_cyl_times); end

x_min = min([min_tub, min_cyl]);
x_max = 20;

% 특이값 제외
c_tub_interp(c_tub_interp >= 101.2526) = NaN;
c_cyl_interp(c_cyl_interp >= 103.7886) = NaN;
C_tub_interp(C_tub_interp <= 8.2683)   = NaN;
C_cyl_interp(C_cyl_interp <= 6.0297)   = NaN;


%% 4. 플롯 (정확히 정수 시점에만 마커 + Legend에 선+마커 아이콘 1개)

% figure('Position',[300 300 600 450]);
lw = 1;
color1 = [0, 0.4470, 0.7410];       % 파란색
color2  = [0.8500, 0.3250, 0.0980];  % 주황색

% "정수 시간" 지정
marker_times = 10:1:20;

% -- 왼쪽 Y축: c_cell [$/kWh] --
yyaxis left

% 1) Tube: 연속 선 (HandleVisibility='off' -> Legend에서 숨김)
hLine_tub_c = plot(T_chg_tub, c_tub_interp, 'LineStyle','-', 'Marker','none', 'LineWidth', lw, 'Color', color1, 'HandleVisibility','off');
hold on; grid on;

%    Tube: 정수 시간 마커만 보간
c_tub_marker = interp1(T_chg_tub, c_tub_interp, marker_times, 'linear', 'extrap');
hMarker_tub_c = plot(marker_times, c_tub_marker, 'LineStyle','none', 'Marker','o', 'Color', color1, 'HandleVisibility','off');

%    Tube: Legend 표시용 '더미(dummy)' plot
hDummy_tub_c = plot(nan, nan, 'LineStyle','-', 'Marker','o', 'Color', color1, 'DisplayName','c_{cell} Tube');

% 2) Cylinder: 연속 선
hLine_cyl_c = plot(T_chg_cyl, c_cyl_interp, 'LineStyle','-', 'Marker','none', 'LineWidth', lw, 'Color', color2, 'HandleVisibility','off');

%    Cylinder: 정수 시점 마커
c_cyl_marker = interp1(T_chg_cyl, c_cyl_interp, marker_times, 'linear', 'extrap');
hMarker_cyl_c = plot(marker_times, c_cyl_marker, 'LineStyle','none', 'Marker','o', 'Color', color2, 'HandleVisibility','off');

%    Cylinder: Legend 표시용 더미
hDummy_cyl_c = plot(nan, nan, 'LineStyle','-', 'Marker','o', 'Color', color2, 'DisplayName','c_{cell} Cylinder');

ylabel('c_{cell} [$/kWh]', 'FontSize', 10);
ylim([90 110]);
set(gca, 'YColor','k');

% -- 오른쪽 Y축: C_cell [$] --
yyaxis right

% 3) Tube: 연속 선
hLine_tub_C = plot(T_chg_tub, C_tub_interp, 'LineStyle','-', 'Marker','none', 'LineWidth', lw, 'Color', color1, 'HandleVisibility','off');

%    Tube: 정수 시점 마커
C_tub_marker = interp1(T_chg_tub, C_tub_interp, marker_times, 'linear', 'extrap');
hMarker_tub_C = plot(marker_times, C_tub_marker, 'LineStyle','none', 'Marker','x', 'Color', color1, 'HandleVisibility','off');

%    Tube: Legend 더미
hDummy_tub_C = plot(nan, nan, 'LineStyle','-', 'Marker','x', 'Color', color1, 'DisplayName','C_{cell} Tube');

% 4) Cylinder: 연속 선
hLine_cyl_C = plot(T_chg_cyl, C_cyl_interp, 'LineStyle','-', 'Marker','none', 'LineWidth', lw, 'Color', color2, 'HandleVisibility','off');

%    Cylinder: 정수 시점 마커
C_cyl_marker = interp1(T_chg_cyl, C_cyl_interp, marker_times, 'linear', 'extrap');
hMarker_cyl_C = plot(marker_times, C_cyl_marker, 'LineStyle','none', 'Marker','x', 'Color', color2, 'HandleVisibility','off');

%    Cylinder: Legend 더미
hDummy_cyl_C = plot(nan, nan, 'LineStyle','-', 'Marker','x', 'Color', color2, 'DisplayName','C_{cell} Cylinder');

ylabel('C_{cell} [$]', 'FontSize', 10);
ylim([5 30]);
set(gca, 'YColor','k');

% 공통 X축
xlabel('Charging Time [min]', 'FontSize', 10);
xlim([x_min, x_max]);

% ====== Legend: 더미 핸들들만 모아서 "선+마커" 형태 ======
%    순서: [Tube($/kWh), Cylinder($/kWh), Tube($), Cylinder($)]
set(hDummy_tub_c, 'LineWidth', 1.1);
set(hDummy_cyl_c, 'LineWidth', 1.1);
set(hDummy_tub_C, 'LineWidth', 1.1);
set(hDummy_cyl_C, 'LineWidth', 1.1);

legend([hDummy_tub_c, hDummy_cyl_c, hDummy_tub_C, hDummy_cyl_C], 'Location','southeast', 'NumColumns',2, 'FontSize', 8);


exportgraphics(gcf, 'figure4c.png', 'Resolution', 300);
