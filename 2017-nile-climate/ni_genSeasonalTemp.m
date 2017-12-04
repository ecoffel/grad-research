dataset = 'cmip5';

switch (dataset)
    case 'cmip5'
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                      'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
        timePeriod = [1980 2004];
        rcp = 'historical';
    case 'era-interim'
        fprintf('loading ERA...\n');
        models = {''};
        tmax = loadDailyData(['E:\data\' dataset '\output\mx2t\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        tmax{3} = tmax{3} - 273.15;
        tmax = dailyToMonthly(tmax);
    case 'ncep-reanalysis'
        fprintf('loading NCEP...\n');
        models = {''};
        tmax = loadDailyData(['E:\data\' dataset '\output\tmax\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        tmax{3} = tmax{3} - 273.15;
        tmax = dailyToMonthly(tmax);
    case 'gldas'
        fprintf('loading GLDAS...\n');
        models = {''};
        tmax = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1980, 'endYear', 2010);
        tmax{3} = tmax{3} - 273.15;
end

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

for model = 1:length(models)
    tempSeasonal = {};

    if strcmp(dataset, 'cmip5')
        fprintf('loading %s...\n', models{model});
        tmax = loadDailyData(['E:\data\cmip5\output\' models{model} '\r1i1p1\' rcp '\tasmax\regrid\world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
        if nanmean(nanmean(nanmean(nanmean(nanmean(tmax{3}))))) > 100
            tmax{3} = tmax{3} - 273.15;
        end
        tmax = dailyToMonthly(tmax);
    end
    
    lat = tmax{1};
    lon = tmax{2};
    data = tmax{3};
    
    % whole nile region
    regionBounds = [[2 32]; [25, 44]];
    [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
    
    for season = 1:size(seasons, 1)
        regionT = squeeze(nanmean(data(latInds, lonInds, :, seasons(season, :)), 4));
        tempSeasonal{season} = regionT;
    end
    
    if strcmp(dataset, 'cmip5')
        save(['2017-nile-climate/output/temp-seasonal-' dataset '-historical-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{model} '.mat'], 'tempSeasonal');
    else
        save(['2017-nile-climate/output/temp-seasonal-' dataset '.mat'], 'tempSeasonal');
    end
    clear tmax data TSeasonal;
end
