
season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};
baseVar = 'wb';

baseRegrid = true;

region = 'world';
chgType = 'multi-model';

plotRegion = 'world';
plotTitle = ['CMIP5 annual maximum wet-bulb'];

basePeriodYears = 1985:2004;
testPeriodYears = 2070:2080;

% compare the annual mean temperatures or the mean extreme temperatures
exportFormat = 'png';

blockWater = true;
baseBiasCorrect = false;

heatThreshold = 29;

baseDir = 'e:/data/';
yearStep = 1;

if ~baseBiasCorrect
    baseBcStr = '';
else
    baseBcStr = '-bc';
end

if strcmp(season, 'summer')
    findMax = true;
    months = [6 7 8];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = true;
    months = [12 1 2];
    maxMinStr = 'maximum';
elseif strcmp(season, 'all')
    findMax = true;
    months = 1:12;
    maxMinStr = 'maximum';
end

plotRange = [0 100];

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/';
end

lat = [];
lon = [];
baseData = {};

baseDatasetStr = ['ncep'];
baseDataDir = 'ncep-reanalysis/output';
baseEnsemble = '';
baseRcp = '';

['loading ncep base...']
for y = basePeriod(1):yearStep:basePeriod(end)
    ['year ' num2str(y) '...']

    if baseRegrid
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    else
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    end

    if length(lat) == 0
        lat = baseDaily{1};
        lon = baseDaily{2};
    end

    if ~strcmp(baseVar, 'rh') && baseDaily{3}(1,1,1,1,1) > 100
        baseDaily{3} = baseDaily{3} - 273.15;
    end

    baseData{y-basePeriod(1)+1} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                         size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
    clear baseDaily baseExtTmp;
end


['done loading...']

baseDataGrid = [];
% average over ensembles, models, and years
for y = 1:length(baseData)
    baseDataGrid(:,:,y,:) = baseData{y};
end

clear baseData;



% load projected change data
decCount = 1;
for t = testPeriodYears(1):10:testPeriodYears(end-1)
    load(['chg-data-' baseVar '-' chgType '-' num2str(t) '-' num2str(t+10) '.mat']);
    
    chgData(chgData > 10) = NaN;
    
    for x = 1:size(chgData, 1)
        for y = 1:size(chgData, 2)
            chgData(x, y, :) = sort(chgData(x, y, :));
        end
    end
    
    futureCount = zeros(size(chgData, 1), size(chgData, 2), size(chgData, 3));
    
    for c = 1:size(chgData, 3)
        curCount = zeros(size(chgData, 1), size(chgData, 2), size(baseDataGrid, 3), size(baseDataGrid, 4));
        futureData = [];
        for y = 1:size(baseDataGrid, 3)
        
            for d = 1:size(baseDataGrid, 4)
                % compute future scenarios by adding change onto base data
                futureData(:, :, y, d) = squeeze(baseDataGrid(:, :, y, d)) + chgData(:, :, c);
            end
        end
        
        % count number of exceedences
        for x = 1:size(futureData, 1)
            for y = 1:size(futureData, 2)
                for year = 1:size(futureData, 3)
                    for d = 1:size(futureData, 4)
                        if futureData(x, y, year, d) > heatThreshold
                            curCount(x, y, year, d) = curCount(x, y, year, d) + 1;
                        end
                    end
                end
            end
        end
        futureCount(:, :, c) = nanmean(nanmean(curCount, 4), 3);
        clear curCount;
        
    end
    
    decCount = decCount + 1;
    clear chgData;
end

% calculate annual probability of exceeding threshold at each gridbox




for d = 1:size(futureData, 3)
    
    result = {lat, lon, futureData(:, :, d, prcInd(1))};
    fileTitle = ['extremeAnomUnc-' chgType '-' num2str(prcRange(1)) '-' num2str(testPeriodYears(d)) '-' num2str(testPeriodYears(d)+10)];
    plotTitle = ['Annual maximum wet-bulb, ' num2str(prcRange(1)) ' percentile'];

    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', [fileTitle '.' exportFormat], ...
                      'plotXUnits', plotXUnits, ...
                      'plotCountries', false, ...
                      'plotStates', true, ...
                      'blockWater', blockWater);

    plotFromDataFile(saveData);

    result = {lat, lon, futureData(:, :, d, prcInd(2))};
    fileTitle = ['extremeAnomUnc-' chgType '-' num2str(prcRange(2)) '-' num2str(testPeriodYears(d)) '-' num2str(testPeriodYears(d)+10)];
    plotTitle = ['Annual maximum wet-bulb, ' num2str(prcRange(2)) ' percentile'];

    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', [fileTitle '.' exportFormat], ...
                      'plotXUnits', plotXUnits, ...
                      'plotCountries', false, ...
                      'plotStates', true, ...
                      'blockWater', blockWater);

    plotFromDataFile(saveData);

end
