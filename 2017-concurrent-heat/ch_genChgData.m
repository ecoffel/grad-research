% generate mean annual changes for each model at a given temp percentile
% for each gridbox

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
baseVar = 'tasmax';

baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
% baseModels = {'access1-0'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';
futureVar = 'tasmax';

futureModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
% futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
%basePeriodYears = 1980:1990;
futurePeriodYears = 2020:2080;
%futurePeriodYears = 2050:2060;

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

load lat;
load lon;

% look at change above this base period temperature percentile
thresh = 50;

numDays = 372;

baseData = zeros(size(lat, 1), size(lat, 2), numDays, length(basePeriodYears));
baseData(baseData == 0) = NaN;

futureData = zeros(size(lat, 1), size(lat, 2), numDays, length(futurePeriodYears));
futureData(futureData == 0) = NaN;

% mean temps (above thresh) in the base period
baseThresh = [];
futureThresh = [];
chgData = [];

['loading base: ' baseDataset]
for m = 1:length(baseModels)
    curModel = baseModels{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end

        baseDaily3d = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                             size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

        baseData(1:size(baseDaily3d, 1), 1:size(baseDaily3d, 2), 1:size(baseDaily3d, 3), y-basePeriodYears(1)+1) = baseDaily3d;
        clear baseDaily baseDaily3d;
    end

    for x = 1:size(baseData, 1)
        for y = 1:size(baseData, 2)
            curGridCell = squeeze(reshape(baseData(x, y, :, :), [size(baseData, 3)*size(baseData, 4), 1]));
            baseThresh(x, y, m) = prctile(curGridCell, thresh);
        end
    end
    
    clear baseData;
end

% ------------ load future data -------------    

['loading future: ' futureDataset]
for m = 1:length(futureModels)
        curModel = futureModels{m};

    ['loading future model ' curModel '...']
    
    for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
        ['year ' num2str(y) '...']

        futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if futureDaily{3}(1,1,1,1,1) > 100
            futureDaily{3} = futureDaily{3} - 273.15;
        end

        futureDaily3d = reshape(futureDaily{3}, [size(futureDaily{3}, 1), size(futureDaily{3}, 2), ...
                                                 size(futureDaily{3}, 3)*size(futureDaily{3}, 4)*size(futureDaily{3}, 5)]);
        futureData(1:size(futureDaily3d, 1), 1:size(futureDaily3d, 2), 1:size(futureDaily3d, 3), y-futurePeriodYears(1)+1) = futureDaily3d;

        clear futureDaily futureDaily3d;
    end
    
    for x = 1:size(futureData, 1)
        for y = 1:size(futureData, 2)
            for year = 1:size(futureData, 4)
                curGridCell = squeeze(reshape(futureData(x, y, :, year), [size(futureData, 3), 1]));
                futureThresh(x, y, year, m) = prctile(curGridCell, thresh);
                chgData(x, y, year, m) = futureThresh(x, y, year, m) - baseThresh(x, y, m);
            end
        end
    end

    clear futureData;
end

save(['chgData-cmip5-' num2str(thresh) '-' futureRcps{1} '.mat'], 'chgData');



