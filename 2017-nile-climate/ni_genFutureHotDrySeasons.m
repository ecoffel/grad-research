models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'ipsl-cm5a-mr', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
rcp = 'rcp85';
timePeriod = [2031 2055];

reanalysisBase = false;

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
hotFuture = zeros(length(latInds), length(lonInds), 12, length(models));
hotFutureSig = zeros(length(latInds), length(lonInds), 12);
dryFuture = zeros(length(latInds), length(lonInds), 12, length(models));
dryFutureSig = zeros(length(latInds), length(lonInds), 12);
wetFuture = zeros(length(latInds), length(lonInds), 12, length(models));
wetFutureSig = zeros(length(latInds), length(lonInds), 12);
hotDryFuture = zeros(length(latInds), length(lonInds), 12, length(models));
hotDryFutureSig = zeros(length(latInds), length(lonInds), 12);
for m = 1:length(models)
    if reanalysisBase
        load(['2017-nile-climate/output/projections/temp-monthly-future-era-interim-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curTempFuture = tempFuture;

        load(['2017-nile-climate/output/projections/pr-monthly-future-chirps-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curPrFuture = prFuture;
    else
        fprintf('loading historical %s...\n', models{m});
        curPrHistorical = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1980, 'endYear', 2004);
        curPrHistorical = curPrHistorical{3}(latInds, lonInds, :, :) .* 3600 .* 24;
        
        curTempHistorical = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
        curTempHistorical = dailyToMonthly(curTempHistorical);
        curTempHistorical = curTempHistorical{3}(latInds, lonInds, :, :);
        if nanmean(nanmean(nanmean(nanmean(curTempHistorical)))) > 100
            curTempHistorical = curTempHistorical - 273.15;
        end
        
        for xlat = 1:size(curPrHistorical, 1)
            for ylon = 1:size(curPrHistorical, 2)
                for month = 1:12
                    for p = 1:length(percentiles)
                        pThresh = prctile(reshape(curPrHistorical(xlat, ylon, :, month), [numel(curPrHistorical(xlat, ylon, :, month)), 1]), percentiles(p));
                        tThresh = prctile(reshape(curTempHistorical(xlat, ylon, :, month), [numel(curTempHistorical(xlat, ylon, :, month)), 1]), percentiles(p));

                        historicalTemp(xlat, ylon, month, p) = tThresh;
                        historicalPr(xlat, ylon, month, p) = pThresh;
                    end
                end
            end
        end
        
        clear curPrHistorical curTempHistorical;
        
        fprintf('loading future %s...\n', models{m});
        curPrFuture = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/' rcp '/pr/regrid/world'], 'pr', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        curPrFuture = curPrFuture{3}(latInds, lonInds, :, :) .* 3600 .* 24;
        
        curTempFuture = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        curTempFuture = dailyToMonthly(curTempFuture);
        curTempFuture = curTempFuture{3}(latInds, lonInds, :, :);
        if nanmean(nanmean(nanmean(nanmean(curTempFuture)))) > 100
            curTempFuture = curTempFuture - 273.15;
        end
    end
    
    for month = 1:12
        for year = 1:size(curTempFuture, 3)
            hotFuture(:, :, month, m) = hotFuture(:, :, month, m) + (squeeze(curTempFuture(:, :, year, month)) > squeeze(historicalTemp(:, :, month, 9)));
            dryFuture(:, :, month, m) = dryFuture(:, :, month, m) + (squeeze(curPrFuture(:, :, year, month)) < squeeze(historicalPr(:, :, month, 1)));
            wetFuture(:, :, month, m) = wetFuture(:, :, month, m) + (squeeze(curPrFuture(:, :, year, month)) > squeeze(historicalPr(:, :, month, 9)));
            hotDryFuture(:, :, month, m) = hotDryFuture(:, :, month, m) + (squeeze(curPrFuture(:, :, year, month)) < squeeze(historicalPr(:, :, month, 1)) & squeeze(curTempFuture(:, :, year, month)) > squeeze(historicalTemp(:, :, month, 9)));
        end
        
        % convert to fraction of years
        hotFuture(:, :, month, m) = hotFuture(:, :, month, m)  ./ size(curTempFuture, 3);
        dryFuture(:, :, month, m) = dryFuture(:, :, month, m)  ./ size(curTempFuture, 3);
        wetFuture(:, :, month, m) = wetFuture(:, :, month, m)  ./ size(curTempFuture, 3);
        hotDryFuture(:, :, month, m) = hotDryFuture(:, :, month, m)  ./ size(curTempFuture, 3);
    end
    
    clear curTempFuture curPrFuture;
end

if reanalysisBase
    save(['2017-nile-climate/output/hotFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotDryFuture');
else
    save(['2017-nile-climate/output/hotFuture-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotDryFuture');
end
