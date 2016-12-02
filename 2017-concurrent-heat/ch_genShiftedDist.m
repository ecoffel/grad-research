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
%baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

baseRegrid = true;

region = 'world';
plotRegion = 'world';

basePeriodYears = 1981:2004;
futurePeriodYears = 2020:2080;

% how much global mean temp will rise over the future period
startTemp = 0.8;
tempRise = 2;

% temp rise for each future year
annualTempDelta = linspace(startTemp, startTemp + tempRise, length(futurePeriodYears));

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

latBounds = [-60 60];
lonBounds = [0 360];

load lat;
load lon;

% look at change above this base period temperature percentile
thresh = 90;

numDays = 372;

baseData = zeros(size(lat, 1), size(lat, 2), numDays, length(basePeriodYears));
baseData(baseData == 0) = NaN;

futureData = [];
selData = [];

['loading base: ' baseDataset]
for m = 1:length(baseModels)
    curModel = baseModels{m};

    baseThresh = [];
    
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
            curCellData = reshape(squeeze(baseData(x, y, :, :)), [size(baseData, 3)*size(baseData, 4), 1]);
            baseThresh(x, y) = prctile(curCellData, thresh);
            clear curCellData;
        end
    end

    % start out taking the mean over all years - will change to pulling
    % random years for each future day or something similar
    baseData = nanmean(baseData, 4);
    
    for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
        futureData(:, :, :) = baseData + repmat(annualTempDelta(y-futurePeriodYears(1)+1), [size(baseData, 1), ...
                                                                                            size(baseData, 2), ...
                                                                                            size(baseData, 3)]);
        selData(:, :, y-futurePeriodYears(1)+1, m) = ch_genSelData(futureData, baseThresh, false);
    end
    
    clear baseData futureData;
end

save(['selData-cmip5-' num2str(thresh) '-shifted-' num2str(tempRise)], 'selData');


