models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'ccsm4', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fio-esm', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1961 2005];
timePeriodFuture = [2061 2085];

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
    tasHistCmip5 = [];
    tasFutCmip5 = [];
    for m = 1:length(models)
        fprintf('loading pr: %s...\n', models{m});
        prHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        prHistCmip5(:, :, :, :, m) = prHist{3} .* 3600 .* 24;
        
        prFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/pr/regrid/world'], 'pr', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
        prFutCmip5(:, :, :, :, m) = prFut{3} .* 3600 .* 24;
        
        
        fprintf('loading tas: %s...\n', models{m});
        tasHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        tasHistCmip5(:, :, :, :, m) = tasHist{3} - 273.15;
        
        tasFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/tas/regrid/world'], 'tas', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
        tasFutCmip5(:, :, :, :, m) = tasFut{3} - 273.15;
    end
end

prChg = [];
prSig = [];

months = 1:12;

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

tasFutTotal = squeeze(nanmean(nanmean(nanmean(tasFutCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));
tasHistTotal = squeeze(nanmean(nanmean(nanmean(tasHistCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));

prFutTotal = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));
prHistTotal = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsTotal, lonIndsTotal, :, months, :), 4), 2), 1));

prFutBlue = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsBlue, lonIndsBlue, :, months, :), 4), 2), 1));
prHistBlue = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsBlue, lonIndsBlue, :, months, :), 4), 2), 1));

prFutWhite = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latIndsWhite, lonIndsWhite, :, months, :), 4), 2), 1));
prHistWhite = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latIndsWhite, lonIndsWhite, :, months, :), 4), 2), 1));

hdHist = [];
hdFut = [];

for m = 1:length(models)
    prHistMean = nanmean(prHistCmip5(latIndsTotal, lonIndsTotal, :, months, m), 4);
    prFutMean = nanmean(prFutCmip5(latIndsTotal, lonIndsTotal, :, months, m), 4);
    
    tasHistMean = nanmean(tasHistCmip5(latIndsTotal, lonIndsTotal, :, months, m), 4);
    tasFutMean = nanmean(tasFutCmip5(latIndsTotal, lonIndsTotal, :, months, m), 4);
    
    for xlat = 1:size(prHistMean,1)
        for ylon = 1:size(prHistMean,2)
            hdHist(xlat,ylon,m) = length(find(prHistMean(xlat,ylon,:) < prctile(prHistMean(xlat,ylon,:), 50) & tasHistMean(xlat,ylon,:) > prctile(tasHistMean(xlat,ylon,:), 50)));
            hdFut(xlat,ylon,m) = length(find(prFutMean(xlat,ylon,:) < prctile(prHistMean(xlat,ylon,:), 50) & tasFutMean(xlat,ylon,:) > prctile(tasHistMean(xlat,ylon,:), 50)));
        end
    end
            
end

taschg = squeeze(nanmean(nanmean(tasFutCmip5(latIndsTotal, lonIndsTotal, :, months, :),4),3))-squeeze(nanmean(nanmean(tasHistCmip5(latIndsTotal, lonIndsTotal, :, months, :),4),3));
prchg = squeeze(nanmean(nanmean(prFutCmip5(latIndsTotal, lonIndsTotal, :, months, :),4),3))-squeeze(nanmean(nanmean(prHistCmip5(latIndsTotal, lonIndsTotal, :, months, :),4),3));

prstdhist = [];
prstdfut = [];
for m = 1:length(models)
    for xlat = 1:length(latIndsTotal)
        for ylon = 1:length(lonIndsTotal)
            prstdhist(xlat, ylon, m) = nanstd(detrend(squeeze(nanmean(prHistCmip5(latIndsTotal(xlat), lonIndsTotal(ylon), :, months, m),4))));
            prstdfut(xlat, ylon, m) = nanstd(detrend(squeeze(nanmean(prFutCmip5(latIndsTotal(xlat), lonIndsTotal(ylon), :, months, m),4))));
        end
    end
end

prstdchg = prstdfut - prstdhist;


prchg = reshape(prchg,[size(prchg,1)*size(prchg,2),size(prchg,3)]);
prchg = normc(prchg);
prchg = reshape(prchg, [size(prchg,1)*size(prchg,2),1]);

taschg = reshape(taschg,[size(taschg,1)*size(taschg,2),size(taschg,3)]);
taschg = normc(taschg);
taschg = reshape(taschg, [size(taschg,1)*size(taschg,2),1]);

prstdchg = reshape(prstdchg,[size(prstdchg,1)*size(prstdchg,2),size(prstdchg,3)]);
prstdchg = normc(prstdchg);
prstdchg = reshape(prstdchg, [size(prstdchg,1)*size(prstdchg,2),1]);

hdchg = reshape(hdFut-hdHist,[size(hdHist,1)*size(hdHist,2),size(hdHist,3)]);
hdchg = normc(hdchg);
hdchg = reshape(hdchg,[size(hdchg,1)*size(hdchg,2),1]);

f = fitlm([prchg, prstdchg], hdchg, 'interactions');

colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

figure('color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1,2,1]);

b = bar([1 1.5 2], f.Coefficients.Estimate(2:4));
set(b, 'barwidth', .9, 'edgecolor', [0 0 0], 'linewidth', 2, 'facecolor', 'flat');
b.CData(1,:) = colorW;
b.CData(2,:) = colorD;
b.CData(3,:) = colorHd;

ylim([-.8 .8]);
xlim([.5 2.5]);
set(gca, 'fontsize', 40);
set(gca, 'ytick', [-.75:.25:.75]);
ylabel('Normalized coefficient');
set(gca, 'xtick', [1 1.5 2], 'xticklabels', {'P Chg^*', 'P STD Chg^*', 'Interaction^*'});
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig hd-chg-contrib.eps;
close all;


prChgBlue = (squeeze(nanmean(prFutBlue, 1) - nanmean(prHistBlue, 1))) ./ squeeze(nanmean(prHistBlue,1)) .* 100;
prStdBlue = (squeeze(nanstd(prFutBlue, [], 1) - nanstd(prHistBlue, [], 1))) ./ squeeze(nanstd(prHistBlue,[],1)) .* 100;

prHist = squeeze(nanmean(prHistTotal,1));
prStdHist = squeeze(nanstd(detrend(prHistTotal(:, m)),[],1));

prChgTotal = (squeeze(nanmean(prFutTotal, 1) - nanmean(prHistTotal, 1)));

prStdTotal = [];
for m = 1:length(models)
    prStdTotal(m) = (squeeze(nanstd(detrend(prFutTotal(:, m)), [], 1) - nanstd(detrend(prHistTotal(:, m)), [], 1)));
end

prChgTotal = (prChgTotal ./ prHist)' .* 100;
prStdTotal = (prStdTotal ./ prStdHist)' .* 100;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
%pbaspect([2 1 1]);
axis square;

xlim([-12 120])
ylim([-50 60])

for m = 1:length(prChgTotal)
    prSig = kstest2(squeeze(prFutTotal(:, m)), squeeze(prHistTotal(:, m)));

    if prSig
        plot(prChgTotal(m), prStdTotal(m), 'o', 'MarkerSize', 30, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    else
        %plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    end
    t = text(prChgTotal(m), prStdTotal(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
    t.FontSize = 22;
end

[b,i] = sort(prChgTotal);
prChgTotal = prChgTotal(i);
prStdTotal = prStdTotal(i);

[f, gof] = fit(prChgTotal, prStdTotal, 'poly1');
cint = confint(f);
p = plot([prChgTotal(1) prChgTotal(end)], [f(prChgTotal(1)) f(prChgTotal(end))], '--b', 'LineWidth', 2);
f = fitlm(prChgTotal, prStdTotal);

plot([-20 80], [0 0], '--k', 'linewidth', 2);
plot([0 0], [-80 170], '--k', 'linewidth', 2);

plot([-200 200], [-200 200], '-', 'color', [.5 .5 .5]);

ylabel('P STD change (%)');
xlabel('Precipitation change (%)');

set(gca, 'xtick', [0 20 40]);
set(gca, 'FontSize', 40);
legend([p], {sprintf('Slope = %.2f, p = %.2f', f.Coefficients.Estimate(2), f.Coefficients.pValue(2))}, 'location', 'northwest');
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-std-total.eps;
close all;

