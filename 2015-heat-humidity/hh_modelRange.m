% % find the variability between models for a given variable

% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

baseModels = {'bnu-esm', 'canesm2'};
testModels = {'bnu-esm', 'canesm2'};
% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
% testModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

baseVar = 'wb';
testVar = 'wb';

baseRegrid = true;
testRegrid = true;

baseBiasCorrect = false;
testBiasCorrect = false;

basePeriodYears = 1985:2004;
testPeriodYears = 2050:2069;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'png';

rcps = {'rcp45', 'rcp85'};
region = 'world';
plotRegion = 'world';

% percentile range to show
percentiles = [25 75];

blockWater = true;

baseDir = 'e:/data/';
yearStep = 1;

if ~testBiasCorrect
    testBcStr = '';
else
    testBcStr = '-bc';
end

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
    findMax = false;
    months = [12 1 2];
    maxMinStr = 'minimum';
elseif strcmp(season, 'all')
    findMax = true;
    months = 1:12;
    maxMinStr = 'maximum';
end

if annualmean
    maxMinStr = ['mean ' maxMinStr];
    maxMinFileStr = 'mean';
else
    maxMinFileStr = 'ext';
end

if strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin') | strcmp(baseVar, 'wb')
    plotRange = [0 5];
    plotXUnits = 'degrees C';
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/'
end

if strcmp(testPeriod, 'past')
    testPeriod = basePeriodYears;
    testRcp = 'historical/'
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        modelStr = strsplit(baseModels{1}, '/');
        baseDatasetStr = ['cmip5-' modelStr{1} '-' modelStr{2}]
    else
        baseDatasetStr = ['cmip5-mm'];
    end

    baseDataDir = 'cmip5/output';
    baseEnsemble = 'r1i1p1/';
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    baseEnsemble = '';
    baseRcp = '';
end

fileTimeStr = '';
if ~strcmp(testVar, '')
    fileTimeStr = [testDataset '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [season '-' maxMinFileStr '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end
    
% load base dataset
baseExt = {};
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

        if annualmean
            baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        else
            baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        end

        baseExt{m} = {baseExt{m}{:} baseExtTmp{:}};
        clear baseDaily baseExtTmp;
    end
end

% loop over rcps and load future data
futureExt = {};
for r = 1:length(rcps)
    rcp = rcps{r};
    
    if strcmp(basePeriod, 'future')
        basePeriod = testPeriodYears;
        baseRcp = [rcp '/'];
    end

    if strcmp(testPeriod, 'future')
        testPeriod = testPeriodYears;
        testRcp = [rcp '/'];
    end

    if ~strcmp(testVar, '')
        testDatasetStr = testDataset;
        if strcmp(testDatasetStr, 'cmip5')
            if length(testModels) == 1
                modelStr = strsplit(testModels{1}, '/');
                testDatasetStr = ['cmip5-' modelStr{1} '-' modelStr{2}];
            else 
                testDatasetStr = ['cmip5-mm'];
            end

            testDataDir = 'cmip5/output';
            testEnsemble = 'r1i1p1/';
        elseif strcmp(testDatasetStr, 'ncep')
            testDatasetStr = ['ncep'];
            testDataDir = 'ncep-reanalysis/output';
            testEnsemble = '';
            testRcp = '';
        end

    end

    
    futureExt{r} = {};
    if ~strcmp(testVar, '')
        for m = 1:length(testModels)
            if strcmp(testModels{m}, '')
                curModel = testModels{m};
            else
                curModel = [testModels{m} '/'];
            end

            futureExt{r}{m} = {};

            ['loading ' curModel ' future']
            for y = testPeriod(1):yearStep:testPeriod(end)
                ['year ' num2str(y) '...']

                % load daily data
                if testRegrid
                    testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/' region testBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                else
                    testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                end

                if annualmean
                    testDailyExtTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
                else
                    testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);
                end

                futureExt{r}{m} = {futureExt{r}{m}{:}, testDailyExtTmp{:}};
                clear testDaily testDailyExtTmp;
            end
        end
    end
end

['done loading...']

% average over the future period and rank each gridbox from the models & rcps
testData = [];
baseData = [];
chgData = [];

% average over models and years
for m = 1:length(baseExt)
    for y = 1:length(baseExt{m})
        baseData(:,:,m,y) = baseExt{m}{y}{3};
    end
end

for r = 1:length(rcps)
    for m = 1:length(futureExt{r})
        for y = 1:length(futureExt{r}{m})
            testData(:,:,m,r,y) = futureExt{r}{m}{y}{3};
        end
    end
end

% average over future period
baseData = nanmean(baseData, 5);
testData = nanmean(testData, 5);


% loop over models and rcps to make a list of all possible changes
i = 1;
for m = 1:size(testData, 3)
    for r = 1:size(testData, 4)
        chgData(:,:,i) = squeeze(testData(:,:,m,r)) - baseData(:,:,m);
        i = i+1;
    end
end

% loop over all models
for m = 1:size(baseData, 3)
    
    % and over all gridboxes
    for x = 1:size(baseData, 1)
        for y = 1:size(baseData, 2)
            % sort the models
            baseData(x, y, :) = sort(baseData(x, y, :));
            testData(x, y, :) = sort(reshape(testData(x, y, :, :), [1 1 size(testData, 3)*size(testData, 4)]));
            chgData(x, y, :) = sort(chgData(x, y, :));
        end
    end
end

chgLow = squeeze(chgData(:, :, round(percentiles(1)/100.0 * size(chgData, 3))));
chgHigh = squeeze(chgData(:, :, round(percentiles(2)/100.0 * size(chgData, 3))));

baseLow = squeeze(baseData(:, :, round(percentiles(1)/100.0 * size(baseData, 3))));
baseHigh = squeeze(baseData(:, :, round(percentiles(2)/100.0 * size(baseData, 3))));

testLow = squeeze(testData(:, :, round(percentiles(1)/100.0 * size(testData, 3))));
testHigh = squeeze(testData(:, :, round(percentiles(2)/100.0 * size(testData, 3))));

resultLow = {baseExt{1}{1}{1}, baseExt{1}{1}{2}, chgLow};
resultHigh = {baseExt{1}{1}{1}, baseExt{1}{1}{2}, chgHigh};

plotTitle = ['Lower bound'];
fileTitle = ['modelRange-low-' baseVar '-' fileTimeStr '.' exportformat];

saveData = struct('data', {resultLow}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', [-5 5], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', 'degrees C', ...
                  'blockWater', blockWater, ...
                  'plotCountries', false, ...
                  'plotStates', false);

plotFromDataFile(saveData);


plotTitle = ['Upper bound'];
fileTitle = ['modelRange-high-' baseVar '-' fileTimeStr '.' exportformat];

saveData = struct('data', {resultHigh}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', [-5 5], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', 'degrees C', ...
                  'blockWater', blockWater, ...
                  'plotCountries', false, ...
                  'plotStates', false);

plotFromDataFile(saveData);
