dataset = 'cmip5';

findHeatWaves = false;
plotMaps = false;

coordPairs = csvread('ni-region.txt');

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
        timePeriod = [1980 2004];
        rcp = 'historical';
        
    case 'era-interim'
        timePeriod = [1980 2016];
        fprintf('loading ERA temps...\n');
        tmaxHistorical = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxHistorical{3} = tmaxHistorical{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) - 273.15;
        models = {''};
        
    case 'ncep-reanalysis'
        timePeriod = [1980 2016];
        fprintf('loading NCEP temps...\n');
        tmaxHistorical = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxHistorical{3} = tmaxHistorical{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) - 273.15;
        models = {''};
end

numYears = (timePeriod(end)-timePeriod(1)+1);

load lat;
load lon;

[regionInds, regions, regionNames] = ni_getRegions();

curInds = regionInds('nile');
latInds = curInds{1};
lonInds = curInds{2};

% temperature percentile for a heat wave 
threshPrc = 99;

if findHeatWaves
    
    for model = 1:length(models)

        % if needed, load current cmip5 model
        fprintf('loading historical %s\n', models{model});
        tmaxHistorical = loadDailyData(['e:/data/cmip5/output/' models{model} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
        tmaxHistorical = tmaxHistorical{3};
        if nanmean(nanmean(nanmean(nanmean(nanmean(tmaxHistorical))))) > 100
            tmaxHistorical = tmaxHistorical - 273.15;
        end
        tmaxHistorical = tmaxHistorical(latInds, lonInds, :, :, :);

        if ~strcmp(rcp, 'historical')
            fprintf('loading future %s\n', models{model});
            tmaxFuture = loadDailyData(['e:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
            tmaxFuture = tmaxFuture{3};
            if nanmean(nanmean(nanmean(nanmean(nanmean(tmaxFuture))))) > 100
                tmaxFuture = tmaxFuture - 273.15;
            end
            tmaxFuture = tmaxFuture(latInds, lonInds, :, :, :);
            [heatWaveDurMean, heatWaveDurMax, heatWaveIntMean, heatWaveIntMax] = ni_findHeatWaveStats(tmaxHistorical, tmaxFuture, threshPrc);
        else
            [heatWaveDurMean, heatWaveDurMax, heatWaveIntMean, heatWaveIntMax] = ni_findHeatWaveStats(tmaxHistorical, tmaxHistorical, threshPrc);
        end
        
        heatWaves = {heatWaveDurMean, heatWaveDurMax, heatWaveIntMean, heatWaveIntMax};

        save(['2017-nile-climate/output/nile-heat-waves-99-' rcp '-' models{model} '-annual-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'heatWaves');

        clear tmaxHistorical tmaxFuture heatWaves;
    end
else
    
    heatWaveDurMeanHist = [];
    heatWaveDurMaxHist = [];
    heatWaveIntMeanHist = [];
    heatWaveIntMaxHist = [];
    
    heatWaveDurMeanFut = [];
    heatWaveDurMaxFut = [];
    heatWaveIntMeanFut = [];
    heatWaveIntMaxFut = [];
    
    for model = 1:length(models)
        load(['2017-nile-climate/output/nile-heat-waves-99-historical-' models{model} '-annual-1980-2004.mat']);
        heatWaveDurMeanHist(:, :, :, model) = heatWaves{1};
        heatWaveDurMaxHist(:, :, :, model) = heatWaves{2};
        heatWaveIntMeanHist(:, :, :, model) = heatWaves{3};
        heatWaveIntMaxHist(:, :, :, model) = heatWaves{4};
        
        load(['2017-nile-climate/output/nile-heat-waves-99-rcp85-' models{model} '-annual-2056-2080.mat']);
        heatWaveDurMeanFut(:, :, :, model) = heatWaves{1};
        heatWaveDurMaxFut(:, :, :, model) = heatWaves{2};
        heatWaveIntMeanFut(:, :, :, model) = heatWaves{3};
        heatWaveIntMaxFut(:, :, :, model) = heatWaves{4};
    end
    
    curInds = regionInds('nile-north');
    latIndsReg = curInds{1}-latInds(1)+1;
    lonIndsReg = curInds{2}-lonInds(1)+1;
    
    chgInt = squeeze(nanmean(nanmean(nanmean(heatWaveIntMaxFut(latIndsReg, lonIndsReg, :, :)))))-squeeze(nanmean(nanmean(nanmean(heatWaveIntMaxHist(latIndsReg, lonIndsReg, :, :)))));
    chgDur = squeeze(nanmean(nanmean(nanmean(heatWaveDurMaxFut(latIndsReg, lonIndsReg, :, :)))))-squeeze(nanmean(nanmean(nanmean(heatWaveDurMaxHist(latIndsReg, lonIndsReg, :, :)))));
    
    if plotMaps
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmean(nanmedian(heatWaveDurMaxHist,4),3)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [0 30], ...
                          'cbXTicks', 0:5:30, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['heat-wave-max-dur-hist.eps'], ...
                          'plotXUnits', ['Days'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'Reds'), ...
                          'plotCountries', true, ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
        
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmean(nanmedian(heatWaveDurMaxFut,4),3)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [0 30], ...
                          'cbXTicks', 0:5:30, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['heat-wave-max-dur-fut.eps'], ...
                          'plotXUnits', ['Days'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'Reds'), ...
                          'plotCountries', true, ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
    end
    
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    
    for m = 1:length(models)
        t = text(chgInt(m), chgDur(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end
    
    outInd = find(chgInt > nanmean(chgInt)+2*nanstd(chgInt) | chgInt < nanmean(chgInt)-2*nanstd(chgInt) | ...
                  chgDur > nanmean(chgDur)+2*nanstd(chgDur) | chgDur < nanmean(chgDur)-2*nanstd(chgDur));
    chgIntOut = chgInt;
    chgIntOut(outInd) = [];
    chgDurOut = chgDur;
    chgDurOut(outInd) = [];
    
    f = fit(chgIntOut, chgDurOut, 'poly1');
    cint = confint(f);
    if sign(cint(1,1)) == sign(cint(2,1))
        plot([min(chgIntOut) max(chgIntOut)], [f(min(chgIntOut)) f(max(chgIntOut))], '--b', 'LineWidth', 2);
    end
    
    xlim([0 8]);
    set(gca, 'XTick', 0:2:8);
    ylim([0 40]);
    set(gca, 'YTick', 0:10:40);
    xlabel(['Intensity (' char(176) 'C)']);
    ylabel(['Duration (consecutive days)']);
    set(gca, 'FontSize', 36);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig heat-wave-intensity-duration-north.eps;
    close all;
    
end
