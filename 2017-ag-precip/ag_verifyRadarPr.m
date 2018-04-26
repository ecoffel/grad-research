radar = importdata('2017-ag-precip/monthly-totals.txt');

pr = loadDailyData('e:/data/cpc-pr/output/precip', 'startYear', 2011, 'endYear', 2017)
pr{3} = nansum(pr{3},5);

[latInds, lonInds] = latLonIndexRange(pr, [32 40], [-105 -83]+360);

monthlycpc = squeeze(nanmean(nanmean(pr{3}(latInds, lonInds, :, :), 2), 1));
monthlycpc = reshape(monthlycpc', [numel(monthlycpc),1]);

figure('Color',[1,1,1]);
hold on;
box on;
axis square;
grid on;
scatter(radar(1:72),monthlycpc,'k')

[f, gof] = fit(radar(1:72),monthlycpc, 'poly1');
p = plot([min(radar(1:72)) max(radar(1:72))], [f(min(radar(1:72))) f(max(radar(1:72)))], '--b', 'LineWidth', 2);
plot([0 200], [0 200], '--', 'LineWidth', 2, 'Color', [.5 .5 .5]);
legend([p], {sprintf('Slope = %.2f', f.p1)}, 'location', 'northwest');

xlim([0 200])
ylim([0 200]);
set(gca, 'FontSize', 36);
xlabel('Radar-based (mm/month)');
ylabel('CPC (mm/month)');
title('2011-2016, 32N-40N, 105W-83W');
