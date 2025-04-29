clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% -------------------------------------------------------------
% 1. 기본 설정
% --------------------------------------------------------------
COM_filepath  = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_tube   = 'JYR_cell_0213.mph';
COM_cyl  = 'JYR_cylinder_cell_0213.mph';

R_out_vec = 5:1:40;        % Sweep할 외경 [mm]

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
    'p_am1_vf','p_ca_vf','p_pvdf_vf'};

%% -------------------------------------------------------------
% 3. 튜블러 셀 모델 열기
% --------------------------------------------------------------
disp('Loading Tubular cell model...');
model_tube = mphload(fullfile(COM_filepath, COM_tube));
ModelUtil.showProgress(true);

par_tub = struct();
for k = 1:numel(plist)
    par_tub.(plist{k}) = mphevaluate(model_tube, plist{k});
end

%% -------------------------------------------------------------
% 4. 원통형 셀 모델 열기
% --------------------------------------------------------------
disp('Loading Cylindrical cell model...');
model_cyl = mphload(fullfile(COM_filepath, COM_cyl));
ModelUtil.showProgress(true);

par_cyl = struct();
for k = 1:numel(plist)
    par_cyl.(plist{k}) = mphevaluate(model_cyl, plist{k});
end

%% -------------------------------------------------------------
% 5. R_out 스윕 계산
% --------------------------------------------------------------
disp('Sweeping over R_out range...');

fields = {'anode_active','anode_binder', ...
          'cathode_active','cathode_binder','cathode_carbon', ...
          'separator','electrolyte','total'};

for f = fields
    mass_tub.(f{1}) = zeros(size(R_out_vec));
    mass_cyl.(f{1}) = zeros(size(R_out_vec));
end

for i = 1:length(R_out_vec)
    R_out = R_out_vec(i);

    % Tubular
    res_t = batteryMassModel(R_out,'tubular',par_tub);
    for f = fields
        mass_tub.(f{1})(i) = res_t.massPerCell.(f{1});
    end

    % Cylindrical
    res_c = batteryMassModel(R_out,'cylindrical',par_cyl);
    for f = fields
        mass_cyl.(f{1})(i) = res_c.massPerCell.(f{1});
    end
end

%% -------------------------------------------------------------
% 6. 결과 플롯 예시
% --------------------------------------------------------------
figure('Name','Total cell mass');
plot(R_out_vec,mass_tub.total,'o-','LineWidth',1.8,'MarkerSize',6); hold on;
plot(R_out_vec,mass_cyl.total,'s-','LineWidth',1.8,'MarkerSize',6);
grid on; box on;
xlabel('R_{out} [mm]'); ylabel('Total Cell Mass [g]');
legend('Tubular','Cylindrical','Location','northwest'); set(gca,'FontSize',11);

figure('Name','Tubular cell – mass breakdown');
plot(R_out_vec,mass_tub.anode_active ,'-','LineWidth',1.6); hold on;
plot(R_out_vec,mass_tub.anode_binder ,'-','LineWidth',1.6);
plot(R_out_vec,mass_tub.cathode_active,'-','LineWidth',1.6);
plot(R_out_vec,mass_tub.cathode_binder,'-','LineWidth',1.6);
plot(R_out_vec,mass_tub.cathode_carbon,'-','LineWidth',1.6);
plot(R_out_vec,mass_tub.separator    ,'-','LineWidth',1.6);
plot(R_out_vec,mass_tub.electrolyte  ,'-','LineWidth',1.6);
grid on; box on;
xlabel('R_{out} [mm]'); ylabel('Mass per Cell [g]');
legend({'An-active','An-binder','Ca-active','Ca-binder','Ca-carbon', ...
        'Separator','Electrolyte'},'Location','northwest');
set(gca,'FontSize',11);

figure('Name','Cylindrical cell – mass breakdown');
plot(R_out_vec,mass_cyl.anode_active ,'-','LineWidth',1.6); hold on;
plot(R_out_vec,mass_cyl.anode_binder ,'-','LineWidth',1.6);
plot(R_out_vec,mass_cyl.cathode_active,'-','LineWidth',1.6);
plot(R_out_vec,mass_cyl.cathode_binder,'-','LineWidth',1.6);
plot(R_out_vec,mass_cyl.cathode_carbon,'-','LineWidth',1.6);
plot(R_out_vec,mass_cyl.separator    ,'-','LineWidth',1.6);
plot(R_out_vec,mass_cyl.electrolyte  ,'-','LineWidth',1.6);
grid on; box on;
xlabel('R_{out} [mm]'); ylabel('Mass per Cell [g]');
legend({'An-active','An-binder','Ca-active','Ca-binder','Ca-carbon', ...
        'Separator','Electrolyte'},'Location','northwest');
set(gca,'FontSize',11);

%% -------------------------------------------------------------
% 7. 결과 저장
% --------------------------------------------------------------
% 저장 경로와 파일명 설정 (원한다면 다른 폴더/이름으로 변경)
savename = sprintf('mass_results.mat');
savepath = fullfile('C:\Users\user\Desktop\Figure\Cost Model\mat 파일', savename);

% .mat 파일로 저장
save(savepath, 'R_out_vec', 'mass_tub', 'mass_cyl');

fprintf('✓ 결과가 %s 에 저장되었습니다.\n', savepath);

%% =============================================================
%      batteryMassModel  (local function)
% =============================================================
function result = batteryMassModel(R_out_mm,cellType,par)
% --------------------------------------------------------------
% 세부 구성별 질량(g) 계산 (separator electrolyte 분리 반영)
% --------------------------------------------------------------

% ---------- 고정 상수 ----------
delta_cu = 10e-6;       % Cu thickness [m]
delta_al = 16e-6;       % Al thickness [m]
h_jr_mm  = 2.0;         % 상하 electrolyte 공간 [mm]

delta_tl = par.n_delta + par.s_delta + par.p_delta + 0.5*delta_cu + 0.5*delta_al;

% 외경-내경 설정
R_out_m = R_out_mm * 1e-3;
switch lower(cellType)
    case 'tubular'
        Rin_m = 3e-3;
    case 'cylindrical'
        if      R_out_mm <= 9,  Rin_m = 1e-3;
        elseif  R_out_mm <= 23, Rin_m = (1 + (R_out_mm-9)/14)*1e-3;
        else                    Rin_m = 2e-3;
        end
    otherwise
        error('cellType must be ''tubular'' or ''cylindrical''');
end

% Jellyroll geometry
L_jr = pi*(R_out_m^2 - Rin_m^2) / delta_tl;                 
H_jr = (15/14*R_out_mm + 55.5 - 2*h_jr_mm)*1e-3;            
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
mpa_sep_ely = par.s_epsilon * par.s_delta * par.e_rho * 1000;
mpa_ely_an  = par.n_epsilon * par.n_delta * par.e_rho * 1000;
mpa_ely_ca  = par.p_epsilon * par.p_delta * par.e_rho * 1000;
mpa_ely_total = mpa_sep_ely + mpa_ely_an + mpa_ely_ca;

% ---------- 셀 질량 (g) ----------
m_an_active  = mpa_an_active  * A_jr;
m_an_binder  = mpa_an_binder  * A_jr;
m_ca_active  = mpa_ca_active  * A_jr;
m_ca_binder  = mpa_ca_binder  * A_jr;
m_ca_carbon  = mpa_ca_carbon  * A_jr;
m_sep        = mpa_sep_solid  * A_jr;
m_ely        = mpa_ely_total  * A_jr;

m_total = m_an_active + m_an_binder + ...
          m_ca_active + m_ca_binder + m_ca_carbon + ...
          m_sep + m_ely;

% ---------- 결과 ----------
result = struct();
result.R_out_mm = R_out_mm;
result.A_jr     = A_jr;

result.massPerCell = struct( ...
    'anode_active',  m_an_active, ...
    'anode_binder',  m_an_binder, ...
    'cathode_active',m_ca_active, ...
    'cathode_binder',m_ca_binder, ...
    'cathode_carbon',m_ca_carbon, ...
    'separator',     m_sep, ...
    'electrolyte',   m_ely, ...
    'total',         m_total);
end
