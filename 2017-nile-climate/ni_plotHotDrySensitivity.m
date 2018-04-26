base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004-t75-p25.mat']);
hotDryHistorical75 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004-t80-p20.mat']);
hotDryHistorical80 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004-t85-p15.mat']);
hotDryHistorical85 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004.mat']);
hotDryHistorical90 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004-t95-p5.mat']);
hotDryHistorical95 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080-t75-p25.mat']);
hotDryFuture45Late75 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080-t80-p20.mat']);
hotDryFuture45Late80 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080-t85-p15.mat']);
hotDryFuture45Late85 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080.mat']);
hotDryFuture45Late90 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080-t95-p5.mat']);
hotDryFuture45Late95 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t75-p25.mat']);
hotDryFutureLate75 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t80-p20.mat']);
hotDryFutureLate80 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t85-p15.mat']);
hotDryFutureLate85 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080.mat']);
hotDryFutureLate90 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t95-p5.mat']);
hotDryFutureLate95 = hotDryFuture;

north = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

if north
    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;
else
    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;
end

hotdry75 = hotDryFutureLate75;
hotdry75 = hotdry75(curLatInds, curLonInds, :);
hotdry75 = squeeze(nanmean(nanmean(hotdry75,2),1));
hotdryHist75 = hotDryHistorical75;
hotdryHist75 = hotdryHist75(curLatInds, curLonInds, :);
hotdryHist75 = squeeze(nanmean(nanmean(hotdryHist75,2),1));
hotdry75 = hotdry75 ./ hotdryHist75;
hotdry75(isinf(hotdry75)) = NaN;

hotdry45_75 = hotDryFuture45Late75;
hotdry45_75 = hotdry45_75(curLatInds, curLonInds, :);
hotdry45_75 = squeeze(nanmean(nanmean(hotdry45_75,2),1));
hotdryHist75 = hotDryHistorical75;
hotdryHist75 = hotdryHist75(curLatInds, curLonInds, [1:9 11:end]);
hotdryHist75 = squeeze(nanmean(nanmean(hotdryHist75,2),1));
hotdry45_75 = hotdry45_75 ./ hotdryHist75;
hotdry45_75(isinf(hotdry45_75)) = NaN;

hotdry80 = hotDryFutureLate80;
hotdry80 = hotdry80(curLatInds, curLonInds, :);
hotdry80 = squeeze(nanmean(nanmean(hotdry80,2),1));
hotdryHist80 = hotDryHistorical80;
hotdryHist80 = hotdryHist80(curLatInds, curLonInds, :);
hotdryHist80 = squeeze(nanmean(nanmean(hotdryHist80,2),1));
hotdry80 = hotdry80 ./ hotdryHist80;
hotdry80(isinf(hotdry80)) = NaN;

hotdry45_80 = hotDryFuture45Late80;
hotdry45_80 = hotdry45_80(curLatInds, curLonInds, :);
hotdry45_80 = squeeze(nanmean(nanmean(hotdry45_80,2),1));
hotdryHist80 = hotDryHistorical80;
hotdryHist80 = hotdryHist80(curLatInds, curLonInds, [1:9 11:end]);
hotdryHist80 = squeeze(nanmean(nanmean(hotdryHist80,2),1));
hotdry45_80 = hotdry45_80 ./ hotdryHist80;
hotdry45_80(isinf(hotdry45_80)) = NaN;

hotdry85 = hotDryFutureLate85;
hotdry85 = hotdry85(curLatInds, curLonInds, :);
hotdry85 = squeeze(nanmean(nanmean(hotdry85,2),1));
hotdryHist85 = hotDryHistorical85;
hotdryHist85 = hotdryHist85(curLatInds, curLonInds, :);
hotdryHist85 = squeeze(nanmean(nanmean(hotdryHist85,2),1));
hotdry85 = hotdry85 ./ hotdryHist85;
hotdry85(isinf(hotdry85)) = NaN;

hotdry45_85 = hotDryFuture45Late85;
hotdry45_85 = hotdry45_85(curLatInds, curLonInds, :);
hotdry45_85 = squeeze(nanmean(nanmean(hotdry45_85,2),1));
hotdryHist85 = hotDryHistorical85;
hotdryHist85 = hotdryHist85(curLatInds, curLonInds, [1:9 11:end]);
hotdryHist85 = squeeze(nanmean(nanmean(hotdryHist85,2),1));
hotdry45_85 = hotdry45_85 ./ hotdryHist85;
hotdry45_85(isinf(hotdry45_85)) = NaN;

hotdry90 = hotDryFutureLate90;
hotdry90 = hotdry90(curLatInds, curLonInds, :);
hotdry90 = squeeze(nanmean(nanmean(hotdry90,2),1));
hotdryHist90 = hotDryHistorical90;
hotdryHist90 = hotdryHist90(curLatInds, curLonInds, :);
hotdryHist90 = squeeze(nanmean(nanmean(hotdryHist90,2),1));
hotdry90 = hotdry90 ./ hotdryHist90;
hotdry90(isinf(hotdry90)) = NaN;

hotdry45_90 = hotDryFuture45Late90;
hotdry45_90 = hotdry45_90(curLatInds, curLonInds, :);
hotdry45_90 = squeeze(nanmean(nanmean(hotdry45_90,2),1));
hotdryHist90 = hotDryHistorical90;
hotdryHist90 = hotdryHist90(curLatInds, curLonInds, [1:9 11:end]);
hotdryHist90 = squeeze(nanmean(nanmean(hotdryHist90,2),1));
hotdry45_90 = hotdry45_90 ./ hotdryHist90;
hotdry45_90(isinf(hotdry45_90)) = NaN;

hotdry95 = hotDryFutureLate95;
hotdry95 = hotdry95(curLatInds, curLonInds, :);
hotdry95 = squeeze(nanmean(nanmean(hotdry95,2),1));
hotdryHist95 = hotDryHistorical95;
hotdryHist95 = hotdryHist95(curLatInds, curLonInds, :);
hotdryHist95 = squeeze(nanmean(nanmean(hotdryHist95,2),1));
hotdry95 = hotdry95 ./ hotdryHist95;
hotdry95(isinf(hotdry95)) = NaN;

hotdry45_95 = hotDryFuture45Late95;
hotdry45_95 = hotdry45_95(curLatInds, curLonInds, :);
hotdry45_95 = squeeze(nanmean(nanmean(hotdry45_95,2),1));
hotdryHist95 = hotDryHistorical95;
hotdryHist95 = hotdryHist95(curLatInds, curLonInds, [1:9 11:end]);
hotdryHist95 = squeeze(nanmean(nanmean(hotdryHist95,2),1));
hotdry45_95 = hotdry45_95 ./ hotdryHist95;
hotdry45_95(isinf(hotdry45_95)) = NaN;


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

e1 = errorbar([74.5 79.5 84.5 89.5 94.5], [nanmedian(hotdry45_75) nanmedian(hotdry45_80) nanmedian(hotdry45_85) nanmedian(hotdry45_90) nanmedian(hotdry45_95)], ...
                           [nanstd(hotdry45_75)    nanstd(hotdry45_80)    nanstd(hotdry45_85)    nanstd(hotdry45_90)    nanstd(hotdry45_95)]);

e2 = errorbar([75.5 80.5 85.5 90.5 95.5], [nanmedian(hotdry75) nanmedian(hotdry80) nanmedian(hotdry85) nanmedian(hotdry90) nanmedian(hotdry95)], ...
                           [nanstd(hotdry75)    nanstd(hotdry80)    nanstd(hotdry85)    nanstd(hotdry90)    nanstd(hotdry95)]);


set(e1, 'LineWidth', 2);
set(e2, 'LineWidth', 2);
xlim([72 97]);
plot([0 100], [0 0], '--k');
ylabel('Increase in frequency (multiple)');
xlabel('Temperature percentile');
set(gca, 'FontSize', 40);
set(gcf, 'Position', get(0,'Screensize'));
legend([e2,e1],{'RCP 8.5', 'RCP 4.5'},'location','northwest');

if north
    export_fig(['hot-dry-freq-multiplier-' base '-north.eps']);
else
    export_fig(['hot-dry-freq-multiplier-' base '-south.eps']);
end
close all;
