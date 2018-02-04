plotSeasonalAnnualData = false;
north = false;
compareCmip5Trends = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

% save historical percentiles for use in future projections?
computeHistoricalDist = false;

coordPairs = csvread('ni-region.txt');

timePeriod = [1981 2016];

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

if ~exist('tmaxEraRaw', 'var')
    fprintf('loading ERA temps...\n');
    tmaxEraRaw = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    tmaxEraRaw{3} = tmaxEraRaw{3} - 273.15;
    % take monthly mean
    tmaxEraRaw = dailyToMonthly(tmaxEraRaw);
end

if ~exist('prEraRaw', 'var')
    fprintf('loading ERA pr...\n');
    prEraRaw = loadDailyData('e:/data/era-interim/output/tp/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    prEraRaw{3} = prEraRaw{3} .* 1000;
    % take monthly mean
    prEraRaw = dailyToMonthly(prEraRaw);
end

if ~exist('tmaxNcepRaw', 'var')
    fprintf('loading NCEP temps...\n');
    tmaxNcepRaw = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    tmaxNcepRaw{3} = tmaxNcepRaw{3} - 273.15;
    % take monthly mean
    tmaxNcepRaw = dailyToMonthly(tmaxNcepRaw);
end

if ~exist('prNcepRaw', 'var')
    fprintf('loading NCEP pr...\n');
    prNcepRaw = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    prNcepRaw{3} = prNcepRaw{3} .* 3600 .* 24;
    % take monthly mean
    prNcepRaw = dailyToMonthly(prNcepRaw);
end

if ~exist('prGpcpRaw', 'var')
    fprintf('loading GPCP pr...\n');
    prGpcpRaw = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    
    latGpcp = prGpcpRaw{1};
    lonGpcp = prGpcpRaw{2};
    [latIndsNorthGpcp, lonIndsNorthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
    [latIndsSouthGpcp, lonIndsSouthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
    [latIndsGpcp, lonIndsGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBounds(1,:), regionBounds(2,:));
end

if ~exist('prGldasRaw', 'var')
    fprintf('loading GLDAS pr...\n');
    prGldasRaw = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
    prGldasRaw{3} = prGldasRaw{3} .* 3600 .* 24;
    
    latGldas = prGldasRaw{1};
    lonGldas = prGldasRaw{2};
    [latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
    [latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
    [latIndsGldas, lonIndsGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBounds(1,:), regionBounds(2,:));
end

if ~exist('tmaxGldasRaw', 'var')
    fprintf('loading GLDAS tmax...\n');
    tmaxGldasRaw = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1981, 'endYear', 2010);
    tmaxGldasRaw{3} = tmaxGldasRaw{3} - 273.15;
end


if ~exist('chirpsRaw', 'var')
    fprintf('loading CHIRPS pr...\n');
    % load regridded chirps
    load('C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-regrid.mat');
    chirpsRaw = prChirps;
%     chirpsRaw = [];
%     
%     % load pre-processed chirps with nile region selected
%     for year = 1981:1:2016
%         fprintf('chirps year %d...\n', year);
%         load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-' num2str(year) '.mat']);
%         chirpsPr{3} = chirpsPr{3};
%         
%         if length(chirpsRaw) == 0
%             chirpsRaw = chirpsPr{3};
%         else
%             chirpsRaw = cat(4, chirpsRaw, chirpsPr{3});
%         end
%         
%         clear chirpsPr;
%     end
%     % flip to (x, y, year, month)
%     chirpsRaw = permute(chirpsRaw, [1 2 4 3]);
%     
%     % load global chirps lat/lon grids
%     load lat-chirps;
%     load lon-chirps;
% 
%     [latIndChirps, lonIndChirps] = latLonIndexRange({latChirps, lonChirps, []}, regionBounds(1,:), regionBounds(2,:));
%     [latIndChirpsNorth, lonIndChirpsNorth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
%     [latIndChirpsSouth, lonIndChirpsSouth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
%     latIndChirpsNorth = latIndChirpsNorth - latIndChirps(1) + 1;
%     lonIndChirpsNorth = lonIndChirpsNorth - lonIndChirps(1) + 1;
%     latIndChirpsSouth = latIndChirpsSouth - latIndChirps(1) + 1;
%     lonIndChirpsSouth = lonIndChirpsSouth - lonIndChirps(1) + 1;
end

if north
    tmaxEra = tmaxEraRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    tmaxNcep = tmaxNcepRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    tmaxGldas = tmaxGldasRaw{3}(latIndsNorthGldas, lonIndsNorthGldas, :, :);

    prEra = prEraRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    prNcep = prNcepRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    prGpcp = prGpcpRaw{3}(latIndsNorthGpcp, lonIndsNorthGpcp, :, :);
    prGldas = prGldasRaw{3}(latIndsNorthGldas, lonIndsNorthGldas, :, :);
    prChirps = chirpsRaw(latIndsNorth-latInds(1)+1, lonIndsNorth-lonInds(1)+1, :, :);
else
    tmaxEra = tmaxEraRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    tmaxNcep = tmaxNcepRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    tmaxGldas = tmaxGldasRaw{3}(latIndsSouthGldas, lonIndsSouthGldas, :, :);

    prEra = prEraRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    prNcep = prNcepRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    prGpcp = prGpcpRaw{3}(latIndsSouthGpcp, lonIndsSouthGpcp, :, :);
    prGldas = prGldasRaw{3}(latIndsSouthGldas, lonIndsSouthGldas, :, :);
    prChirps = chirpsRaw(latIndsSouth-latInds(1)+1, lonIndsSouth-lonInds(1)+1, :, :);
end

numYears = (timePeriod(end)-timePeriod(1)+1);

load wettest-season-ncep;
wettestSeasonNorth = mode(reshape(wettestSeason(latIndsNorth, lonIndsNorth), [numel(wettestSeason(latIndsNorth, lonIndsNorth)), 1]));
wettestSeasonSouth = mode(reshape(wettestSeason(latIndsSouth, lonIndsSouth), [numel(wettestSeason(latIndsSouth, lonIndsSouth)), 1]));

load('hottest-season-ncep.mat');
hottestSeasonNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSeasonSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

prcTmax = 90;
prcPr = 10;

hotTrends = zeros(4, 3);
hotCI = zeros(4, 3, 2);
hotSig = zeros(4, 3);
hotTrendsCmip5 = zeros(4, length(models));
dryTrends = zeros(4, 5);
dryCI = zeros(4, 5, 2);
drySig = zeros(4, 5);
dryTrendsCmip5 = zeros(4, length(models));
hotDryTrends = zeros(4, 3);
hotDryCI = zeros(4, 3, 2);
hotDrySig = zeros(4, 3);
hotDryTrendsCmip5 = zeros(4, length(models));

if computeHistoricalDist
    % compute historical percentiles in tmax/pr for each month
    historicalTemp = [];
    historicalPr = [];
    percentiles = 10:10:90;
    for p = 1:length(percentiles)
        for month = 1:12
            % compute percentile for current month
            historicalTemp(:, :, month, p) = prctile(squeeze(tmaxEraRaw{3}(latInds, lonInds, :, month)), percentiles(p), 3);
            historicalPr(:, :, month, p) = prctile(squeeze(prEraRaw{3}(latInds, lonInds, :, month)), percentiles(p), 3);
        end
    end
    
    save(['2017-nile-climate/output/historical-temp-percentiles-era-interim.mat'], 'historicalTemp');
    save(['2017-nile-climate/output/historical-pr-percentiles-era-interim.mat'], 'historicalPr');
    
    % for NCEP
    historicalTemp = [];
    historicalPr = [];
    percentiles = 10:10:90;
    for p = 1:length(percentiles)
        for month = 1:12
            % compute percentile for current month
            historicalTemp(:, :, month, p) = prctile(squeeze(tmaxNcepRaw{3}(latInds, lonInds, :, month)), percentiles(p), 3);
            historicalPr(:, :, month, p) = prctile(squeeze(prNcepRaw{3}(latInds, lonInds, :, month)), percentiles(p), 3);
        end
    end
    
    save(['2017-nile-climate/output/historical-temp-percentiles-ncep-reanalysis.mat'], 'historicalTemp');
    save(['2017-nile-climate/output/historical-pr-percentiles-ncep-reanalysis.mat'], 'historicalPr');
    
    % and for GLDAS
    historicalTemp = [];
    historicalPr = [];
    percentiles = 10:10:90;
    for p = 1:length(percentiles)
        for month = 1:12
            % compute percentile for current month
            historicalTemp(:, :, month, p) = prctile(squeeze(tmaxGldasRaw{3}(latIndsGldas, lonIndsGldas, :, month)), percentiles(p), 3);
            historicalPr(:, :, month, p) = prctile(squeeze(prGldasRaw{3}(latIndsGldas, lonIndsGldas, :, month)), percentiles(p), 3);
        end
    end
    
    save(['2017-nile-climate/output/historical-temp-percentiles-gldas.mat'], 'historicalTemp');
    save(['2017-nile-climate/output/historical-pr-percentiles-gldas.mat'], 'historicalPr');
    
    
    % and for CHIRPS
    historicalPr = [];
    percentiles = 10:10:90;
    for p = 1:length(percentiles)
        for month = 1:12
            % compute percentile for current month
            historicalPr(:, :, month, p) = prctile(squeeze(chirpsRaw(:, :, :, month)), percentiles(p), 3);
        end
    end
    
    save(['2017-nile-climate/output/historical-pr-percentiles-chirps.mat'], 'historicalPr');
end


figure('Color', [1,1,1]);
colors = get(gca, 'colororder');
i = 1;
for s = 1:size(seasons, 1)
    % timeseries of current season tmax/tmin
    curTmaxEra = nanmean(tmaxEra(:, :, :, seasons(s, :)), 4);
    curPrEra = nanmean(prEra(:, :, :, seasons(s, :)), 4);
    curTmaxNcep = nanmean(tmaxNcep(:, :, :, seasons(s, :)), 4);
    curPrNcep = nanmean(prNcep(:, :, :, seasons(s, :)), 4);
    curPrGpcp = nanmean(prGpcp(:, :, :, seasons(s, :)), 4);
    curPrChirps = nanmean(prChirps(:, :, :, seasons(s, :)), 4);
    curPrGldas = nanmean(prGldas(:, :, :, seasons(s, :)), 4);
    curTmaxGldas = nanmean(tmaxGldas(:, :, :, seasons(s, :)), 4);
    
    % get seasonal means over time series...
    curTmaxThreshEra = prctile(curTmaxEra, prcTmax, 3);
    curPrThreshEra = prctile(curPrEra, prcPr, 3);
    
    curTmaxThreshNcep = prctile(curTmaxNcep, prcTmax, 3);
    curPrThreshNcep = prctile(curPrNcep, prcPr, 3);
    
    curPrThreshGpcp = prctile(curPrGpcp, prcPr, 3);
    curPrThreshChirps = prctile(curPrChirps, prcPr, 3);
    curPrThreshGldas = prctile(curPrGldas, prcPr, 3);
    curTmaxThreshGldas = prctile(curTmaxGldas, prcTmax, 3);
    
    for year = 1:size(curTmaxEra, 3)
        hotEra(year) = numel(find(curTmaxEra(:, :, year) > curTmaxThreshEra));
        dryEra(year) = numel(find(curPrEra(:, :, year) < curPrThreshEra));
        hotdryEra(year) = numel(find(curTmaxEra(:, :, year) > curTmaxThreshEra & curPrEra(:, :, year) < curPrThreshEra));
        
        hotNcep(year) = numel(find(curTmaxNcep(:, :, year) > curTmaxThreshNcep));
        dryNcep(year) = numel(find(curPrNcep(:, :, year) < curPrThreshNcep));
        hotdryNcep(year) = numel(find(curTmaxNcep(:, :, year) > curTmaxThreshNcep & curPrNcep(:, :, year) < curPrThreshNcep));
        
        dryGpcp(year) = numel(find(curPrGpcp(:, :, year) < curPrThreshGpcp));
        dryChirps(year) = numel(find(curPrChirps(:, :, year) < curPrThreshChirps));
        if year <= size(curPrGldas, 3)
            dryGldas(year) = numel(find(curPrGldas(:, :, year) < curPrThreshGldas));
            hotGldas(year) = numel(find(curTmaxGldas(:, :, year) > curTmaxThreshGldas));
            hotdryGldas(year) = numel(find(curTmaxGldas(:, :, year) > curTmaxThreshGldas & curPrGldas(:, :, year) < curPrThreshGldas));
        end
        
        % using chirps pr & era temp
        hotdryEraChirps(year) = numel(find(curTmaxEra(:, :, year) > curTmaxThreshEra & curPrChirps(:, :, year) < curPrThreshChirps));
    end
    
    % load pre-processed cmip5 hot/dry counts
    load(['2017-nile-climate/output/hotDryFuture-cmip5-historical-1980-2004-each-year']);
    hotDryCmip5 = hotDryFuture;
    load(['2017-nile-climate/output/dryFuture-cmip5-historical-1980-2004-each-year']);
    dryCmip5 = dryFuture;
    load(['2017-nile-climate/output/hotFuture-cmip5-historical-1980-2004-each-year']);
    hotCmip5 = hotFuture;
    
    % average over area & season
    if north
        hotDryCmip5 = squeeze(nansum(nansum(nanmean(hotDryCmip5(latIndsNorth - latInds(1) + 1, lonIndsNorth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
        dryCmip5 = squeeze(nansum(nansum(nanmean(dryCmip5(latIndsNorth - latInds(1) + 1, lonIndsNorth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
        hotCmip5 = squeeze(nansum(nansum(nanmean(hotCmip5(latIndsNorth - latInds(1) + 1, lonIndsNorth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
    else
        hotDryCmip5 = squeeze(nansum(nansum(nanmean(hotDryCmip5(latIndsSouth - latInds(1) + 1, lonIndsSouth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
        dryCmip5 = squeeze(nansum(nansum(nanmean(dryCmip5(latIndsSouth - latInds(1) + 1, lonIndsSouth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
        hotCmip5 = squeeze(nansum(nansum(nanmean(hotCmip5(latIndsSouth - latInds(1) + 1, lonIndsSouth - lonInds(1) + 1, :, seasons(s, :), :), 4), 2), 1));
    end
    
    % normalize all counts to account for different grids
    dryCmip5 = normr(dryCmip5');
    hotCmip5 = normr(hotCmip5');
    hotDryCmip5 = normr(hotDryCmip5');
    dryEra = normr(dryEra);
    dryNcep = normr(dryNcep);
    dryGpcp = normr(dryGpcp);
    dryGldas = normr(dryGldas);
    dryChirps = normr(dryChirps);
    hotEra = normr(hotEra);
    hotNcep = normr(hotNcep);
    hotGldas = normr(hotGldas);
    hotdryEra = normr(hotdryEra);
    hotdryNcep = normr(hotdryNcep);
    hotdryGldas = normr(hotdryGldas);
    hotdryEraChirps = normr(hotdryEraChirps);
    
    % compute trends for datasets
    fHotEra = fit((1:length(hotEra))', hotEra', 'poly1');
    fHotNcep = fit((1:length(hotNcep))', hotNcep', 'poly1');
    fHotGldas = fit((1:length(hotGldas))', hotGldas', 'poly1');
    
    hotTrends(s, 1) = fHotEra.p1;
    hotTrends(s, 2) = fHotNcep.p1;
    hotTrends(s, 3) = fHotGldas.p1;
    
    for m = 1:size(hotCmip5, 1)
        f = fit((1:size(hotCmip5, 2))', (squeeze(hotCmip5(m, :)))', 'poly1');
        hotTrendsCmip5(s, m) = f.p1;
        
        f = fit((1:size(dryCmip5, 2))', (squeeze(dryCmip5(m, :)))', 'poly1');
        dryTrendsCmip5(s, m) = f.p1;
        
        f = fit((1:size(hotDryCmip5, 2))', (squeeze(hotDryCmip5(m, :)))', 'poly1');
        hotDryTrendsCmip5(s, m) = f.p1;
    end
    
    % and get CI
    c = confint(fHotEra);
    hotCI(s, 1, :) = c(:,1);
    c = confint(fHotNcep);
    hotCI(s, 2, :) = c(:,1);
    c = confint(fHotGldas);
    hotCI(s, 3, :) = c(:,1);
    
    hotSig(s, 1) = Mann_Kendall(hotEra, .05);
    hotSig(s, 2) = Mann_Kendall(hotNcep, .05);
    hotSig(s, 3) = Mann_Kendall(hotGldas, .05);
    
    fDryEra = fit((1:length(dryEra))', dryEra', 'poly1');
    fDryNcep = fit((1:length(dryNcep))', dryNcep', 'poly1');
    fDryGldas = fit((1:length(dryGldas))', dryGldas', 'poly1');
    fDryGpcp = fit((1:length(dryGpcp))', dryGpcp', 'poly1');
    fDryChirps = fit((1:length(dryChirps))', dryChirps', 'poly1');
    
    dryTrends(s, 1) = fDryEra.p1;
    dryTrends(s, 2) = fDryNcep.p1;
    dryTrends(s, 3) = fDryGldas.p1;
    dryTrends(s, 4) = fDryGpcp.p1;
    dryTrends(s, 5) = fDryChirps.p1;
    
    c = confint(fDryEra);
    dryCI(s, 1, :) = c(:,1);
    c = confint(fDryNcep);
    dryCI(s, 2, :) = c(:,1);
    c = confint(fDryGldas);
    dryCI(s, 3, :) = c(:,1);
    c = confint(fDryGpcp);
    dryCI(s, 4, :) = c(:,1);
    c = confint(fDryChirps);
    dryCI(s, 5, :) = c(:,1);
    
    drySig(s, 1) = Mann_Kendall(dryEra, .05);
    drySig(s, 2) = Mann_Kendall(dryNcep, .05);
    drySig(s, 3) = Mann_Kendall(dryGldas, .05);
    drySig(s, 4) = Mann_Kendall(dryGpcp, .05);
    drySig(s, 5) = Mann_Kendall(dryChirps, .05);
    
    fHotDryEra = fit((1:length(hotdryEra))', hotdryEra', 'poly1');
    fHotDryNcep = fit((1:length(hotdryNcep))', hotdryNcep', 'poly1');
    fHotDryGldas = fit((1:length(hotdryGldas))', hotdryGldas', 'poly1');
    fHotDryEraChirps = fit((1:length(hotdryEraChirps))', hotdryEraChirps', 'poly1');
    
    hotDryTrends(s, 1) = fHotDryEra.p1;
    hotDryTrends(s, 2) = fHotDryNcep.p1;
    hotDryTrends(s, 3) = fHotDryGldas.p1;
    hotDryTrends(s, 4) = fHotDryEraChirps.p1;
    
    c = confint(fHotDryEra);
    hotDryCI(s, 1, :) = c(:,1);
    c = confint(fHotDryNcep);
    hotDryCI(s, 2, :) = c(:,1);
    c = confint(fHotDryGldas);
    hotDryCI(s, 3, :) = c(:,1);
    c = confint(fHotDryEraChirps);
    hotDryCI(s, 4, :) = c(:,1);
    
    hotDrySig(s, 1) = Mann_Kendall(hotdryEra, .05);
    hotDrySig(s, 2) = Mann_Kendall(hotdryNcep, .05);
    hotDrySig(s, 3) = Mann_Kendall(hotdryGldas, .05);
    hotDrySig(s, 4) = Mann_Kendall(hotdryEraChirps, .05);
    
    if plotSeasonalAnnualData
        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        ylim([0 125]);
        p1 = plot(hotEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(hotEra, 0.05)
            plot(1:length(hotEra), fHotEra(1:length(hotEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(hotNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(hotNcep, 0.05)
            plot(1:length(hotNcep), fHotNcep(1:length(hotNcep)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        p3 = plot(hotGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(hotGldas, 0.05)
            plot(1:length(hotGldas), fHotGldas(1:length(hotGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        set(gca, 'XTick', 6:10:length(hotEra), 'XTickLabels', [1985 1995 2005 2015]);
        ylim([0 1]);
        ylabel([seasonNames{s} ' hot seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'northwest');
        if north
            export_fig(['hot-season-' num2str(s) '-north.eps']);
        else
            export_fig(['hot-season-' num2str(s) '-south.eps']);
        end
        close all;

        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        p1 = plot(dryEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(dryEra, 0.05)            
            plot(1:length(dryEra), fDryEra(1:length(dryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(dryNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(dryNcep, 0.05)
            plot(1:length(dryNcep), fDryNcep(1:length(dryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
        end
        p3 = plot(dryGpcp, 'Color', colors(4,:), 'LineWidth', 2);
        if Mann_Kendall(dryGpcp, 0.05)
            plot(1:length(dryGpcp), fDryGpcp(1:length(dryGpcp)), '--', 'Color', colors(4,:), 'LineWidth', 2);
        end
        p4 = plot(dryGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(dryGldas, 0.05)
            plot(1:length(dryGldas), fDryGldas(1:length(dryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        p5 = plot(dryChirps, 'Color', colors(5,:), 'LineWidth', 2);
        if Mann_Kendall(dryChirps, 0.05)
            plot(1:length(dryChirps), fDryGldas(1:length(dryChirps)), '--', 'Color', colors(5,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        ylabel([seasonNames{s} ' dry seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3 p4 p5], {'ERA-Interim', 'NCEP II', 'GPCP', 'GLDAS', 'CHIRPS-v2'}, 'location', 'northwest');
        ylim([0 1]);
        set(gca, 'XTick', 6:10:length(dryEra), 'XTickLabels', [1985 1995 2005 2015]);
        if north
            export_fig(['dry-season-' num2str(s) '-north.eps']);
        else
            export_fig(['dry-season-' num2str(s) '-south.eps']);
        end
        close all;

        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        ylim([0 125]);
        p1 = plot(hotdryEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryEra, 0.05)
            plot(1:length(hotdryEra), fHotDryEra(1:length(hotdryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(hotdryNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryNcep, 0.05)
            plot(1:length(hotdryNcep), fHotDryNcep(1:length(hotdryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
        end
        p3 = plot(hotdryGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryGldas, 0.05)
            plot(1:length(hotdryGldas), fHotDryGldas(1:length(hotdryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        p4 = plot(hotdryEraChirps, 'Color', colors(5,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryEraChirps, 0.05)
            plot(1:length(hotdryEraChirps), fHotDryEraChirps(1:length(hotdryEraChirps)), '--', 'Color', colors(5,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        set(gca, 'XTick', 6:10:length(hotdryEra), 'XTickLabels', [1985 1995 2005 2015]);
        ylim([0 1]);
        ylabel([seasonNames{s} ' hot & dry seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS', 'CHIRPS-ERA'}, 'location', 'northwest');
        if north
            export_fig(['hotdry-season-' num2str(s) '-north.eps']);
        else
            export_fig(['hotdry-season-' num2str(s) '-south.eps']);
        end
        close all;
    end
end

dryTrends = dryTrends .* 10;
hotTrends = hotTrends .* 10;
hotDryTrends = hotDryTrends .* 10;

hotTrendsCmip5 = hotTrendsCmip5 .* 10;
dryTrendsCmip5 = dryTrendsCmip5 .* 10;
hotDryTrendsCmip5 = hotDryTrendsCmip5 .* 10;

if compareCmip5Trends
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;
    
    pdt = plot([nanmean(nanmean(hotTrends)) nanmean(nanmean(hotTrends))], [-1 1], '-', 'Color', [247, 92, 81]./255.0, 'LineWidth', 2);
    pdd = plot([-1 1], [nanmean(nanmean(dryTrends)) nanmean(nanmean(dryTrends))], '-', 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    
    for m = 1:size(hotTrendsCmip5, 2)
        t = text(nanmean(hotTrendsCmip5(:,m),1), nanmean(dryTrendsCmip5(:,m),1), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
        t.FontSize = 18;
    end
    
    dt = (squeeze(nanmean(hotTrendsCmip5,1)))';
    dd = (squeeze(nanmean(dryTrendsCmip5,1)))';
    f = fit(dt, dd, 'poly1');
    cint = confint(f);
    if sign(cint(1,1)) == sign(cint(2,1))
        plot([min(dt) max(dt)], [f(min(dt)) f(max(dt))], '--b', 'LineWidth', 2);
    end
    
    xlim([-.1 .15]);
    set(gca, 'XTick', [-.1:.05:.15]);
    xlabel('Hot season trend')
    ylim([-.1 .1]);
    set(gca, 'YTick', [-.1:.05:.1]);
    ylabel('Dry season trend');
    set(gca, 'FontSize', 36);
    %legend([pdt pdd], {'Obs hot season trend', 'Obs dry season trend'});
    
    set(gcf, 'Position', get(0,'Screensize'));
    if north
        export_fig trend-comparison-north.eps;
    else
        export_fig trend-comparison-south.eps;
    end
end



figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.2 -.1 0 .1 .2];
for d = 1:size(dryTrends, 2)
    for s = 1:size(dryTrends, 1)
        e = errorbar(s+displace(d), dryTrends(s, d), dryTrends(s,d)-dryCI(s,d,1), dryCI(s,d,2)-dryTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), dryTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if drySig(s, d)
            plot(s+displace(d), dryTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end

b = boxplot([dryTrendsCmip5(1,:)' dryTrendsCmip5(2,:)' dryTrendsCmip5(3,:)' dryTrendsCmip5(4,:)'], ...
                     'positions', [1.35 2.35 3.35 4.35], 'widths', [.1 .1 .1 .1]);

set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
                
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{wettestSeasonNorth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonNorth}];
else
    ax.XTickLabels{wettestSeasonSouth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonSouth}];
end

ylabel('Dry season trend');
l = legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'GPCP', 'CHIRPS-v2'}, 'location', 'southwest');
set(l, 'FontSize', 30);
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig dry-trends-north.eps;
else
    export_fig dry-trends-south.eps;
end
close all;





figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.1 0 .1];
for d = 1:size(hotTrends, 2)
    for s = 1:size(hotTrends, 1)
        e = errorbar(s+displace(d), hotTrends(s, d), hotTrends(s,d)-hotCI(s,d,1), hotCI(s,d,2)-hotTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), hotTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if hotSig(s, d)
            plot(s+displace(d), hotTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end

b = boxplot([hotTrendsCmip5(1,:)' hotTrendsCmip5(2,:)' hotTrendsCmip5(3,:)' hotTrendsCmip5(4,:)'], ...
                     'positions', [1.25 2.25 3.25 4.25], 'widths', [.1 .1 .1 .1]);

set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{hottestSeasonNorth} = ['\color{red} ' ax.XTickLabels{hottestSeasonNorth}];
else
    ax.XTickLabels{hottestSeasonSouth} = ['\color{red} ' ax.XTickLabels{hottestSeasonSouth}];
end

ylabel('Hot season trend');
l = legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'southeast');
set(l, 'FontSize', 30);
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig hot-trends-north.eps;
else
    export_fig hot-trends-south.eps;
end
close all;




figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.15 -.05 .05 .15];
for d = 1:size(hotDryTrends, 2)
    for s = 1:size(hotDryTrends, 1)
        e = errorbar(s+displace(d), hotDryTrends(s, d), hotDryTrends(s,d)-hotDryCI(s,d,1), hotDryCI(s,d,2)-hotDryTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), hotDryTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if hotDrySig(s, d)
            plot(s+displace(d), hotDryTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end

b = boxplot([hotDryTrendsCmip5(1,:)' hotDryTrendsCmip5(2,:)' hotDryTrendsCmip5(3,:)' hotDryTrendsCmip5(4,:)'], ...
                     'positions', [1.3 2.3 3.3 4.3], 'widths', [.1 .1 .1 .1]);

set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{hottestSeasonNorth} = ['\color{red} ' ax.XTickLabels{hottestSeasonNorth}];
else
    ax.XTickLabels{hottestSeasonSouth} = ['\color{red} ' ax.XTickLabels{hottestSeasonSouth}];
end

ylabel('Hot & dry season trend');
l = legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'CHIRPS-ERA'}, 'location', 'southeast');
set(l, 'FontSize', 30);
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig hot-dry-trends-north.eps;
else
    export_fig hot-dry-trends-south.eps;
end
close all;