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
north = false;

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

latInds = curInds{1};
lonInds = curInds{2};

prFut = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
prHist = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, months, :), 4), 2), 1));

dryHist = squeeze(nanmean(nanmean(dryHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
wetHist = squeeze(nanmean(nanmean(wetHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
hotDryHist = squeeze(nanmean(nanmean(hotDryHist(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

dryFuture25 = squeeze(nanmean(nanmean(dryFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
wetFuture25 = squeeze(nanmean(nanmean(wetFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
hotDryFuture25 = squeeze(nanmean(nanmean(hotDryFuture25(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

dryFuture50 = squeeze(nanmean(nanmean(dryFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
wetFuture50 = squeeze(nanmean(nanmean(wetFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
hotDryFuture50 = squeeze(nanmean(nanmean(hotDryFuture50(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

dryFuture75 = squeeze(nanmean(nanmean(dryFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
wetFuture75 = squeeze(nanmean(nanmean(wetFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
hotDryFuture75 = squeeze(nanmean(nanmean(hotDryFuture75(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

dryFutureLate = squeeze(nanmean(nanmean(dryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
wetFutureLate = squeeze(nanmean(nanmean(wetFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));
hotDryFutureLate = squeeze(nanmean(nanmean(hotDryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, :), 2), 1));

prChg = (squeeze(nanmean(prFut, 1) - nanmean(prHist, 1))) ./ squeeze(nanmean(prHist,1));
prStd = (squeeze(nanstd(prFut, [], 1) - nanstd(prHist, [], 1))) ./ squeeze(nanstd(prHist,[],1));
prCoVar = squeeze(nanstd(prFut, [], 1) ./ nanmean(prFut, 1)) - ...
          squeeze(nanstd(prHist, [], 1) ./ nanmean(prHist, 1));

wet = true;
std = true;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

if std
    chgvar = prStd;
else
    chgvar = prChg;
end

if wet
    seasonvar = wetFutureLate;
else
    seasonvar = dryFutureLate;
end
    

for m = 1:size(prFut, 2)
    t = text(chgvar(m), seasonvar(m) * 100, num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
    t.FontSize = 18;
end

[f, gof] = fit(chgvar', seasonvar .* 100, 'poly1');
cint = confint(f);
p = plot([min(chgvar) max(chgvar)], [f(min(chgvar)) f(max(chgvar))], '--b', 'LineWidth', 2);

if std
    corrval = partialcorr([seasonvar, prStd'], prChg');
    corrval = corrval(2, 1);
else
    corrval = corr(seasonvar, chgvar');
end

xlim([-.4 1.2]);
set(gca, 'XTick', -.4:.4:1.2)
ylim([0 70]);
set(gca, 'YTick', 0:10:70)
if std
    xlabel('P std. dev. change (mm/day)');
else
    xlabel('Precipitation change (mm/day)');
end

if wet
    ylabel('Future wet season frequency (%)');
else
    ylabel('Future dry season frequency (%)');
end
set(gca, 'FontSize', 40);
if std
    legend([p], {sprintf('Partial correlation = %.2f', corrval)}, 'location', 'northeast');
else
    legend([p], {sprintf('Correlation = %.2f', corrval)}, 'location', 'northeast');
end
set(gcf, 'Position', get(0,'Screensize'));
if wet
    if std
        export_fig prstd-wet-south-rcp85.eps;
    else
        export_fig prchg-wet-south-rcp85.eps;
    end
else
    if std
        export_fig prstd-dry-south-rcp85.eps;
    else
        export_fig prchg-dry-south-rcp85.eps;
    end
end
close all;

