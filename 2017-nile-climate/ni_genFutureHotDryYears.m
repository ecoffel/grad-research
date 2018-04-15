models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
rcp = 'historical';
timePeriod = [1980 2004];

reanalysisBase = false;

% should we save each year's grid separately
eachYear = false;

if reanalysisBase
    load(['2017-nile-climate/output/historical-temp-percentiles-era-interim.mat']);
    load(['2017-nile-climate/output/historical-pr-percentiles-chirps.mat']);
else
    historicalTemp = [];
    historicalPr = [];
    percentiles = 10:10:90;
end

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempFutureCmip5 = [];
prFutureCmip5 = [];
if eachYear
    hotFuture = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
    hotFutureSig = zeros(length(latInds), length(lonInds));
    dryFuture = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
    dryFutureSig = zeros(length(latInds), length(lonInds));
    wetFuture = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
    wetFutureSig = zeros(length(latInds), length(lonInds));
    hotDryFuture = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
    hotDryFutureSig = zeros(length(latInds), length(lonInds));
else
    hotFuture = zeros(length(latInds), length(lonInds), length(models));
    hotFutureSig = zeros(length(latInds), length(lonInds));
    dryFuture = zeros(length(latInds), length(lonInds), length(models));
    dryFutureSig = zeros(length(latInds), length(lonInds));
    wetFuture = zeros(length(latInds), length(lonInds), length(models));
    wetFutureSig = zeros(length(latInds), length(lonInds));
    hotDryFuture = zeros(length(latInds), length(lonInds), length(models));
    hotDryFutureSig = zeros(length(latInds), length(lonInds));
end

for m = 1:length(models)
    if reanalysisBase
        load(['2017-nile-climate/output/projections/temp-monthly-future-era-interim-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curTempFuture = tempFuture;

        load(['2017-nile-climate/output/projections/pr-monthly-future-chirps-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curPrFuture = prFuture;
    else
        fprintf('loading historical %s...\n', models{m});
        curPrHistorical = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1980, 'endYear', 2004);
        curPrHistorical = nanmean(curPrHistorical{3}(latInds, lonInds, :, :) .* 3600 .* 24, 4);
        
        curTempHistorical = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
        curTempHistorical = dailyToMonthly(curTempHistorical);
        curTempHistorical = nanmean(curTempHistorical{3}(latInds, lonInds, :, :), 4);
        if nanmean(nanmean(nanmean(nanmean(curTempHistorical)))) > 100
            curTempHistorical = curTempHistorical - 273.15;
        end
        
        for xlat = 1:size(curPrHistorical, 1)
            for ylon = 1:size(curPrHistorical, 2)
                for p = 1:length(percentiles)
                    pThresh = prctile(reshape(curPrHistorical(xlat, ylon, :), [numel(curPrHistorical(xlat, ylon, :)), 1]), percentiles(p));
                    tThresh = prctile(reshape(curTempHistorical(xlat, ylon, :), [numel(curTempHistorical(xlat, ylon, :)), 1]), percentiles(p));

                    historicalTemp(xlat, ylon, p) = tThresh;
                    historicalPr(xlat, ylon, p) = pThresh;
                end
            end
        end
        
        % not finding historical trends
        if ~strcmp(rcp, 'historical')

            fprintf('loading future %s...\n', models{m});
            curPrFuture = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/' rcp '/pr/regrid/world'], 'pr', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
            curPrFuture = nanmean(curPrFuture{3}(latInds, lonInds, :, :) .* 3600 .* 24, 4);

            curTempFuture = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
            curTempFuture = dailyToMonthly(curTempFuture);
            curTempFuture = nanmean(curTempFuture{3}(latInds, lonInds, :, :),4);
            if nanmean(nanmean(nanmean(nanmean(curTempFuture)))) > 100
                curTempFuture = curTempFuture - 273.15;
            end
        else
            curPrFuture = curPrHistorical;
            curTempFuture = curTempHistorical;
        end
        
        clear curPrHistorical curTempHistorical;
    end
    
    for year = 1:size(curTempFuture, 3)
        if eachYear
            hotFuture(:, :, year, m) = (squeeze(curTempFuture(:, :, year)) > squeeze(historicalTemp(:, :, 9)));
            dryFuture(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPr(:, :, 1)));
            wetFuture(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) > squeeze(historicalPr(:, :, 9)));
            hotDryFuture(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPr(:, :, 1)) & squeeze(curTempFuture(:, :, year)) > squeeze(historicalTemp(:, :, 9)));
        else
            hotFuture(:, :, m) = hotFuture(:, :, m) + (squeeze(curTempFuture(:, :, year)) > squeeze(historicalTemp(:, :, 9)));
            dryFuture(:, :, m) = dryFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPr(:, :, 1)));
            wetFuture(:, :, m) = wetFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) > squeeze(historicalPr(:, :, 9)));
            hotDryFuture(:, :, m) = hotDryFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPr(:, :, 1)) & squeeze(curTempFuture(:, :, year)) > squeeze(historicalTemp(:, :, 9)));
        end
    end

    if ~eachYear
        % convert to fraction of years
        hotFuture(:, :, m) = hotFuture(:, :, m)  ./ size(curTempFuture, 3);
        dryFuture(:, :, m) = dryFuture(:, :, m)  ./ size(curTempFuture, 3);
        wetFuture(:, :, m) = wetFuture(:, :, m)  ./ size(curTempFuture, 3);
        hotDryFuture(:, :, m) = hotDryFuture(:, :, m)  ./ size(curTempFuture, 3);
    end

    clear curTempFuture curPrFuture;
end

if reanalysisBase
    save(['2017-nile-climate/output/hotFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotDryFuture');
else
    eachYearStr = '';
    if eachYear
        eachYearStr = '-each-year';
    end
    
    save(['2017-nile-climate/output/hotFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) eachYearStr '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) eachYearStr '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) eachYearStr '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) eachYearStr '.mat'], 'hotDryFuture');
end
