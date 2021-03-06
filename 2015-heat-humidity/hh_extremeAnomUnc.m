season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};
baseVar = 'tmax';

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

if strcmp(baseVar, 'wb')
    plotRange = [0 35];
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    plotRange = [-40 40];
    plotXUnits = 'degrees C';
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/';
end

lat = [];
lon = [];
baseExt = {};

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        baseDatasetStr = ['cmip5-' baseModels{1}]
    else
        baseDatasetStr = ['cmip5-mm'];
    end

    baseDataDir = 'cmip5/output';
    baseEnsemble = ['r' num2str(e) 'i1p1/'];
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    baseEnsemble = '';
    baseRcp = '';
end

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseExt{m} = {};

    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']

        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end

        if length(lat) == 0
            lat = baseDaily{1};
            lon = baseDaily{2};
        end

        if ~strcmp(baseVar, 'rh') && baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end

        baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);

        baseExt{m} = {baseExt{m}{:} baseExtTmp{:}};
        clear baseDaily baseExtTmp;
    end
end

['done loading...']

baseAvg = [];
% average over ensembles, models, and years
    for m = 1:length(baseExt)
        for y = 1:length(baseExt{m})
            baseAvg(:,:,m,y) = baseExt{m}{y}{3};
        end
    end

baseAvg = squeeze(nanmean(nanmean(baseAvg, 4), 3));

futureData = [];

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
    
    for c = 1:size(chgData, 3)
        % compute future scenarios by adding change onto base data
        futureData(:, :, decCount, c) = baseAvg + chgData(:, :, c);
    end
    
    decCount = decCount + 1;
    clear chgData;
end

prcRange = [10 90];
prcInd = [round(size(futureData, 4) * (prcRange(1)/100.0)), round(size(futureData, 4) * (prcRange(2)/100.0))];

for d = 1:size(futureData, 3)
    
    result = {lat, lon, futureData(:, :, d, prcInd(1))};
    fileTitle = ['extremeAnomUnc-' chgType '-' num2str(prcRange(1)) '-' num2str(testPeriodYears(d)) '-' num2str(testPeriodYears(d)+10)];
    plotTitle = ['Annual maximum temperature, ' num2str(prcRange(1)) ' percentile'];

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
    plotTitle = ['Annual maximum temperature, ' num2str(prcRange(2)) ' percentile'];

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
