clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular cell';
COM_filename = 'JYR_cell_0527.mph';
% COM_filename = 'JYR_cell_cylinder_0528';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

for C_rate = 6
    for R_out = 23
        for R_in = 2

            R_out_str = [num2str(R_out) '[mm]'];
            R_in_str = [num2str(R_in) '[mm]'];

            model.param.set('C_rate', C_rate);
            model.param.set('R_out', R_out_str);
            model.param.set('R_in', R_in_str);

            model.study('std1').run

            % Time
            time = mphglobal(model, 't', 'unit', 'min');

            % Temperature
            T_max = mphglobal(model, 'T_max', 'unit', 'degC');
            T_avg = mphglobal(model, 'T_avg', 'unit', 'degC');

            % Lithium plating potential
            Elp_avg = mphglobal(model, 'comp1.E_lp');
            Elp_min = mphglobal(model, 'comp3.E_lp');

            % Flux
            f_topbottom = mphglobal(model, 'comp2.f_topbottom2');
            f_side = mphglobal(model, 'comp2.f_side2');

            % Current
            comp1.i_cell = mphglobal(model, 'comp1.i_cell');
            comp3.i_cell = mphglobal(model, 'comp3.i_cell');

            % Heat generation
            q_tot = mphglobal(model, 'comp2.q_tot');
            q_h = mphglobal(model, 'comp2.q_h');
            q_cond = mphglobal(model, 'comp2.q_cond');

            % Power loss
            Qh_n_rxn = mphglobal(model, 'Qh_n_rxn');
            Qh_n_trn_l = mphglobal(model, 'Qh_n_trn_l');
            Qh_n_trn_s = mphglobal(model, 'Qh_n_trn_s');

            % Temperature plot
            subplot(2, 3, 1)
            plot(time, T_max, 'LineWidth', 2, 'DisplayName', 'T_max')
            hold on
            plot(time, T_avg, 'LineWidth', 2, 'DisplayName', 'T_avg')
            hold off
            title('Temperature') 
            xlabel('Time (min)');
            ylabel('Temperature (degC)');
            legend('show')
            grid on;

            % E_lp plot
            subplot(2, 3, 2)
            plot(time, Elp_avg, 'LineWidth', 2, 'DisplayName', 'Elp_avg')
            hold on
            plot(time, Elp_min, 'LineWidth', 2, 'DisplayName', 'Elp_min')
            hold off
            title('E_lp')
            xlabel('Time (min)')
            ylabel('Voltage (V)')
            legend('show')
            grid on

            % Heat flux
            subplot(2, 3, 3)
            plot(time, f_topbottom, 'LineWidth', 2, 'DisplayName', 'f_topbottom')
            hold on
            plot(time, f_side, 'LineWidth', 2, 'DisplayName', 'f_side')
            hold off
            title('Heat flux')
            xlabel('Time (min)')
            ylabel('Flux (W)')
            legend('show')
            grid on

            % Current
            subplot(2, 3, 4)
            plot(time, comp1.i_cell, 'LineWidth', 2, 'DisplayName', 'comp1.i_cell')
            hold on
            plot(time, comp3.i_cell, 'LineWidth', 2, 'DisplayName', 'comp3.i_cell')
            hold off
            title('Current')
            xlabel('Time (min)')
            ylabel('Current (A/m^2)')
            legend('show')
            grid on

            % Heat generation plot
            subplot(2, 3, 5)
            plot(time, q_tot, 'LineWidth', 2, 'DisplayName', 'q_tot')
            hold on
            plot(time, q_h, 'LineWidth', 2, 'DisplayName', 'q_h')
            hold on
            plot(time, q_cond, 'LineWidth', 2, 'DisplayName', 'q_cond')
            hold off

            title('Heat generation')
            xlabel('Time (min)')
            ylabel('Heat generation (W/m^3)')
            legend('show')
            grid on

            % Power loss plot
            subplot(2, 3, 6)
            plot(time, Qh_n_rxn, 'LineWidth', 2, 'DisplayName', 'Qh_n_rxn')
            hold on
            plot(time, Qh_n_trn_l, 'LineWidth', 2, 'DisplayName', 'Qh_n_trn_l')
            hold on
            plot(time, Qh_n_trn_s, 'LineWidth', 2, 'DisplayName', 'Qh_n_trn_s')
            hold off

            title('Power loss')
            xlabel('Time (min)')
            ylabel('Powe loss (N/m)')
            legend('show')
            grid on

        end
    end
end