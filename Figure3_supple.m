clear; clc; close all;

% COMSOL 모델 경로 설정
COM_filepath = 'C:/Users/user/Desktop/Tubular battery 최종';
COM_filename1 = 'JYR_cell_0912.mph';
COM_filename2 = 'JYR_cylinder_cell_1008.mph';
COM_fullfile1 = fullfile(COM_filepath, COM_filename1);
COM_fullfile2 = fullfile(COM_filepath, COM_filename2);

% PNG 파일 경로 설정
png_dir = 'C:/Users/user/Desktop/MATLAB/Tubular_battery';

% 파라미터 설정
C_rate = [2 6 10];
R_out = [10.5 23 35];
R_in = 2;

% 루프
for i = 1:length(C_rate)
    for j = 1:length(R_out)
        R_out_str = [num2str(R_out(j)) '[mm]'];
        R_in_str = [num2str(R_in) '[mm]'];

        % 모델1 로드

        model1 = mphload(COM_fullfile1);

        model1.param.set('C_rate', C_rate(i));
        model1.param.set('R_out', R_out_str);
        model1.param.set('R_in', R_in_str);
        model1.study('std1').run;

        % 모델 1 변수 가져오기
        time_s1 = mphglobal(model1, 't', 'unit', 's');
        time_min1 = mphglobal(model1, 't', 'unit', 'min');
        T_max1 = mphglobal(model1, 'T_max', 'unit', 'degC');
        T_avg1 = mphglobal(model1, 'T_avg', 'unit', 'degC');
        I_cell1 = mphglobal(model1, 'comp1.I_cell', 'unit', 'A');
        E_cell1 = mphglobal(model1, 'comp1.E_cell', 'unit', 'V');
        SOC1 = mphglobal(model1, 'comp1.SOC');
        E_lp1 = mphglobal(model1, 'comp1.E_lp', 'unit', 'V');

        [max_val1, idx] = max(T_max1);
        max_time1 = time_s1(idx);

        % 모델2 로드

        model2 = mphload(COM_fullfile2);

        model2.param.set('C_rate', C_rate(i));
        model2.param.set('R_out', R_out_str);
        model2.study('std1').run;


        % 모델 2 변수 가져오기
        time_s2 = mphglobal(model2, 't', 'unit', 's');
        time_min2 = mphglobal(model2, 't', 'unit', 'min');
        T_max2 = mphglobal(model2, 'T_max', 'unit', 'degC');
        T_avg2 = mphglobal(model2, 'T_avg', 'unit', 'degC');
        I_cell2 = mphglobal(model2, 'comp1.I_cell', 'unit', 'A');
        E_cell2 = mphglobal(model2, 'comp1.E_cell', 'unit', 'V');
        SOC2 = mphglobal(model2, 'comp1.SOC');
        E_lp2 = mphglobal(model2, 'comp1.E_lp', 'unit', 'V');

        [max_val2, idx] = max(T_max2);
        max_time2 = time_s2(idx);

        % 일관된 비율의 그림 생성
        figure('Position', [100, 100, 500, 1200]); % 전체 그림 크기 조정

        % 타일 레이아웃 생성 (5x1)
        
        % Temperature Contour
        ax1 = subplot(4, 1, 1); 

        contour_file1 = fullfile(png_dir, ['figure_Crate_', num2str(C_rate(i)), '_Rout_', num2str(R_out(j)), '_cyl', '.png']);
        contour_img1 = imread(contour_file1);

        contour_file2 = fullfile(png_dir, ['figure_Crate_', num2str(C_rate(i)), '_Rout_', num2str(R_out(j)), '.png']);
        contour_img2 = imread(contour_file2);

        combined_img = [contour_img1, contour_img2];
        imshow(combined_img, 'Parent', ax1);
        axis(ax1, 'equal');
        
        % 간격 조정 (Position 인자 사용)
        ax1.Position = [0.13 0.71 0.775 0.25]; % [left, bottom, width, height]

        % Temperature plot
        ax2 = subplot(4, 1, 2);
        color1 = [0.8500, 0.3250, 0.0980]; % Orange
        color2 = [0, 0.4470, 0.7410]; % Blue
        plot(time_min1, T_max1, 'Color', color1, 'DisplayName', 'T_{max}(Tube)');
        hold on;
        plot(time_min1, T_avg1, 'Color', color2, 'DisplayName', 'T_{avg}(Tube)');
        plot(time_min2, T_max2, 'Color', color1, 'LineStyle', '--', 'DisplayName', 'T_{max}(Cylinder)');
        plot(time_min2, T_avg2, 'Color', color2, 'LineStyle', '--', 'DisplayName', 'T_{avg}(Cylinder)');
        hold off;
        title('Temperature Plot', 'FontWeight', 'bold', 'FontSize', 11);
        xlabel('Time [min]', 'FontSize', 10);
        ylabel('Temperature [^oC]', 'FontSize', 10);
        legend('Location', 'northeast', 'FontSize', 6);
        grid on;
        xlim([0, min([max(time_min1), max(time_min2)])]);

        % 간격 조정 (Position 인자 사용)
        ax2.Position = [0.13 0.54 0.775 0.18];

        % I, V Curve
        ax3 = subplot(4, 1, 3);
        yyaxis right;
        plot(time_min1, I_cell1, 'DisplayName', 'Cell Current(Tube)');
        hold on;
        plot(time_min2, I_cell2, 'LineStyle', '--', 'DisplayName', 'Cell Current(Cylinder)');
        ylabel('Cell Current [A]', 'FontSize', 10);
        set(gca, 'YColor', color1);

        yyaxis left;
        plot(time_min1, E_cell1, 'DisplayName', 'Cell Voltage(Tube)');
        plot(time_min2, E_cell2, 'LineStyle', '--', 'DisplayName', 'Cell Voltage(Cylinder)');
        hold off;
        ylim([min([min(E_cell1), min(E_cell2)]), 4.25]);
        ylabel('Cell Voltage [V]', 'FontSize', 10);
        set(gca, 'YColor', color2);

        xlabel('Time [min]', 'FontSize', 10);
        legend('Location', 'northwest', 'FontSize', 6);
        title('I, V Curve', 'FontWeight', 'bold', 'FontSize', 11);
        grid on;
        xlim([0, min([max(time_min1), max(time_min2)])]);

        % SOC, E_lp Curve
        ax4 = subplot(4, 1, 4);
        yyaxis left;
        plot(time_min1, E_lp1, 'DisplayName', 'E_{lp}(Tube)');
        hold on;
        plot(time_min2, E_lp2, 'LineStyle', '--','DisplayName', 'E_{lp}(Cylinder)');
        ylabel('Lithium Plating Potential [V]', 'FontSize', 10);
        set(gca, 'YColor', color2);

        yyaxis right;
        plot(time_min1, SOC1, 'DisplayName', 'SOC(Tube)');
        plot(time_min2, SOC2, 'LineStyle', '--', 'DisplayName', 'SOC(Cylinder)');
        hold off;
        ylabel('SOC', 'FontSize', 10);
        set(gca, 'YColor', color1);

        xlabel('Time [min]', 'FontSize', 10);
        legend('Location', 'northeast', 'FontSize', 6);
        title('SOC, E_{lp} Curve', 'FontWeight', 'bold', 'FontSize', 11);
        grid on;
        xlim([0, min([max(time_min1), max(time_min2)])]);

        % Save the figure
        filename = ['figure_combined_Crate_', num2str(C_rate(i)), '_Rout_', num2str(R_out(j)), '.png'];
        exportgraphics(gcf, filename, 'Resolution', 300);
        close(gcf);
    end
end
