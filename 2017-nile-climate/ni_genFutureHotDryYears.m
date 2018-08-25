models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          %'cmcc-cesm'
%models = {'access1-0', 'access1-3'};
rcp = 'historical';
timePeriod = [2056 2080];
timePeriod = [2075 2099];
timePeriod = [1981 2005];

% 75-99, 50-74, 25-49

reanalysisBase = false;

useGlobal = false;

monthlyShift = false;

% use mean shifts in annual t/p instead of future projected distribution
tshift = 'full';
pshift = 'full';

if reanalysisBase
    load(['2017-nile-climate/output/historical-temp-percentiles-era-interim.mat']);
    load(['2017-nile-climate/output/historical-pr-percentiles-chirps.mat']);
else
    historicalTempThresh = [];
    historicalPrThreshLow = [];
    historicalPrThreshHigh = [];
    pThreshPrcLow = 25;
    pThreshPrcHigh = 75;
    tThreshPrc = 90;
end

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

if useGlobal
    latInds = 1:90;
    lonInds = 1:180;
end

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempFutureCmip5 = [];
prFutureCmip5 = [];

hotFutureEach = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
dryFutureEach = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
wetFutureEach = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));
hotDryFutureEach = zeros(length(latInds), length(lonInds), timePeriod(end)-timePeriod(1)+1, length(models));

hotFuture = zeros(length(latInds), length(lonInds), length(models));
hotFutureSig = zeros(length(latInds), length(lonInds));
dryFuture = zeros(length(latInds), length(lonInds), length(models));
dryFutureSig = zeros(length(latInds), length(lonInds));
wetFuture = zeros(length(latInds), length(lonInds), length(models));
wetFutureSig = zeros(length(latInds), length(lonInds));
hotDryFuture = zeros(length(latInds), length(lonInds), length(models));
hotDryFutureSig = zeros(length(latInds), length(lonInds));

if ~exist('tempHistorical')
    tempHistorical = [];
    prHistorical = [];
end

if ~exist('tempFuture')
    tempFuture = [];
    prFuture = [];
end

for m = 1:length(models)
    if reanalysisBase
        load(['2017-nile-climate/output/projections/temp-monthly-future-era-interim-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curTempFuture = tempFuture;

        load(['2017-nile-climate/output/projections/pr-monthly-future-chirps-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
        curPrFuture = prFuture;
    else
        if size(tempHistorical, 5) ~= length(models)
            fprintf('loading historical %s...\n', models{m});
            curPrHistorical = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1980, 'endYear', 2004);
            curPrHistorical = curPrHistorical{3}(latInds, lonInds, :, :) .* 3600 .* 24;

            curTempHistorical = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
            curTempHistorical = dailyToMonthly(curTempHistorical);
            curTempHistorical = curTempHistorical{3}(latInds, lonInds, :, :);
            if nanmean(nanmean(nanmean(nanmean(curTempHistorical)))) > 100
                curTempHistorical = curTempHistorical - 273.15;
            end

            prHistorical(:, :, :, :, m) = curPrHistorical;
            tempHistorical(:, :, :, :, m) = curTempHistorical;
        end
        
        curPrHistorical = prHistorical(:, :, :, :, m);
        curTempHistorical = tempHistorical(:, :, :, :, m);
        
        for xlat = 1:size(curPrHistorical, 1)
            for ylon = 1:size(curPrHistorical, 2)
                pThreshLow = prctile(reshape(nanmean(curPrHistorical(xlat, ylon, :, :), 4), [numel(nanmean(curPrHistorical(xlat, ylon, :, :), 4)), 1]), pThreshPrcLow);
                pThreshHigh = prctile(reshape(nanmean(curPrHistorical(xlat, ylon, :, :), 4), [numel(nanmean(curPrHistorical(xlat, ylon, :, :), 4)), 1]), pThreshPrcHigh);
                tThresh = prctile(reshape(nanmean(curTempHistorical(xlat, ylon, :, :), 4), [numel(nanmean(curTempHistorical(xlat, ylon, :, :), 4)), 1]), tThreshPrc);

                historicalTempThresh(xlat, ylon) = tThresh;
                historicalPrThreshLow(xlat, ylon) = pThreshLow;
                historicalPrThreshHigh(xlat, ylon) = pThreshHigh;
            end
        end
        
        % not finding historical trends
        if ~strcmp(rcp, 'historical')

            if strcmp(pshift, 'mean')
                if monthlyShift
                    load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chg-cmip5-rcp85-2056-2080-' models{m} '.mat']);
                    curPrFuture = curPrHistorical;
                    for month = 1:12
                        curPrFuture(:, :, :, month) = curPrFuture(:, :, :, month) + repmat(monthlyChg(:, :, month), [1 1 size(curPrFuture, 3)]);
                    end
                    
                    curPrHistorical = nanmean(curPrHistorical, 4);
                    curPrFuture = nanmean(curPrFuture, 4);
                else
                    load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chg-cmip5-rcp85-2056-2080-' models{m} '.mat']);
                    annChg = nanmean(monthlyChg, 3);
                    curPrHistorical = nanmean(curPrHistorical, 4);
                    curPrFuture = curPrHistorical + repmat(annChg, [1 1 size(curPrHistorical, 3)]);
                end
            elseif strcmp(pshift, 'full')
                
                if size(prFuture, 4) ~= length(models)
                    fprintf('loading future %s...\n', models{m});
                    curPrFuture = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/' rcp '/pr/regrid/world'], 'pr', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
                    curPrFuture = nanmean(curPrFuture{3}(latInds, lonInds, :, :) .* 3600 .* 24, 4);
                    prFuture(:, :, :, m) = curPrFuture;
                end
                
                curPrFuture = prFuture(:, :, :, m);
                curPrHistorical = nanmean(curPrHistorical, 4);
            elseif strcmp(pshift, 'none')
                curPrFuture = curPrHistorical;
                
                curPrHistorical = nanmean(curPrHistorical, 4);
                curPrFuture = nanmean(curPrFuture, 4);
            end

            
            if strcmp(tshift, 'mean')
                if monthlyShift
                    load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\tasmax-monthly-chg-cmip5-rcp85-2056-2080-' models{m} '.mat']);
                    curTempFuture = curTempHistorical;
                    for month = 1:12
                        curTempFuture(:, :, :, month) = curTempFuture(:, :, :, month) + repmat(monthlyChg(:, :, month), [1 1 size(curTempFuture, 3)]);
                    end
                    
                    curTempHistorical = nanmean(curTempHistorical, 4);
                    curTempFuture = nanmean(curTempFuture, 4);
                else
                    load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\tasmax-monthly-chg-cmip5-rcp85-2056-2080-' models{m} '.mat']);
                    annChg = nanmean(monthlyChg, 3);
                    curTempHistorical = nanmean(curTempHistorical, 4);
                    curTempFuture = curTempHistorical + repmat(annChg, [1 1 size(curTempHistorical, 3)]);
                end
            elseif strcmp(tshift, 'full')
                if size(tempFuture, 4) ~= length(models)
                    curTempFuture = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/' rcp '/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
                    curTempFuture = dailyToMonthly(curTempFuture);
                    curTempFuture = nanmean(curTempFuture{3}(latInds, lonInds, :, :),4);
                    if nanmean(nanmean(nanmean(nanmean(curTempFuture)))) > 100
                        curTempFuture = curTempFuture - 273.15;
                    end
                    
                    tempFuture(:, :, :, m) = curTempFuture;
                end
                
                curTempHistorical = nanmean(curTempHistorical, 4);
                curTempFuture = tempFuture(:, :, :, m);
            elseif strcmp(tshift, 'none')
                curTempFuture = curTempHistorical;
                
                curTempHistorical = nanmean(curTempHistorical, 4);
                curTempFuture = nanmean(curTempFuture, 4);
            end
        else
            curPrFuture = nanmean(curPrHistorical, 4);
            curTempFuture = nanmean(curTempHistorical, 4);
        end
        
        clear curPrHistorical curTempHistorical;
    end
    
    for year = 1:size(curTempFuture, 3)
        hotFutureEach(:, :, year, m) = (squeeze(curTempFuture(:, :, year)) > squeeze(historicalTempThresh(:, :)));
        dryFutureEach(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPrThreshLow(:, :)));
        wetFutureEach(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) > squeeze(historicalPrThreshHigh(:, :)));
        hotDryFutureEach(:, :, year, m) = (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPrThreshLow(:, :)) & squeeze(curTempFuture(:, :, year)) > squeeze(historicalTempThresh(:, :)));


        hotFuture(:, :, m) = hotFuture(:, :, m) + (squeeze(curTempFuture(:, :, year)) > squeeze(historicalTempThresh(:, :)));
        dryFuture(:, :, m) = dryFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) < squeeze(historicalPrThreshLow(:, :)));
        wetFuture(:, :, m) = wetFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) > squeeze(historicalPrThreshHigh(:, :)));
        hotDryFuture(:, :, m) = hotDryFuture(:, :, m) + (squeeze(curPrFuture(:, :, year)) < historicalPrThreshLow & squeeze(curTempFuture(:, :, year)) > historicalTempThresh);
    end

    % convert to fraction of years
    hotFuture(:, :, m) = hotFuture(:, :, m)  ./ size(curTempFuture, 3);
    dryFuture(:, :, m) = dryFuture(:, :, m)  ./ size(curTempFuture, 3);
    wetFuture(:, :, m) = wetFuture(:, :, m)  ./ size(curTempFuture, 3);
    hotDryFuture(:, :, m) = hotDryFuture(:, :, m)  ./ size(curTempFuture, 3);

    clear curTempFuture curPrFuture;
end

if reanalysisBase
    save(['2017-nile-climate/output/hotFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-era-interim-chirps-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '.mat'], 'hotDryFuture');
else
    
    if strcmp(rcp, 'historical')
        tshift = '';
        pshift = '';
    else
        tshift = ['-t' tshift];
        pshift = ['-p' pshift];
    end
    
    if monthlyShift
        mstr = ['-monthly'];
    else
        mstr = '';
    end
    
    gstr = '';
    if useGlobal
        gstr = '-global';
    end
    
    save(['2017-nile-climate/output/hotFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'hotDryFuture');
    
    hotFuture = hotFutureEach;
    dryFuture = dryFutureEach;
    wetFuture = wetFutureEach;
    hotDryFuture = hotDryFutureEach;
    save(['2017-nile-climate/output/hotFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-each-year-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'hotFuture');
    save(['2017-nile-climate/output/dryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-each-year-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'dryFuture');
    save(['2017-nile-climate/output/wetFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-each-year-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'wetFuture');
    save(['2017-nile-climate/output/hotDryFuture-annual-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-each-year-t' num2str(tThreshPrc) '-p' num2str(pThreshPrcLow) tshift pshift mstr gstr '.mat'], 'hotDryFuture');
end
