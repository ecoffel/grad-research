dataset = 'cmip5';

findHeatWaves = false;

coordPairs = csvread('ni-region.txt');

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
        timePeriod = [2056 2080];
        rcp = 'rcp85';
        
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

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

% regionBoundsNorth = [[13 32]; [29, 34]];
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

lat = lat(latInds, lonInds);
lon = lon(latInds, lonInds);

drawMaps = false;
drawLines = false;

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

        fprintf('loading future %s\n', models{model});
        tmaxFuture = loadDailyData(['e:/data/cmip5/output/' models{model} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        tmaxFuture = tmaxFuture{3};
        if nanmean(nanmean(nanmean(nanmean(nanmean(tmaxFuture))))) > 100
            tmaxFuture = tmaxFuture - 273.15;
        end
        tmaxFuture = tmaxFuture(latInds, lonInds, :, :, :);

        [heatWaveDurMean, heatWaveDurMax, heatWaveInt] = ni_findHeatWaveStats(tmaxHistorical, tmaxFuture, threshPrc);

        heatWaves = {heatWaveDurMean, heatWaveDurMax, heatWaveInt};

        save(['2017-nile-climate/output/nile-heat-waves-99-' rcp '-' models{model} '-annual-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'heatWaves');

        clear tmaxHistorical tmaxFuture heatWaves;
    end
else
    
    heatWaveDurMeanHist = [];
    heatWaveDurMaxHist = [];
    heatWaveIntHist = [];
    
    heatWaveDurMeanFut = [];
    heatWaveDurMaxFut = [];
    heatWaveIntFut = [];
    
    for model = 1:length(models)
        load(['2017-nile-climate/output/nile-heat-waves-99-historical-' models{model} '-annual-1980-2004.mat']);
        heatWaveDurMeanHist(:, :, :, model) = heatWaves{1};
        heatWaveDurMaxHist(:, :, :, model) = heatWaves{2};
        heatWaveIntHist(:, :, :, model) = heatWaves{3};
        
        load(['2017-nile-climate/output/nile-heat-waves-99-rcp85-' models{model} '-annual-2056-2080.mat']);
        heatWaveDurMeanFut(:, :, :, model) = heatWaves{1};
        heatWaveDurMaxFut(:, :, :, model) = heatWaves{2};
        heatWaveIntFut(:, :, :, model) = heatWaves{3};
    end
    
    chgInt = squeeze(nanmean(nanmean(nanmean(heatWaveIntFut))))-squeeze(nanmean(nanmean(nanmean(heatWaveIntHist))))
    chgDur = squeeze(nanmean(nanmean(nanmean(heatWaveDurMeanFut))))-squeeze(nanmean(nanmean(nanmean(heatWaveDurMeanHist))))
    
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    
    scatter(chgInt
    
end
