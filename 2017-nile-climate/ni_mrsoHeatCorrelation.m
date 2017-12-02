
load 2017-nile-climate/nile-heat-waves-95-5day-era-south.mat;
load 2017-nile-climate/nile-heat-waves-95-5day-era-north.mat;

load 2017-nile-climate/mrso-era-interim-north.mat;
load 2017-nile-climate/mrso-era-interim-south.mat;

heatProbSouthEra = heatProbSouth;
heatProbNorthEra = heatProbNorth;
mrsoNorthEra = prNorth;
mrsoSouthEra = prSouth;

load 2017-nile-climate/nile-heat-waves-95-5day-ncep-south.mat;
load 2017-nile-climate/nile-heat-waves-95-5day-ncep-north.mat;

load 2017-nile-climate/mrso-ncep-reanalysis-north.mat;
load 2017-nile-climate/mrso-ncep-reanalysis-south.mat;

heatProbSouthNcep = heatProbSouth;
heatProbNorthNcep = heatProbNorth;
mrsoNorthNcep = prNorth;
mrsoSouthNcep = prSouth;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

heatSouthCorrNcep = [];
heatNorthCorrNcep = [];
for s = 1:size(seasons, 1)
    heatSouth = squeeze(nansum(nansum(nansum(heatProbSouthNcep(:, :, :, seasons(s,:)), 4), 2), 1));
    heatSouthCorrNcep(s) = corr(heatSouth, mrsoSouthNcep{s});
    
    heatNorth = squeeze(nansum(nansum(nansum(heatProbNorthNcep(:, :, :, seasons(s,:)), 4), 2), 1));
    heatNorthCorrNcep(s) = corr(heatNorth, mrsoNorthNcep{s});
    
    heatSouth = squeeze(nansum(nansum(nansum(heatProbSouthEra(:, :, :, seasons(s,:)), 4), 2), 1));
    heatSouthCorrEra(s) = corr(heatSouth, mrsoSouthEra{s});
    
    heatNorth = squeeze(nansum(nansum(nansum(heatProbNorthEra(:, :, :, seasons(s,:)), 4), 2), 1));
    heatNorthCorrEra(s) = corr(heatNorth, mrsoNorthEra{s});
end

figure('Color', [1,1,1]);
colors = get(gca, 'colororder');
subplot(2,1,1);
hold on;
axis square;
box on;
grid on;
plot(heatNorthCorrNcep, 'x', 'Color', colors(1,:), 'MarkerSize', 15, 'LineWidth', 2);
plot(heatNorthCorrEra, 'x', 'Color', colors(2,:),'MarkerSize', 15, 'LineWidth', 2);
plot([0 5], [0 0], 'k--');
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
leg = legend('NCEP', 'ERA');
set(leg, 'location', 'northwest');
ylim([-1 1]);
xlim([.75 4.25]);
ylabel('Correlation');
set(gca, 'FontSize', 24);
title('North', 'FontSize', 24);

subplot(2,1,2);
hold on;
axis square;
box on;
grid on;
plot(heatSouthCorrNcep, 'x', 'Color', colors(1,:), 'MarkerSize', 15, 'LineWidth', 2);
plot(heatSouthCorrEra, 'x', 'Color', colors(2,:), 'MarkerSize', 15, 'LineWidth', 2);
plot([0 5], [0 0], 'k--');
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
leg = legend('NCEP', 'ERA');
set(leg, 'location', 'northwest');
ylim([-1 1]);
xlim([.75 4.25]);
ylabel('Correlation');
set(gca, 'FontSize', 24);
title('South', 'FontSize', 24);

export_fig mrso-heat-corr.eps;