var = 'tasmax';

load(['2015-heat-humidity\recur-dat\recur-exceedence-' var '-rcp45.mat']);
recur45 = testExceedences;
load(['2015-heat-humidity\recur-dat\recur-exceedence-' var '-rcp85.mat']);
recur85 = testExceedences;

figure('Color',[1,1,1]);
hold on; box on; grid on; axis square;
%plot(squeeze(nanmean(nanmean(testExceedences, 4), 2)))

recurTasmax45Mean = squeeze(nanmean(nanmean(nanmean(recur45, 4), 3), 2));
recurTasmax45Std = nanstd(squeeze(nanmean(nanmean(recur45, 4), 2)), [], 2);

recurTasmax85Mean = squeeze(nanmean(nanmean(nanmean(recur85, 4), 3), 2));
recurTasmax85Std = nanstd(squeeze(nanmean(nanmean(recur85, 4), 2)), [], 2);

p1 = shadedErrorBar(-88:2:90, recurTasmax45Mean, recurTasmax45Std, '-', 1);
set(p1.mainLine,  'LineWidth', 2, 'Color', [66/255.0, 170/255.0, 244/255.0]);
set(p1.patch, 'FaceColor', [66/255.0, 170/255.0, 244/255.0]);
set(p1.edge, 'Color', 'w');

p2 = shadedErrorBar(-88:2:90, recurTasmax85Mean, recurTasmax85Std, '-', 1);
set(p2.mainLine,  'LineWidth', 2, 'Color', [221/255.0, 53/255.0, 67/255.0]);
set(p2.patch, 'FaceColor', [221/255.0, 53/255.0, 67/255.0]);
set(p2.edge, 'Color', 'w');

xlabel('Latitude', 'FontSize', 24);
ylabel('Days per year', 'FontSize', 24);
set(gca, 'XTick', [-90 -60 -30 0 30 60 90]);
set(gca, 'FontSize', 24);
ylim([-5 365]);
l = legend([p1.mainLine, p2.mainLine], 'RCP 4.5', 'RCP 8.5');
set(l, 'FontSize', 24);
