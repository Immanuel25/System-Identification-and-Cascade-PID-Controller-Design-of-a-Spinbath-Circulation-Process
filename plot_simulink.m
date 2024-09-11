setpoint = 1;
figure(1)

% Plot all data series on the same plot with specified markers and colors
plot(out.Ysl.Time, out.Ysl.Data, 'm+--', 'DisplayName', '$D_2$', 'MarkerSize', 8, 'LineWidth', 1)
hold on
plot(out.Ycas.Time, out.Ycas.Data, 'y*-', 'DisplayName', '$R$', 'MarkerSize', 8, 'LineWidth', 1)
plot(out.Ysscas.Time, out.Ysscas.Data, 'cx-', 'DisplayName', '$D_1$', 'MarkerSize', 8, 'LineWidth', 1)
hold off

% Add labels, title, and legend
ylabel("Value $\theta$", 'Interpreter', 'latex','FontSize', 12)
xlabel('Time ($s$)', 'Interpreter', 'latex','FontSize', 12)
lgd = legend('Location', 'southeast','FontSize', 15); % Position legend at the right bottom
lgd.Interpreter = 'latex'; % Use LaTeX interpreter for legend
grid on

% Calculate errors
error_A = setpoint - out.Ysl.Data;
error_B = setpoint - out.Ycas.Data;
error_C = setpoint - out.Ysscas.Data;

% Calculate IAE for Single Loop and Cascade
IAE_A = trapz(out.Ysl.Time, abs(error_A));
IAE_B = trapz(out.Ycas.Time, abs(error_B));
IAE_C = trapz(out.Ysscas.Time, abs(error_C));

% Display IAE results
disp('IAE Results - Input D:');
disp(['Single Loop: ', num2str(IAE_A)]);
disp(['Conventional Cascade: ', num2str(IAE_B)]);
disp(['Summed Setpoint Cascade: ', num2str(IAE_C)]);
