dataset = 'cmip5';
var = 'pr';

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
    case 'era-interim'
        fprintf('loading ERA...\n');
        models = {''};
        pr = loadDailyData(['E:\data\' dataset '\output\' var '\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        pr{3} = pr{3} .* 1000;
        pr = dailyToMonthly(pr);
    case 'ncep-reanalysis'
        fprintf('loading NCEP...\n');
        models = {''};
        pr = loadDailyData(['E:\data\' dataset '\output\' var '\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        pr{3} = pr{3} .* 3600 .* 24;
        pr = dailyToMonthly(pr);
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
        fprintf('loading %s...\n', models{model});
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{model} '\mon\r1i1p1\historical\pr\regrid\world'], 'pr', 'startYear', 1980, 'endYear', 2004);
        pr{3} = pr{3} .* 3600 .* 24;
        pr = dailyToMonthly(pr);
    end
    
    lat = pr{1};
    lon = pr{2};
    data = pr{3};
    
    % whole nile region
    regionBounds = [[2 32]; [25, 44]];
    [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
    
    for season = 1:size(seasons, 1)
        regionP = squeeze(nanmean(data(latInds, lonInds, :, seasons(season, :)), 4));
        prSeasonal{season} = regionP;
    end
    
    if strcmp(dataset, 'cmip5')
        save(['2017-nile-climate/output/pr-' dataset '-historical-' models{model} '.mat'], 'prSeasonal');
    else
        save(['2017-nile-climate/output/pr-' dataset '.mat'], 'prSeasonal');
    end
    clear pr data prSeasonal;
end