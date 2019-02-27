models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'ccsm4', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fio-esm', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

rcp = 'rcp85';
timePeriodBase = [1961 2005];
timePeriodFuture = [2061 2085];

plotScatter = false;
plotMap = true;
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

        %load(['2017-nile-climate/output/tasmax-monthly-chg-cmip5-' rcp '-' num2str(timePeriodFuture(1)) '-' num2str(timePeriodFuture(end)) '-' models{m} '.mat']);
        %tempChgCmip5(:, :, :, m) = monthlyChg;

        fprintf('loading pr: %s...\n', models{m});
        prHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        prHistCmip5(:, :, :, :, m) = prHist{3} .* 3600 .* 24;
        prFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/' rcp '/pr/regrid/world'], 'pr', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
        prFutCmip5(:, :, :, :, m) = prFut{3} .* 3600 .* 24;
        
        
        fprintf('loading tas: %s...\n', models{m});
        tasHist = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', timePeriodBase(1), 'endYear', timePeriodBase(end));
        tasHistCmip5(:, :, :, :, m) = tasHist{3} - 273.15;
        tasFut = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/' rcp '/tas/regrid/world'], 'tas', 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));    
        tasFutCmip5(:, :, :, :, m) = tasFut{3} - 273.15;

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
    
    curInds = regionInds('nile-blue');
    latIndsBlue = curInds{1};
    lonIndsBlue = curInds{2};
    
    curInds = regionInds('nile-white');
    latIndsWhite = curInds{1};
    lonIndsWhite = curInds{2};
    
    
    latInds = [latIndsBlue latIndsWhite];
    lonInds = [lonIndsBlue lonIndsWhite];
    
    prFut = squeeze(nanmean(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    prHist = squeeze(nanmean(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    
    tasFut = squeeze(nanmean(nanmean(nanmean(tasFutCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    tasHist = squeeze(nanmean(nanmean(nanmean(tasHistCmip5(latInds, lonInds, :, months, :), 4), 2), 1));
    %tChg = squeeze(nanmean(nanmean(nanmean(tempChgCmip5(latInds-latIndsRegion(1)+1, lonInds-lonIndsRegion(1)+1, months, :)))));
    
    if plotMap
        curInds = regionInds('nile');
        latInds = curInds{1};
        lonInds = curInds{2};
        
        chg = squeeze(nanmean(nanmean(prFutCmip5(latInds, lonInds, :, :, :), 4), 3)) - ...
              squeeze(nanmean(nanmean(prHistCmip5(latInds, lonInds, :, :, :), 4), 3));
        
        
        prStdChg = [];
        
        for xlat = 1:length(latInds)
            for ylon = 1:length(lonInds)
                histStd = nanstd(squeeze(nanmean(prHistCmip5(latInds(xlat), lonInds(ylon), :, :, :), 4)), 1);
                futStd = nanstd(squeeze(nanmean(prFutCmip5(latInds(xlat), lonInds(ylon), :, :, :), 4)), 1);
                prStdChg(xlat, ylon, :) = (futStd - histStd);
            end
        end
        
        prStdSig = [];
        for xlat = 1:size(prStdChg, 1)
            for ylon = 1:size(prStdChg, 2)
                prStdSig(xlat, ylon) = length(find(sign(prStdChg(xlat, ylon, :)) == sign(nanmedian(prStdChg(xlat, ylon), 3))));
            end
        end
        
        coords1 = regions('nile-blue');
        coords1 = [coords1(1,:) coords1(2,:)];
        coords2 = regions('nile-white');
        coords2 = [coords2(1,:) coords2(2,:)];
        
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
                          'stippleInterval', 30, ...
                          'boxCoords', {[coords1;
                                         coords2]});
        plotFromDataFile(saveData);
        
        
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmedian(prStdChg, 3)}; 
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-.1 .1], ...
                          'cbXTicks', -.1:.05:.1, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['pr-std-chg-rcp45-annual.eps'], ...
                          'plotXUnits', ['mm/day'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'BrBG'), ...
                          'plotCountries', true, ...
                          'statData', prStdSig <= .67*length(models), ...
                          'stippleInterval', 30, ...
                          'boxCoords', {[coords1;
                                         coords2]});
        plotFromDataFile(saveData);
        
        
        chg = squeeze(nanmean(nanmean(tasFutCmip5(latInds, lonInds, :, :, :), 4), 3)) - ...
              squeeze(nanmean(nanmean(tasHistCmip5(latInds, lonInds, :, :, :), 4), 3));
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
                          'boxCoords', {[coords1;
                                         coords2]});
        plotFromDataFile(saveData);
    end
    
    
    
    if plotScatter
        
        % detrend pr
        prFutDt = prFut;
        prHistDt = prHist;
        
        for m = 1:size(prHist, 2)
            prFutDt(:,m) = detrend(prFutDt(:,m));
            prHistDt(:,m) = detrend(prHistDt(:,m));
        end
        
        prChg = squeeze(nanmean(prFut, 1) - nanmean(prHist, 1)) ./ squeeze(nanmean(prHist, 1));
        prStd = squeeze(nanstd(prFutDt, [], 1) - nanstd(prHistDt, [], 1)) ./ squeeze(nanstd(prHistDt, [], 1));
        
        prChg = prChg .* 100;
        prStd = prStd .* 100;
        
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
%         outind = find(pchg>nanmean(pchg)+2*std(pchg) | pchg<nanmean(pchg)-2*std(pchg) | ...
%              pstd>nanmean(pstd)+2*std(pstd) | pstd<nanmean(pstd)-2*std(pstd));
%         
%         pchg(outind) = [];
%         pstd(outind) = [];
%         
        [f,gof,output] = fit(pchg, pstd, 'poly1');
        lm = fitlm(pchg, pstd, 'linear');
        cint = confint(f);
        if lm.Coefficients.pValue(2) < .1
            plot([min(pchg) max(pchg)], [f(min(pchg)) f(max(pchg))], '--b', 'LineWidth', 2);
        end
        
        xlim([-40 80]);
        ylim([-100 150]);
        plot([-50 100], [0 0], '--k');
        plot([0 0], [-150 150], '--k');
        set(gca, 'FontSize', 36);
        xlabel('Precipitation change (%)');
        ylabel('P std. dev. change (%)');
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig pr-std-chg-rcp45-north.eps;
        close all;
        
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
    
