pressures = [1000, 950, 900, 850, 800, 700, 500].*100;

wbcurve = [];
for p = pressures
    wbcurve(end+1)=kopp_wetBulb(35,p,50,1);
end

figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;

plot(pressures, wbcurve, 'k-', 'LineWidth', 2)
plot(pressures, wbcurve, 'o', 'markerfacecolor', [.5, .5, .5], 'markeredgecolor', [0, 0, 0], 'markersize', 15, 'linewidth', 2)

set(gca, 'xtick', flip(pressures), 'xticklabels', flip(pressures)./100);
set(gca, 'ytick', 26:.1:26.5);
set(gca, 'xdir', 'reverse');

xlabel('Pressure level (mb)');
ylabel(['T_W (' char(176) 'C)']);

set(gca, 'fontsize', 40);
xtickangle(45)
title(['T_W at 35 ' char(176) 'C and 50% RH']);

xlim([450, 1050].*100);
ylim([26 26.5]);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['altitude-wb-adjustment.eps']);
close all;
