load(['2017-nile-climate\output\dryFuture-annual-cmip5-historical-1981-2005-t90-p10.mat']);
dryHist = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-historical-1981-2005-t90-p10.mat']);
wetHist = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-historical-1981-2005-t90-p10.mat']);
hotDryHist = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
dryFuture25 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
wetFuture25 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
hotDryFuture25 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
dryFuture50 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
wetFuture50 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
hotDryFuture50 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2075-2099-t90-p50-tfull-pfull.mat']);
dryFuture75 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2075-2099-t90-p50-tfull-pfull.mat']);
wetFuture75 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2075-2099-t90-p10-tfull-pfull.mat']);
hotDryFuture75 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2056-2080.mat']);
wetFutureLate = wetFuture;

% late period
load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2056-2080.mat']);
wetFutureLate = wetFuture;
load(['2017-nile-climate\output\hotFuture-annual-cmip5-rcp85-2056-2080.mat']);
hotFutureLate = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1981 2005];
timePeriodFuture = [2075 2099];

annual = true;

load lat;
load lon;

[regionInds, regions, regionNames] = ni_getRegions();

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

if ~exist('prHistCmip5', 'var')
    prHistCmip5 = [];
    prFutCmip5 = [];
    for m = 1:length(models)
        fprintf('loading pr: %s...\n', models{m});
        prHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        prHistCmip5(:, :, :, :, m) = prHist{3} .* 3600 .* 24;
        prFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/pr/regrid/world'], 'pr', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
        prFutCmip5(:, :, :, :, m) = prFut{3} .* 3600 .* 24;
    end
end

prChg = [];
prSig = [];
s = 1;

if annual
    months = 1:12;
else
    months = seasons(s,:);
end

curInds = regionInds('nile');
latIndsRegion = curInds{1};
lonIndsRegion = curInds{2};

curInds = regionInds('nile-blue');
latIndsBlue = curInds{1};
lonIndsBlue = curInds{2};

curInds = regionInds('nile-white');
latIndsWhite = curInds{1};
lonIndsWhite = curInds{2};

latIndsTotal = [latIndsBlue, latIndsWhite];
lonIndsTotal = [lonIndsBlue, lonIndsWhite];

prFutTotal = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));
prHistTotal = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));

prFutBlue = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsBlue, lonIndsBlue, :, months, :), 4), 2), 1));
prHistBlue = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsBlue, lonIndsBlue, :, months, :), 4), 2), 1));

prFutWhite = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsWhite, lonIndsWhite, :, months, :), 4), 2), 1));
prHistWhite = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsWhite, lonIndsWhite, :, months, :), 4), 2), 1));

% 
% dryHist = squeeze(nanmean(nanmean(dryHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% wetHist = squeeze(nanmean(nanmean(wetHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% hotDryHist = squeeze(nanmean(nanmean(hotDryHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% 
% dryFuture25 = squeeze(nanmean(nanmean(dryFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% wetFuture25 = squeeze(nanmean(nanmean(wetFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% hotDryFuture25 = squeeze(nanmean(nanmean(hotDryFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% 
% dryFuture50 = squeeze(nanmean(nanmean(dryFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% wetFuture50 = squeeze(nanmean(nanmean(wetFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% hotDryFuture50 = squeeze(nanmean(nanmean(hotDryFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% 
% dryFuture75 = squeeze(nanmean(nanmean(dryFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% wetFuture75 = squeeze(nanmean(nanmean(wetFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% hotDryFuture75 = squeeze(nanmean(nanmean(hotDryFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% 
% dryFutureLate = squeeze(nanmean(nanmean(dryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% wetFutureLate = squeeze(nanmean(nanmean(wetFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
% hotDryFutureLate = squeeze(nanmean(nanmean(hotDryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

prChgBlue = (squeeze(nanmean(prFutBlue, 1) - nanmean(prHistBlue, 1))) ./ squeeze(nanmean(prHistBlue,1)) .* 100;
prStdBlue = (squeeze(nanstd(prFutBlue, [], 1) - nanstd(prHistBlue, [], 1))) ./ squeeze(nanstd(prHistBlue,[],1)) .* 100;

prChgTotal = (squeeze(nanmean(prFutTotal, 1) - nanmean(prHistTotal, 1))) ./ squeeze(nanmean(prHistTotal,1)) .* 100;
prStdTotal = (squeeze(nanstd(prFutTotal, [], 1) - nanstd(prHistTotal, [], 1))) ./ squeeze(nanstd(prHistTotal,[],1)) .* 100;
prCVTotal = (squeeze(nanstd(prFutTotal, [], 1) ./ nanmean(prFutTotal, 1)) - squeeze(nanstd(prHistTotal, [], 1)./nanmean(prHistTotal, 1))) ./ ...
            squeeze(nanstd(prHistTotal, [], 1)./nanmean(prHistTotal, 1));

wet = true;
std = true;

prChgTotal = prChgTotal';
prStdTotal = prStdTotal';

[b,i] = sort(prChgTotal);
prChgTotal = prChgTotal(i);
prStdTotal = prStdTotal(i);

corrval = corr(prChgTotal(round(.1*length(models)):round(.9*length(models))), prStdTotal(round(.1*length(models)):round(.9*length(models))));

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
%pbaspect([2 1 1]);
axis square;

xlim([-20 60])
ylim([-75 100])

for m = 1:length(prChgTotal)
    prSig = kstest2(squeeze(prFutTotal(:, m)), squeeze(prHistTotal(:, m)));

    if prSig
        plot(prChgTotal(m), prStdTotal(m), 'o', 'MarkerSize', 30, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    else
        %plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    end
    t = text(prChgTotal(m), prStdTotal(m), num2str(i(m)), 'HorizontalAlignment', 'center', 'Color', 'k');
    t.FontSize = 22;
end

[f, gof] = fit(prChgTotal(round(.1*length(models)):round(.9*length(models))), prStdTotal(round(.1*length(models)):round(.9*length(models))), 'poly1');
cint = confint(f);
p = plot([prChgTotal(round(.1*length(models))) prChgTotal(round(.9*length(models)))], [f(prChgTotal(round(.1*length(models)))) f(prChgTotal(round(.9*length(models))))], '--b', 'LineWidth', 2);

plot([-20 80], [0 0], '--k', 'linewidth', 2);
plot([0 0], [-80 100], '--k', 'linewidth', 2);

ylabel('P std. dev. change (%)');
xlabel('Precipitation change (%)');

set(gca, 'FontSize', 40);
legend([p], {sprintf('Correlation = %.2f', corrval)}, 'location', 'northeast');
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-std-total.eps;
close all;

