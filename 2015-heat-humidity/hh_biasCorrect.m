season = 'all';
basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'ncep';
testDataset = 'cmip5';

baseModels = {''};
testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};

baseVar = 'wb';
testVar = 'wb';

percentiles = 10:10:100;

baseRegrid = true;
testRegrid = true;

basePeriodYears = 1985:2004;

latBounds = [30 55];
lonBounds = [-100 -62] + 360;

baseDir = 'e:/data/';
yearStep = 1;

baseDataDir = '';
baseDatasetStr = '';
if strcmp(baseDataset, 'cmip5')
    if length(baseModels) == 1
        baseDatasetStr = ['cmip5-' baseModels{1}]
    else
        baseDatasetStr = ['cmip5-mm'];
    end
    
    baseDataDir = 'cmip5/output';
    baseEnsemble = 'r1i1p1/';
    baseRcp = '';
elseif strcmp(baseDataset, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    baseEnsemble = '';
    baseRcp = '';
elseif strcmp(baseDataset, 'narr')
    baseDatasetStr = ['narr'];
    baseDataDir = 'narr/output';
    baseEnsemble = '';
    baseRcp = '';
end

testDataDir = '';
testDatasetStr = '';
if strcmp(testDataset, 'cmip5')
    if length(testModels) == 1
        testDatasetStr = ['cmip5-' testModels{1}]
    else
        testDatasetStr = ['cmip5-mm'];
    end
    
    testDataDir = 'cmip5/output';
    testEnsemble = 'r1i1p1/';
    testRcp = 'historical/';
elseif strcmp(testDataset, 'ncep')
    testDatasetStr = ['ncep'];
    testDataDir = 'ncep-reanalysis/output';
    testEnsemble = '';
    testRcp = '';
elseif strcmp(testDataset, 'narr')
    testDatasetStr = ['narr'];
    testDataDir = 'narr/output';
    testEnsemble = '';
    testRcp = '';
end

baseData = {};
baseLat = [];
baseLon = [];

% first load base dataset
['loading base dataset: ' baseDataset]
for y = basePeriodYears(1):yearStep:basePeriodYears(end)
    ['year ' num2str(y) '...']
        
    if baseRegrid
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    else
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    end
    baseDaily{3} = baseDaily{3}-273.15;
    
    [latIndex, lonIndex] = latLonIndexRange(baseDaily, latBounds, lonBounds);
    baseDaily = {baseDaily{1}(latIndex, lonIndex), baseDaily{2}(latIndex, lonIndex), baseDaily{3}(latIndex, lonIndex, :, :, :)};
    
    if length(baseLat) == 0
        baseLat = baseDaily{1};
        baseLon = baseDaily{2};
    end
    
    baseDaily{3} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

    baseData = {baseData{:} baseDaily{3}};
    clear baseDaily;
end

baseDist = {};
baseMeans = [];

for xlat = 1:size(baseData{1}, 1)
    if size(baseDist, 1) < xlat
        baseDist{xlat} = {};
    end
    
    for ylon = 1:size(baseData{1}, 2)
        baseDist{xlat}{ylon} = [];
        for n = 1:length(baseData)
            baseDist{xlat}{ylon} = [baseDist{xlat}{ylon}(:); squeeze(baseData{n}(xlat, ylon, :))];
        end
        pIndex = 1;
        cutoffs = [];
        for p = percentiles
            % store cuttoffs so we take mean between each percentile
            cutoffs(pIndex) = prctile(baseDist{xlat}{ylon}, p);
            if pIndex == 1
                baseMeans(xlat, ylon, pIndex) = nanmean(baseDist{xlat}{ylon}(baseDist{xlat}{ylon}(:) < cutoffs(pIndex)));
            else
                baseMeans(xlat, ylon, pIndex) = nanmean(baseDist{xlat}{ylon}(baseDist{xlat}{ylon}(:) < cutoffs(pIndex) & baseDist{xlat}{ylon}(:) > cutoffs(pIndex-1)));
            end
            pIndex = pIndex+1;
        end
    end
end

clear baseDist baseData;

testBiasCorrection = {};
    
for m = 1:length(testModels)
    if strcmp(testModels{m}, '')
        curModel = testModels{m};
    else
        curModel = [testModels{m} '/'];
    end

    testData = {};
    testBiasCorrection{m} = {testModels{m}, []};
    
    ['loading ' curModel ' base']
    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']
        
        if testRegrid
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        testDaily{3} = testDaily{3}-273.15;
        
        [latIndex, lonIndex] = latLonIndexRange(testDaily, latBounds, lonBounds);
        testDaily = {testDaily{1}(latIndex, lonIndex), testDaily{2}(latIndex, lonIndex), testDaily{3}(latIndex, lonIndex, :, :, :)};
        testDaily{3} = reshape(testDaily{3}, [size(testDaily{3}, 1), size(testDaily{3}, 2), size(testDaily{3}, 3)*size(testDaily{3}, 4)*size(testDaily{3}, 5)]);
        
        if size(testDaily{3}, 1) ~= size(baseLat, 1) | size(testDaily{3}, 2) ~= size(baseLon, 2)
            testDaily = regridGriddata(testDaily, {baseLat, baseLon, []});
        end
        
        testData = {testData{:} testDaily{3}};
        clear baseDaily;
    end
    
    testDist = {};

    for xlat = 1:size(testData{1}, 1)
        if size(testDist, 1) < xlat
            testDist{xlat} = {};
        end

        for ylon = 1:size(testData{1}, 2)
            testDist{xlat}{ylon} = [];
            for n = 1:length(testData)
                testDist{xlat}{ylon} = [testDist{xlat}{ylon}(:); squeeze(testData{n}(xlat, ylon, :))];
            end
            pIndex = 1;
            cutoffs = [];
            for p = percentiles
                % store cuttoffs so we take mean between each percentile
                cutoffs(pIndex) = prctile(testDist{xlat}{ylon}, p);
                if pIndex == 1
                    curMean = nanmean(testDist{xlat}{ylon}(testDist{xlat}{ylon}(:) < cutoffs(pIndex)));
                else
                    curMean = nanmean(testDist{xlat}{ylon}(testDist{xlat}{ylon}(:) < cutoffs(pIndex) & testDist{xlat}{ylon}(:) > cutoffs(pIndex-1)));
                end
                testBiasCorrection{m}{2}(xlat, ylon, pIndex) = baseMeans(xlat, ylon, pIndex) - curMean;
                pIndex = pIndex+1;
            end
        end
    end
    clear testDist testData;
end

fileStr = 'cmip5BiasCorrection_wb_neus_tmp';

eval([fileStr ' =  testBiasCorrection;']);
save([fileStr '.mat'], fileStr);



