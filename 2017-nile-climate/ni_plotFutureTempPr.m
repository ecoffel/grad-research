models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1980 2004];
timePeriodFuture = [2056 2080];

plotScatter = true;
plotMap = false;
annual = true;

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

for s = 1%:size(seasons, 1)
    
    if annual
        months = 1:12;
    else
        months = seasons(s,:);
    end
    
    curInds = regionInds('nile');
    latIndsRegion = curInds{1};
    lonIndsRegion = curInds{2};
    
    curInds = regionInds('nile-south');
    latInds = curInds{1};
    lonInds = curInds{2};
    prFut = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    prHist = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    tChg = squeeze(nanmean(nanmean(nanmean(tempChgCmip5(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :)))));
    
    if plotMap
        curInds = regionInds('nile');
        latInds = curInds{1};
        lonInds = curInds{2};
        chg = squeeze(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, :, :), 4), 3)) - ...
              squeeze(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, :, :), 4), 3));
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmedian(chg, 3)}; 
        sig = [];
        for xlat = 1:size(chg, 1)
            for ylon = 1:size(chg, 2)
                sig(xlat, ylon) = length(find(sign(chg(xlat, ylon, :)) == sign(nanmedian(chg(xlat, ylon), 3))));
            end
        end

        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-.5 .5], ...
                          'cbXTicks', -.5:.25:.5, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['pr-chg-rcp45-annual.eps'], ...
                          'plotXUnits', ['mm/day'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'BrBG'), ...
                          'plotCountries', true, ...
                          'statData', sig <= .67*length(models), ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
        
        
        chg = squeeze(nanmean(nanmean(tempChgCmip5(:, :, :, :), 4), 3));
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmedian(chg, 3)}; 
        sig = [];
        for xlat = 1:size(chg, 1)
            for ylon = 1:size(chg, 2)
                sig(xlat, ylon) = length(find(sign(chg(xlat, ylon, :)) == sign(nanmedian(chg(xlat, ylon), 3))));
            end
        end

        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [2 5], ...
                          'cbXTicks', 2:5, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['temp-chg-rcp45-annual.eps'], ...
                          'plotXUnits', [char(176) 'C'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'Reds'), ...
                          'plotCountries', true, ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
    end
    
    
    
    if plotScatter
        
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
                %plot(tChg(m), prChg(s, m), 'o', 'Color', [85/255.0, 158/255.0, 237/255.0], 'MarkerFaceColor', [115/255.0, 188/255.0, 237/255.0], 'MarkerSize', 25);
                plot(prChg(m), prStd(m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
            else
                %plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
            end
            if tChg(m) < 7
                t = text(prChg(m), prStd(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
                t.FontSize = 18;
            end
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
        
        xlim([-.5 1.5]);
        ylim([-.12 .2]);
        set(gca, 'FontSize', 36);
        xlabel('Precipitation change (mm/day)');
        ylabel('P std. dev. change (mm/day)');
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig pr-std-chg-rcp85-south.eps;
        
        figure('Color', [1,1,1]);
        hold on;
        box on;
        grid on;
        axis square;

        for m = 1:size(prFut, 2)
            prSig(s, m) = kstest2(squeeze(prFut(:, m)), squeeze(prHist(:, m)));

            if prSig(s, m)
                %plot(tChg(m), prChg(s, m), 'o', 'Color', [85/255.0, 158/255.0, 237/255.0], 'MarkerFaceColor', [115/255.0, 188/255.0, 237/255.0], 'MarkerSize', 25);
                if tChg(m) < 7
                    plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
                end
            else
                %plot(tChg(m), prChg(s, m), 'o', 'MarkerSize', 25, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
            end
            if tChg(m) < 7
                t = text(tChg(m), prChg(s, m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
                t.FontSize = 18;
            end
        end
        
        tfit = tChg;
        prfit = (squeeze(prChg(s,:)))';
        outind = find(prfit>nanmean(prfit)+2*std(prfit) | prfit<nanmean(prfit)-2*std(prfit) | ...
             tfit>nanmean(tfit)+2*std(tfit) | tfit<nanmean(tfit)-2*std(tfit));
        tfit(outind) = [];
        prfit(outind) = [];
        f = fit(tfit, prfit, 'poly1');
        cint = confint(f);
        if sign(cint(1,1)) == sign(cint(2,1))
            plot([min(tChg) max(tChg)], [f(min(tChg)) f(max(tChg))], '--b', 'LineWidth', 2);
        end
        
        plot([-1 10], [0 0], '--k', 'LineWidth', 2);

        xlim([0 7]);
        set(gca, 'XTick', 0:7);
        ylim([-1.5 1.5]);
        set(gca, 'YTick', -1.5:.5:1.5);
        xlabel(['Temperature change (' char(176) 'C)']);
        ylabel('Precipitation change (mm/day)');
        set(gca, 'FontSize', 36);
        %title([seasonNames{s}]);
        set(gcf, 'Position', get(0,'Screensize'));
        seasonStr = seasonNames{s};
        if annual
            seasonStr = 'annual';
        end
        export_fig(['temp-pr-chg-rcp85-south-' seasonStr '.eps']);
        close all;
    end
end
    
