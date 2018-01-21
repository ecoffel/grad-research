models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1980 2004];
timePeriodFuture = [2056 2080];

plotScatter = true;
plotMap = false;

load lat;
load lon;

% % loads into prSeasonal
% load 2017-nile-climate\output\pr-seasonal-chirps.mat;
% 
% % loads into historicalPr
% load(['2017-nile-climate/output/historical-pr-percentiles-chirps.mat']);

[regionInds, regions, regionNames] = ni_getRegions();

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

if ~exist('tempChgCmip5', 'var')
tempChgCmip5 = [];
prHistCmip5 = [];
prFutCmip5 = [];
for m = 1:length(models)
    
    load(['2017-nile-climate/output/tasmax-monthly-chg-cmip5-' rcp '-' num2str(timePeriodFuture(1)) '-' num2str(timePeriodFuture(end)) '-' models{m} '.mat']);
    tempChgCmip5(:, :, :, m) = monthlyChg;
    
    fprintf('loading pr: %s...\n', models{m});
    prHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
    prHistCmip5(:, :, :, :, m) = prHist{3} .* 3600 .* 24;
    prFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/pr/regrid/world'], 'pr', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
    prFutCmip5(:, :, :, :, m) = prFut{3} .* 3600 .* 24;

end
end

prChg = [];
prSig = [];

for s = 1:size(seasons, 1)
    
    curInds = regionInds('nile');
    latIndsRegion = curInds{1};
    lonIndsRegion = curInds{2};
    
    curInds = regionInds('nile-south');
    latInds = curInds{1};
    lonInds = curInds{2};
    prFut = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, seasons(s, :), :), 4), 2), 1));
    prHist = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, seasons(s, :), :), 4), 2), 1));
    tChg = squeeze(nanmean(nanmean(nanmean(tempChgCmip5(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, seasons(s, :), :)))));
    
    if plotMap
        curInds = regionInds('nile');
        latInds = curInds{1};
        lonInds = curInds{2};
        chg = squeeze(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, seasons(s, :), :), 4), 3)) - ...
              squeeze(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, seasons(s, :), :), 4), 3));
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmedian(chg, 3)}; 
        sig = [];
        for xlat = 1:size(chg, 1)
            for ylon = 1:size(chg, 2)
                sig(xlat, ylon) = length(find(sign(chg(xlat, ylon, :)) == sign(nanmedian(chg(xlat, ylon), 3))));
            end
        end

        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-1 1], ...
                          'cbXTicks', -1:.5:1, ...
                          'plotTitle', [seasonNames{s}], ...
                          'fileTitle', ['pr-chg-' seasonNames{s} '.eps'], ...
                          'plotXUnits', ['Precipitation change (mm/day)'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'BrBG'), ...
                          'plotCountries', true, ...
                          'statData', sig <= .75*length(models), ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
    end
    
    
    
    if plotScatter
        figure('Color', [1,1,1]);
        hold on;
        box on;
        grid on;
        axis square;

        prChg(s, :) = squeeze(nanmean(prFut, 1) - nanmean(prHist, 1));
        for m = 1:size(prFut, 2)
            prSig(s, m) = kstest2(squeeze(prFut(:, m)), squeeze(prHist(:, m)));

            if prSig(s, m)
                %plot(tChg(m), prChg(s, m), 'o', 'Color', [85/255.0, 158/255.0, 237/255.0], 'MarkerFaceColor', [115/255.0, 188/255.0, 237/255.0], 'MarkerSize', 25);
                plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
            else
                %plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
            end
            t = text(tChg(m), prChg(s, m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
            t.FontSize = 18;
        end
        
        plot([-1 10], [0 0], '--k', 'LineWidth', 2);

        xlim([0 7]);
        set(gca, 'XTick', 0:7);
        ylim([-1.5 1.5]);
        set(gca, 'YTick', -1.5:.5:1.5);
        xlabel(['Temperature change (' char(176) 'C)']);
        ylabel('Precipitation change (mm/day)');
        set(gca, 'FontSize', 36);
        title([seasonNames{s}]);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['temp-pr-chg-south-' seasonNames{s} '.eps']);
        close all;
    end
end
    
