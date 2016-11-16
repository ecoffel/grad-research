
season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

% baseModels = {'csiro-mk3-6-0'};
% testModels = {'csiro-mk3-6-0'};
baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
testModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

baseVar = 'wb';
testVar = 'wb';

baseRegrid = true;
testRegrid = true;

baseBiasCorrect = false;
testBiasCorrect = false;

basePeriodYears = 1985:2004;
testPeriodYears = 2060:2070;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;

meanStr = 'mean';
if ~annualmean
    meanStr = 'extreme';
end

ensembles = 1;

rcps = {'rcp45'};
rcpStr = 'rcp45';

region = 'world';


mode = 'ensemble';
if length(baseModels) > 1
    mode = 'multi-model';
end

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

if strcmp(basePeriod, 'past')
    baseRcp = 'historical/'
end

if strcmp(testPeriod, 'past')
    testRcp = 'historical/'
end

baseExt = {};
futureExt = {};

% loop over all selected ensemble members
for e = ensembles
    
    baseExt{e} = {};
    futureExt{e} = {};
    
    baseDatasetStr = baseDataset;
    if strcmp(baseDatasetStr, 'cmip5')
        if length(baseModels) == 1
            baseDatasetStr = baseModels{1};
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

    % load base dataset
    for m = 1:length(baseModels)
        if strcmp(baseModels{m}, '')
            curModel = baseModels{m};
        else
            curModel = [baseModels{m} '/'];
        end

        baseExt{e}{m} = {};

        ['loading ' curModel ' base']
        for y = basePeriodYears(1):yearStep:basePeriodYears(end)
            ['year ' num2str(y) '...']

            if baseRegrid
                baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end

            if nanmean(nanmean(nanmean(nanmean(nanmean(baseDaily{3}, 5), 4), 3), 2), 1) > 100
                baseDaily{3} = baseDaily{3} - 273.15;
                ['K -> C...']
            end
            
            if annualmean
                baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
            else
                baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
            end
            
            baseExt{e}{m} = {baseExt{e}{m}{:} baseExtTmp{:}};
            clear baseDaily baseExtTmp;
        end
    end

    % loop over rcps and load future data
    
    for r = 1:length(rcps)
        rcp = rcps{r};

        if strcmp(basePeriod, 'future')
            baseRcp = [rcp '/'];
        end

        if strcmp(testPeriod, 'future')
            testRcp = [rcp '/'];
        end

        if ~strcmp(testVar, '')
            testDatasetStr = testDataset;
            if strcmp(testDatasetStr, 'cmip5')
                if length(testModels) == 1
                    testDatasetStr = testModels{1};
                else 
                    testDatasetStr = ['cmip5-mm'];
                end

                testDataDir = 'cmip5/output';
                testEnsemble = ['r' num2str(e) 'i1p1/'];
            elseif strcmp(testDatasetStr, 'ncep')
                testDatasetStr = ['ncep'];
                testDataDir = 'ncep-reanalysis/output';
                testEnsemble = '';
                testRcp = '';
            end

        end


        futureExt{e}{r} = {};
        if ~strcmp(testVar, '')
            for m = 1:length(testModels)
                if strcmp(testModels{m}, '')
                    curModel = testModels{m};
                else
                    curModel = [testModels{m} '/'];
                end

                futureExt{e}{r}{m} = {};

                ['loading ' curModel ' future']
                for y = testPeriodYears(1):yearStep:testPeriodYears(end)
                    ['year ' num2str(y) '...']

                    % load daily data
                    if testRegrid
                        testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/' region testBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                    else
                        testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                    end
                    
                    if nanmean(nanmean(nanmean(nanmean(nanmean(testDaily{3}, 5), 4), 3), 2), 1) > 100
                        testDaily{3} = testDaily{3} - 273.15;
                        ['K -> C...']
                    end

                    if annualmean
                        testDailyExtTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
                    else
                        testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);
                    end

                    futureExt{e}{r}{m} = {futureExt{e}{r}{m}{:}, testDailyExtTmp{:}};
                    clear testDaily testDailyExtTmp;
                end
            end
        end
    end
end

['done loading...']
  
% average over the future period and rank each gridbox from the models & rcps
testData = [];
baseData = [];
chgData = [];

% average over ensembles, models, and years
for e = 1:length(ensembles)
    for m = 1:length(baseExt{e})
        for y = 1:length(baseExt{e}{m})
            baseData(:,:,e,m,y) = baseExt{e}{m}{y}{3};
        end
    end
end

for e = 1:length(ensembles)
    for r = 1:length(rcps)
        for m = 1:length(futureExt{e}{r})
            for y = 1:length(futureExt{e}{r}{m})
                testData(:,:,e,m,r,y) = futureExt{e}{r}{m}{y}{3};
            end
        end
    end
end

% average over future period
baseData = nanmean(baseData, 5);
testData = nanmean(testData, 6);

% loop over models and rcps to make a list of all possible changes
i = 1;
for e = 1:size(testData, 3)
    for m = 1:size(testData, 4)
        for r = 1:size(testData, 5)
            chgData(:,:,i) = squeeze(testData(:,:,e,m,r)) - baseData(:,:,e,m);
            i = i+1;
        end
    end
end

save(['chg-data-' baseVar '-' rcpStr '-' mode '-' meanStr '-' num2str(testPeriodYears(1)) '-' num2str(testPeriodYears(end)) '.mat'], 'chgData');
