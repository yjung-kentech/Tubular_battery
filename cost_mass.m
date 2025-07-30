clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% -------------------------------------------------------------
% 1. 기본 설정
% --------------------------------------------------------------
COM_filepath  = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_tube   = 'JYR_cell_0522.mph';

R_out_vec = 5:1:40;        % Sweep할 외경 [mm]
R_in_vec = 1:0.5:10;       % Sweep할 내경 [mm]

%% -------------------------------------------------------------
% 2. 필요한 파라미터 목록
% --------------------------------------------------------------
plist = { ...
    'n_epsilon','p_epsilon','s_epsilon', ...
    'n_delta','p_delta','s_delta', ...
    'n_rho','p_rho','s_rho','e_rho', ...
    'n_am1_rho','n_binder_rho', ...
    'p_am1_rho','p_ca_rho','p_pvdf_rho', ...
    'n_am1_vf','n_binder_vf', ...
    'p_am1_vf','p_ca_vf','p_pvdf_vf', ...
    'delta_cu', 'rho_cu', 'delta_al', 'rho_al', 'h_jr'};

%% -------------------------------------------------------------
% 3. 튜블러 셀 모델 열기
% --------------------------------------------------------------
disp('Loading Tubular cell model...');
model_tube = mphload(fullfile(COM_filepath, COM_tube));
ModelUtil.showProgress(true);

par = struct();
for k = 1:numel(plist)
    par.(plist{k}) = mphevaluate(model_tube, plist{k});
end


%% -------------------------------------------------------------
% 5.2D 스윕 계산
% --------------------------------------------------------------
disp('Sweeping over R_out and R_in range...');
num_R_out = length(R_out_vec);
num_R_in = length(R_in_vec);

fields = {'anode_active','anode_binder','cathode_active','cathode_binder', ...
          'cathode_carbon','separator','electrolyte', ...
          'cu_foil','al_foil','total'};

for f = fields
    mass.(f{1}) = nan(num_R_out, num_R_in);
end

for i = 1:num_R_out
    R_out = R_out_vec(i);
    for j = 1:num_R_in
        R_in = R_in_vec(j);
        if R_in >= R_out, continue; end

        result = batteryMassModel(R_out, R_in, par);
        for f = fields
            mass.(f{1})(i, j) = result.massPerCell.(f{1});
        end
    end
end

disp('Sweeping complete');


%% -------------------------------------------------------------
% 6. 결과 저장
% --------------------------------------------------------------
savename = sprintf('mass_results_.mat');
savepath = fullfile('C:\Users\user\Desktop\Figure\Cost Model\mat 파일', savename);
save(savepath, 'R_out_vec', 'R_in_vec', 'mass');

%% -------------------------------------------------------------
% 6. 등고선 플롯
% --------------------------------------------------------------
figure('Name', 'Mass Breakdown Contours', 'Position', [50, 50, 1200, 900]);
fields_to_plot = fieldnames(mass);
num_fields = numel(fields_to_plot);
rows = ceil(sqrt(num_fields));
cols = ceil(num_fields / rows);

for k = 1:num_fields
    subplot(rows, cols, k);
    contourf(R_in_vec, R_out_vec, mass.(fields_to_plot{k}), 20, 'LineStyle', 'none');
    set(gca, 'YDir', 'normal', 'FontSize', 10);
    title(strrep(fields_to_plot{k}, '_', ' '), 'FontWeight', 'bold');
    xlabel('R_{in} [mm]'); ylabel('R_{out} [mm]');
    h = colorbar;
    ylabel(h, 'Mass [g]');
end


%% =============================================================
%      batteryMassModel  (local function)
% =============================================================
function result = batteryMassModel(R_out_mm, R_in_mm, par)
% --------------------------------------------------------------
% 세부 구성별 질량(g) 계산
% --------------------------------------------------------------
% 기본 단위 환산
R_out_m = R_out_mm * 1e-3;
R_in_m  = R_in_mm  * 1e-3;
h_cap_mm = 4.0;  % 상하단 electrolyte 공간 (2mm + 2mm)

% Tri-layer 두께 계산
delta_tl = par.n_delta + par.s_delta + par.p_delta + 0.5*par.delta_cu + 0.5*par.delta_al;

% Jellyroll geometry
L_jr = pi*(R_out_m^2 - R_in_m^2) / delta_tl;
H_jr = (15/14*R_out_mm + 55.5 - 2*par.h_jr)*1e-3;
A_jr = L_jr * H_jr;
                                       
% ---------- 단위면적 질량 (g/m²) ----------
% Anode solids
mpa_an_active = (1-par.n_epsilon)*par.n_delta * par.n_am1_rho   * par.n_am1_vf * 1000;
mpa_an_binder = (1-par.n_epsilon)*par.n_delta * par.n_binder_rho* par.n_binder_vf*1000;

% Cathode solids
mpa_ca_active = (1-par.p_epsilon)*par.p_delta * par.p_am1_rho   * par.p_am1_vf * 1000;
mpa_ca_carbon = (1-par.p_epsilon)*par.p_delta * par.p_ca_rho    * par.p_ca_vf  * 1000;
mpa_ca_binder = (1-par.p_epsilon)*par.p_delta * par.p_pvdf_rho  * par.p_pvdf_vf*1000;

% Separator (solid only) and electrolyte
mpa_sep_solid = (1-par.s_epsilon) * par.s_delta * (par.s_rho - par.e_rho * par.s_epsilon)/(1-par.s_epsilon) * 1000;

% Electrolyte (separator + anode + cathode)
mpa_ely_sep = par.s_epsilon * par.s_delta * par.e_rho * 1000;
mpa_ely_an  = par.n_epsilon * par.n_delta * par.e_rho * 1000;
mpa_ely_ca  = par.p_epsilon * par.p_delta * par.e_rho * 1000;
mpa_ely_core = mpa_ely_sep + mpa_ely_an + mpa_ely_ca;

% Current Collector
mpa_cu_foil = 0.5 * par.delta_cu * par.rho_cu * 1000;
mpa_al_foil = 0.5 * par.delta_al * par.rho_al * 1000;

% 상하단 electrolyte 질량
V_cap = pi * (R_out_m^2 - R_in_m^2) * (h_cap_mm * 1e-3);  % [m³]
m_ely_cap = V_cap * par.e_rho * 1000;  % [g]

% 실제 셀 질량 (g)
m_an_active  = mpa_an_active  * A_jr;
m_an_binder  = mpa_an_binder  * A_jr;
m_ca_active  = mpa_ca_active  * A_jr;
m_ca_binder  = mpa_ca_binder  * A_jr;
m_ca_carbon  = mpa_ca_carbon  * A_jr;
m_sep        = mpa_sep_solid  * A_jr;
m_ely        = mpa_ely_core  * A_jr + m_ely_cap;
m_cu         = mpa_cu_foil    * A_jr;
m_al         = mpa_al_foil    * A_jr;


m_total = m_an_active + m_an_binder + ...
          m_ca_active + m_ca_binder + m_ca_carbon + ...
          m_sep + m_ely + m_cu + m_al;

% 결과 구조체
result = struct();
result.R_out_mm = R_out_mm;
result.R_in_mm  = R_in_mm;
result.A_jr     = A_jr;
result.massPerCell = struct( ...
    'anode_active',   m_an_active, ...
    'anode_binder',   m_an_binder, ...
    'cathode_active', m_ca_active, ...
    'cathode_binder', m_ca_binder, ...
    'cathode_carbon', m_ca_carbon, ...
    'separator',      m_sep, ...
    'electrolyte',    m_ely, ...
    'cu_foil',        m_cu, ...
    'al_foil',        m_al, ...
    'total',          m_total);
end