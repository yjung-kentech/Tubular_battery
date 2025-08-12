clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% -------------------------------------------------------------
% 1. 기본 설정
% --------------------------------------------------------------
COM_filepath  = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_tube   = 'JYR_cell_0522.mph';

R_out_vec = 5:1:40;
R_in_vec  = 1:0.5:10;

% 재료비 단가 정의
cost_unit.p_active   = 26.00; % [$/kg]
cost_unit.p_carbon   = 7.00;  % [$/kg]
cost_unit.p_binder   = 15.00; % [$/kg]
cost_unit.n_active   = 10.00; % [$/kg]
cost_unit.n_binder   = 10.00; % [$/kg]
cost_unit.al_foil    = 0.20;  % [$/m^2]
cost_unit.cu_foil    = 1.20;  % [$/m^2]
cost_unit.separator  = 0.90;  % [$/m^2]
cost_unit.electrolyte= 10.00; % [$/L]

%% -------------------------------------------------------------
% 2. 필요한 파라미터 목록
% --------------------------------------------------------------
plist = { ...
    'n_epsilon','p_epsilon','s_epsilon', 'n_delta','p_delta','s_delta', ...
    'n_rho','p_rho','s_rho','e_rho', 'n_am1_rho','n_binder_rho', ...
    'p_am1_rho','p_ca_rho','p_pvdf_rho', 'n_am1_vf','n_binder_vf', ...
    'p_am1_vf','p_ca_vf','p_pvdf_vf', 'delta_cu', 'rho_cu', ...
    'delta_al', 'rho_al', 'h_jr'};

%% -------------------------------------------------------------
% 3. 튜블러 셀 모델 열기
% --------------------------------------------------------------
disp('Loading Tubular cell model...');
model_tube = mphload(fullfile(COM_filepath, COM_tube));
par = struct();
for k = 1:numel(plist)
    par.(plist{k}) = mphevaluate(model_tube, plist{k});
end

%% -------------------------------------------------------------
% 4. 2D 스윕 계산
% --------------------------------------------------------------
disp('Sweeping over R_out and R_in range...');
num_R_out = length(R_out_vec); num_R_in  = length(R_in_vec);

prop_mass_kg = struct(); prop_area_m2 = struct(); cost = struct();
prop_volume_L.electrolyte_tubular = nan(num_R_out, num_R_in);
prop_volume_L.electrolyte_cylindrical = nan(num_R_out, num_R_in);

for i = 1:num_R_out
    R_out = R_out_vec(i);
    for j = 1:num_R_in
        R_in = R_in_vec(j);
        if R_in >= R_out, continue; end
        
        prop_tub = batteryPropertiesModel(R_out, R_in, par, 'tubular');
        prop_cyl = batteryPropertiesModel(R_out, R_in, par, 'cylindrical');
        
        prop_mass_kg.anode_active(i,j)   = prop_tub.mass_kg.anode_active;
        prop_mass_kg.anode_binder(i,j)   = prop_tub.mass_kg.anode_binder;
        prop_mass_kg.cathode_active(i,j) = prop_tub.mass_kg.cathode_active;
        prop_mass_kg.cathode_binder(i,j) = prop_tub.mass_kg.cathode_binder;
        prop_mass_kg.cathode_carbon(i,j) = prop_tub.mass_kg.cathode_carbon;
        prop_area_m2.components(i,j)     = prop_tub.area_m2;
        prop_volume_L.electrolyte_tubular(i,j) = prop_tub.volume_L.electrolyte;
        prop_volume_L.electrolyte_cylindrical(i,j) = prop_cyl.volume_L.electrolyte;

        cost.anode_active(i,j)   = prop_tub.mass_kg.anode_active * cost_unit.n_active;
        cost.anode_binder(i,j)   = prop_tub.mass_kg.anode_binder * cost_unit.n_binder;
        cost.cathode_active(i,j) = prop_tub.mass_kg.cathode_active * cost_unit.p_active;
        cost.cathode_binder(i,j) = prop_tub.mass_kg.cathode_binder * cost_unit.p_binder;
        cost.cathode_carbon(i,j) = prop_tub.mass_kg.cathode_carbon * cost_unit.p_carbon;
        cost.separator(i,j)      = prop_tub.area_m2 * cost_unit.separator;
        cost.cu_foil(i,j)        = prop_tub.area_m2 * cost_unit.cu_foil;
        cost.al_foil(i,j)        = prop_tub.area_m2 * cost_unit.al_foil;
        cost.electrolyte_tubular(i,j) = prop_tub.volume_L.electrolyte * cost_unit.electrolyte;
        cost.electrolyte_cylindrical(i,j) = prop_cyl.volume_L.electrolyte * cost_unit.electrolyte;
        
        common_sum = cost.anode_active(i,j) + cost.anode_binder(i,j) + cost.cathode_active(i,j) + cost.cathode_binder(i,j) + cost.cathode_carbon(i,j) + cost.separator(i,j) + cost.cu_foil(i,j) + cost.al_foil(i,j);
                     
        cost.total_cost_tubular(i,j) = common_sum + cost.electrolyte_tubular(i,j);
        cost.total_cost_cylindrical(i,j) = common_sum + cost.electrolyte_cylindrical(i,j);
    end
end
disp('Sweeping complete');

%% -------------------------------------------------------------
% 5. 결과 저장
% --------------------------------------------------------------
savename = sprintf('Cost.mat');
savepath = fullfile('C:\Users\user\Desktop\Figure\Cost Model\mat 파일', savename);
save(savepath, 'R_out_vec', 'R_in_vec', 'prop_mass_kg', 'prop_area_m2', 'prop_volume_L', 'cost', 'cost_unit');
fprintf('모든 분석 결과가 %s 에 저장되었습니다.\n', savepath);

%% -------------------------------------------------------------
% 6. 등고선 플롯
% --------------------------------------------------------------
% 6.1 물리량(질량/면적/부피) 플롯
figure('Name', 'Physical Properties Breakdown', 'Position', [50, 50, 1200, 900]);
sgtitle('부품별 물리량 분포', 'FontSize', 16, 'FontWeight', 'bold');
fields_physical = {'anode_active','anode_binder','cathode_active','cathode_binder', 'cathode_carbon','separator', 'cu_foil','al_foil', 'electrolyte_tubular', 'electrolyte_cylindrical'};
for k = 1:numel(fields_physical)
    field_name = fields_physical{k}; subplot(3, 4, k);
    switch field_name
        case {'separator', 'cu_foil', 'al_foil'}
            data_to_plot = prop_area_m2.components; unit_label = 'Area [m^2]';
        case {'electrolyte_tubular', 'electrolyte_cylindrical'}
            data_to_plot = prop_volume_L.(field_name); unit_label = 'Volume [L]';
        otherwise
            data_to_plot = prop_mass_kg.(field_name) * 1000; unit_label = 'Mass [g]';
    end
    contourf(R_in_vec, R_out_vec, data_to_plot, 20, 'LineStyle', 'none');
    x_patch = [max(R_in_vec), min(R_out_vec), max(R_in_vec)];
    y_patch = [min(R_out_vec), min(R_out_vec), max(R_in_vec)];
    patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
    set(gca, 'YDir', 'normal'); title(strrep(field_name, '_', ' '));
    xlabel('R_{in} [mm]'); ylabel('R_{out} [mm]'); h = colorbar; ylabel(h, unit_label);
end

% 6.2 비용(Cost) 플롯
figure('Name', 'Cost Breakdown', 'Position', [100, 100, 1200, 900]);
sgtitle('부품별 비용($) 분포', 'FontSize', 16, 'FontWeight', 'bold');
fields_cost_plot = fieldnames(cost);
for k = 1:numel(fields_cost_plot)
    field_name = fields_cost_plot{k}; subplot(3, 4, k);
    data_to_plot = cost.(field_name);
    contourf(R_in_vec, R_out_vec, data_to_plot, 20, 'LineStyle', 'none');
    x_patch = [max(R_in_vec), min(R_out_vec), max(R_in_vec)];
    y_patch = [min(R_out_vec), min(R_out_vec), max(R_in_vec)];
    patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
    set(gca, 'YDir', 'normal'); title(strrep(field_name, '_', ' '));
    xlabel('R_{in} [mm]'); ylabel('R_{out} [mm]'); h = colorbar; ylabel(h, 'Cost [$]');
end

%% =============================================================
%      batteryPropertiesModel  (local function)
% =============================================================
function prop = batteryPropertiesModel(R_out_mm, R_in_mm, par, cellType)
    R_out_m=R_out_mm*1e-3; R_in_m=R_in_mm*1e-3;
    delta_tl=par.n_delta+par.s_delta+par.p_delta+0.5*par.delta_cu+0.5*par.delta_al;
    L_jr=pi*(R_out_m^2-R_in_m^2)/delta_tl;
    H_jr=(15/14*R_out_mm+55.5-2*par.h_jr)*1e-3;
    A_jr=L_jr*H_jr;
    prop.area_m2 = A_jr;
    prop.mass_kg.anode_active = (1-par.n_epsilon)*par.n_delta*par.n_am1_rho*par.n_am1_vf * A_jr;
    prop.mass_kg.anode_binder = (1-par.n_epsilon)*par.n_delta*par.n_binder_rho*par.n_binder_vf * A_jr;
    prop.mass_kg.cathode_active = (1-par.p_epsilon)*par.p_delta*par.p_am1_rho*par.p_am1_vf * A_jr;
    prop.mass_kg.cathode_carbon = (1-par.p_epsilon)*par.p_delta*par.p_ca_rho*par.p_ca_vf * A_jr;
    prop.mass_kg.cathode_binder = (1-par.p_epsilon)*par.p_delta*par.p_pvdf_rho*par.p_pvdf_vf * A_jr;
    vol_core_m3 = (par.s_epsilon*par.s_delta + par.n_epsilon*par.n_delta + par.p_epsilon*par.p_delta) * A_jr;
    total_vol_m3 = 0;
    switch lower(cellType)
        case 'tubular'
            vol_cap_m3  = pi * (R_out_m^2 - R_in_m^2) * (2 * par.h_jr * 1e-3);
            total_vol_m3 = vol_core_m3 + vol_cap_m3;
        case 'cylindrical'
            vol_cap_m3 = pi * (R_out_m^2) * (2 * par.h_jr * 1e-3);
            vol_center_m3 = pi * (R_in_m^2) * H_jr;
            total_vol_m3 = vol_core_m3 + vol_cap_m3 + vol_center_m3;
    end
    prop.volume_L.electrolyte = total_vol_m3 * 1000;
end