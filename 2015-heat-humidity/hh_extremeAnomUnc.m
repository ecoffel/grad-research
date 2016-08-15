% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};
% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'wb';

baseRegrid = true;

region = 'world';
rcp = 'rcp45';
ensembles = 1;

plotRegion = 'world';

plotTitle = ['CMIP5 annual maximum wet-bulb'];

basePeriodYears = 1985:2004;
testPeriodYears = 2060:2070;

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
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = [rcp '/'];
end

lat = [];
lon = [];
baseExt = {};

for e = ensembles
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
    elseif strcmp(baseDatasetStr, 'narr')
        baseDatasetStr = ['narr'];
        baseDataDir = 'narr/output';
        baseEnsemble = '';
        baseRcp = '';
    end

    baseExt{e} = {};
    
    for m = 1:length(baseModels)
        if strcmp(baseModels{m}, '')
            curModel = baseModels{m};
        else
            curModel = [baseModels{m} '/'];
        end

        baseExt{e}{m} = {};

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

            baseExt{e}{m} = {baseExt{e}{m}{:} baseExtTmp{:}};
            clear baseDaily baseExtTmp;
        end
    end

end

['done loading...']

baseAvg = [];
% average over ensembles, models, and years
for e = 1:length(baseExt)
    for m = 1:length(baseExt{e})
        for y = 1:length(baseExt{e}{m})
            baseAvg(:,:,e,m,y) = baseExt{e}{m}{y}{3};
        end
    end
end

baseAvg = squeeze(nanmean(nanmean(nanmean(baseAvg, 5), 4), 3));

futureData = [];

% load projected change data
decCount = 1;
for t = testPeriodYears(1):10:testPeriodYears(end-1)
    load(['chg-data-' baseVar '-multi-model-' num2str(t) '-' num2str(t+10) '.mat']);
    
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

prcRange = [25 75];
prcInd = [round(size(futureData, 4) * (prcRange(1)/100.0)), round(size(futureData, 4) * (prcRange(2)/100.0))];

for d = 1:size(futureData, 3)
    
    result = {lat, lon, futureData(:, :, d, prcInd(1))};
    fileTitle = ['extremeAnomUnc-' num2str(prcRange(1)) '-' num2str(testPeriodYears(d)) '-' num2str(testPeriodYears(d)+10)];
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
    fileTitle = ['extremeAnomUnc-' num2str(prcRange(2)) '-' num2str(testPeriodYears(d)) '-' num2str(testPeriodYears(d)+10)];
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
