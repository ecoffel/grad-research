dataset = 'cmip5';

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
        rcp = 'rcp85';
        timePeriod = [2056 2080];
    case 'era-interim'
        fprintf('loading ERA...\n');
        models = {''};
        pr = loadDailyData(['E:\data\' dataset '\output\tp\regrid\world'], 'startYear', 1981, 'endYear', 2016);
        pr{3} = pr{3} .* 1000;
        pr = dailyToMonthly(pr);
    case 'ncep-reanalysis'
        fprintf('loading NCEP...\n');
        models = {''};
        pr = loadDailyData(['E:\data\' dataset '\output\prate\regrid\world'], 'startYear', 1981, 'endYear', 2016);
        pr{3} = pr{3} .* 3600 .* 24;
        pr = dailyToMonthly(pr);
    case 'gldas'
        fprintf('loading GLDAS...\n');
        models = {''};
        pr = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
        pr{3} = pr{3} .* 3600 .* 24;
    case 'chirps'
        fprintf('loading CHIRPS...\n');
        models = {''};
        load('C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-regrid.mat');
        pr = prChirps;
end

plotMap = false;

% regionBoundsNorth = [[13 32]; [29, 34]];
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

for model = 1:length(models)
    prSeasonal = {};

    if strcmp(dataset, 'cmip5')
        if exist(['2017-nile-climate/output/pr-seasonal-' dataset '-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{model} '.mat'])
            continue;
        end
        fprintf('loading %s...\n', models{model});
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{model} '\mon\r1i1p1\' rcp '\pr\regrid\world'], 'pr', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        pr{3} = pr{3} .* 3600 .* 24;
        pr = dailyToMonthly(pr);
    end
    
    if strcmp(dataset, 'chirps')
        load lat;
        load lon;
        data = pr;
    else
        lat = pr{1};
        lon = pr{2};
        data = pr{3};
    end
    
    % whole nile region
    regionBounds = [[2 32]; [25, 44]];
    [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
    
    for season = 1:size(seasons, 1)
        if strcmp(dataset, 'chirps')
            regionP = squeeze(nanmean(data(:, :, :, seasons(season, :)), 4));
        else
            regionP = squeeze(nanmean(data(latInds, lonInds, :, seasons(season, :)), 4));
        end
        prSeasonal{season} = regionP;
    end
    
    if strcmp(dataset, 'cmip5')
        save(['2017-nile-climate/output/pr-seasonal-' dataset '-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{model} '.mat'], 'prSeasonal');
    else
        save(['2017-nile-climate/output/pr-seasonal-' dataset '.mat'], 'prSeasonal');
    end
    clear pr data prSeasonal;
end
