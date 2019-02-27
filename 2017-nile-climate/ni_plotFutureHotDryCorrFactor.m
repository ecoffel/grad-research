base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1961-2005-t83-p20.mat']);
hotDryHistorical83 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1961-2005-t85-p15.mat']);
hotDryHistorical85 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1961-2005-t95-p5.mat']);
hotDryHistorical95 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2061-2085-t83-p20-tfull-pfull.mat']);
hotDryFutureLate45 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2061-2085-t83-p20-tfull-pfull.mat']);
hotDryFutureLate85 = hotDryFuture;

drawScatter = false;
drawMap = true;
north = false;
annual = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];
seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};

load lat;
load lon;

[regionInds, regions, regionNames] = ni_getRegions();
curInds = regionInds('nile');

latIndsRegion = curInds{1};
lonIndsRegion = curInds{2};
curIndsBlue = regionInds(['nile-blue']);
curIndsWhite = regionInds(['nile-white']);
curLatIndsBlue = curIndsBlue{1} - latIndsRegion(1) + 1;
curLonIndsBlue = curIndsBlue{2} - lonIndsRegion(1) + 1;
curLatIndsWhite = curIndsWhite{1} - latIndsRegion(1) + 1;
curLonIndsWhite = curIndsWhite{2} - lonIndsRegion(1) + 1;
curLatInds = [curLatIndsBlue curLatIndsWhite];
curLonInds = [curLonIndsBlue curLonIndsWhite];

multHist83 = squeeze(nanmean(nanmean(hotDryHistorical83(curLatInds, curLonInds, :), 2), 1)) ./ ((.20)*(1-.83));
multHist85 = squeeze(nanmean(nanmean(hotDryHistorical85(curLatInds, curLonInds, :), 2), 1)) ./ ((.15)*(1-.85));
multHist95 = squeeze(nanmean(nanmean(hotDryHistorical95(curLatInds, curLonInds, :), 2), 1)) ./ ((.05)*(1-.95));

colors = brewermap(5, 'Reds');

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

b = boxplot([multHist83 multHist85 multHist95], 'positions', [1 2 3], 'width', .3);

set(b(:, 1), {'LineWidth', 'Color'}, {3, colors(3,:)})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

set(b(:, 2), {'LineWidth', 'Color'}, {3, colors(4,:)})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

set(b(:, 3), {'LineWidth', 'Color'}, {3, colors(5,:)})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

plot([0 4], [1 1], '--k', 'linewidth', 2);

set(gca,'TickLabelInterpreter', 'tex');

ylim([0 7]);
xlim([.5 3.5]);
set(gca, 'YTick', 0:1:7);
ylabel('Frequency multiplier');
set(gca, 'XTick', 1:1:3, 'XTickLabels', {'T_{83}/P_{20}', 'T_{85}/P_{15}', 'T_{95}/P_{5}'});
set(gca, 'FontSize', 40);
xtickangle(90);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['hot-dry-corr-mult-historical.eps']);
close all;




