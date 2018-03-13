% late period
load(['2017-nile-climate\output\dryFuture-cmip5-rcp85-2056-2080.mat']);
dryFutureLate = dryFuture;
load(['2017-nile-climate\output\wetFuture-cmip5-rcp85-2056-2080.mat']);
wetFutureLate = wetFuture;
load(['2017-nile-climate\output\hotFuture-cmip5-rcp85-2056-2080.mat']);
hotFutureLate = hotFuture;
load(['2017-nile-climate\output\hotDryFuture-cmip5-rcp85-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1980 2004];
timePeriodFuture = [2056 2080];

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

    if annual
        months = 1:12;
    else
        months = seasons(s,:);
    end
    
    curInds = regionInds('nile');
    latIndsRegion = curInds{1};
    lonIndsRegion = curInds{2};
    
    if north
        curInds = regionInds('nile-north');
    else
        curInds = regionInds('nile-south');
    end
    latInds = curInds{1};
    lonInds = curInds{2};
    
    prFut = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    prHist = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    
    dryFutureLate = squeeze(nanmean(nanmean(nanmean(dryFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    wetFutureLate = squeeze(nanmean(nanmean(nanmean(wetFutureLate(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :), 3), 2), 1));
    
    prChg(s, :) = squeeze(nanmean(prFut, 1) - nanmean(prHist, 1));
    prStd = squeeze(nanstd(prFut, [], 1) - nanstd(prHist, [], 1));

    % prchg vs prstd chg
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;

    for m = 1:size(prFut, 2)
        prSig(s, m) = kstest2(squeeze(prFut(:, m)), squeeze(prHist(:, m)));

        if prSig(s, m)
            plot(prChg(m), prStd(m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
        end
        t = text(prChg(m), prStd(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end

    pchg = prChg';
    pstd = prStd';
    outind = find(pchg>nanmean(pchg)+2*std(pchg) | pchg<nanmean(pchg)-2*std(pchg) | ...
             pstd>nanmean(pstd)+2*std(pstd) | pstd<nanmean(pstd)-2*std(pstd));

    pchg(outind) = [];
    pstd(outind) = [];

    f = fit(pchg, pstd, 'poly1');
    cint = confint(f);
    if sign(cint(1,1)) == sign(cint(2,1))
        plot([min(pchg) max(pchg)], [f(min(pchg)) f(max(pchg))], '--b', 'LineWidth', 2);
    end

    if north
        xlim([-.2 .4]);
        set(gca, 'XTick', -.2:.1:.4)
    else
        xlim([-.6 1.2]);
        set(gca, 'XTick', -.6:.3:1.2)
    end
    xlabel('Precipitation change (mm/day)');
    ylim([-.2 .3]);
    set(gca, 'YTick', -.2:.1:.3);
    ylabel('Precipitation std. dev. change (mm/day)');
    set(gca, 'FontSize', 36);
