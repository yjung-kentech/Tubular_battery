clear; clc; close all;

% COMSOL 초기화
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_1cell_isothermal.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% 기존 데이터 로드
txt_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
txt_filename = 'R(T, I, SOC).txt';
txt_fullfile = fullfile(txt_filepath, txt_filename);
data_table_qh = readtable(txt_fullfile, 'Delimiter', '\t');

% 파라미터 설정
T_vec = [10 20 30 40 50 70 90]; % 온도 값
I_vec = [0.1 0.5 1 2 4 6 8 10 12]; % 전류 값

data_table_Qh.Qh = zeros(height(data_table_Qh), 1);

for i = 1:length(T_vec)
    for j = 1:length(I_vec)
        T = T_vec(i);
        I = I_vec(j);

        % COMSOL 모델에 파라미터 설정
        model.param.set('T0', sprintf('%g[degC]', T));
        model.param.set('C_rate', I);
        
        % COMSOL 스터디 실행
        model.study('std1').run

        % q_h 계산을 위한 표현식 설정
        model.variable('var1').set('q_h', q_h_expr);

        % q_h 값을 추출
        q_h = mphglobal(model, 'nojac(comp1.aveop2(comp1.liion.Qh))/vfactor');
        SOC = mphglobal(model, 'SOC');

        % q_h 및 SOC 값을 double 형식으로 변환
        q_h = double(q_h);
        SOC = double(SOC);

        % 중복된 SOC 값 제거 및 평균 q_h 값 계산
        [SOC_unique, ~, idx_unique] = unique(SOC);
        q_h_unique = accumarray(idx_unique, q_h, [], @mean);

        % SOC_existing 값에 대한 q_h 값 보간
        idx = (data_table_qh.T == T) & (data_table_qh.I == I);
        SOC_existing = data_table_qh.SOC(idx);
        qh_vec = interp1(SOC_unique, q_h_unique, SOC_existing, 'linear', 'extrap');

        % data_table_qh에 q_h 값 추가
        data_table_qh.q_h(idx) = qh_vec;
    end
end

% 결과를 텍스트 파일로 저장
writetable(data_table_qh, 'R, q_h(T, I, SOC).txt', 'Delimiter', '\t');
