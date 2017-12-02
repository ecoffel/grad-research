dataset = 'ncep-reanalysis';

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
    case 'era-interim'
        models = {''};
        fprintf('loading ERA pr...\n');
        pr = loadDailyData(['E:\data\' dataset '\output\tp\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        fprintf('loading ERA slhf...\n');
        et = loadDailyData(['E:\data\' dataset '\output\slhf\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        pr{3} = pr{3} .* 1000;
        et{3} = et{3} .* 3600 .*24 ./ 2.45e6;
        pr = dailyToMonthly(pr);
        et = dailyToMonthly(et);
        pe = pr{3} - et{3};
    case 'ncep-reanalysis'
        models = {''};
        fprintf('loading NCEP pr...\n');
        pr = loadDailyData(['E:\data\' dataset '\output\prate\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        fprintf('loading NCEP lhtfl...\n');
        et = loadDailyData(['E:\data\' dataset '\output\lhtfl\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        pr{3} = pr{3} .* 3600 .* 24;
        et{3} = et{3} .* 3600 .* 24 ./ 2.45e6;
        pr = dailyToMonthly(pr);
        et = dailyToMonthly(et);
        pe = pr{3} - et{3};
end

plotMap = false;

% regionBoundsNorth = [[13 32]; [29, 34]];
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

load lat;
load lon;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

for model = 1:length(models)
    peSeasonal = {};

    if strcmp(dataset, 'cmip5')
        fprintf('loading %s...\n', models{model});
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{model} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1980, 'endYear', 2004);
        pr{3} = pr{3} .* 3600 .* 24;
        pr = dailyToMonthly(pr);
    end
    
    % whole nile region
    regionBounds = [[2 32]; [25, 44]];
    [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
    
    for season = 1:size(seasons, 1)
        regionPE = squeeze(nanmean(pe(latInds, lonInds, :, seasons(season, :)), 4));
        peSeasonal{season} = regionPE;
    end
    
    if strcmp(dataset, 'cmip5')
        save(['2017-nile-climate/output/pe-' dataset '-historical-' models{model} '.mat'], 'peSeasonal');
    else
        save(['2017-nile-climate/output/pe-' dataset '.mat'], 'peSeasonal');
    end
    clear pe et pr peSeasonal;
end
