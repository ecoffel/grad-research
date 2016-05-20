% calculate base cutoffs and store them in the final output file so that
% they can be applied to the base data for bias correction

season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'ncep';
testDataset = 'cmip5';

baseModels = {''};
% testModels = {'bnu-esm', 'canesm2', 'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'cmcc-cm', 'cmcc-cms', ...
%           'csiro-mk3-6-0', 'ec-earth', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'inmcm4', ...
%           'hadgem2-es', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

testModels = {'mri-cgcm3'};

addToBC = false;    

baseVar = 'tmin';
testVar = 'tasmin';

percentiles = 10:10:100;

baseRegrid = true;
testRegrid = true;

basePeriodYears = 1985:2004;

futureDecades = {2006:2010, 2010:2020, 2020:2030, 2030:2040, 2040:2050, 2050:2060, 2060:2070, 2070:2080, 2080:2090, 2090:2099};

region = 'usne';

if strcmp(region, 'usne')
    latBounds = [30 55];
    lonBounds = [-100 -62] + 360;
elseif strcmp(region, 'west_africa')
    latBounds = [0, 30];
    lonBounds = [340, 40];
elseif strcmp(region, 'china')
    latBounds = [20, 55];
    lonBounds = [75, 135];
elseif strcmp(region, 'world')
    latBounds = [-90, 90];
    lonBounds = [0, 360];
elseif strcmp(region, 'india')
    latBounds = [8, 34];
    lonBounds = [67, 90];
elseif strcmp(region, 'nepal')
    latBounds = [10, 35];
    lonBounds = [75, 100];
end

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
    futureRcp = 'rcp45/';
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

load('waterGrid');

% first load base dataset
['loading base dataset: ' baseDataset]
for y = basePeriodYears(1):yearStep:basePeriodYears(end)
    ['year ' num2str(y) '...']
        
    if baseRegrid
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    else
        baseDaily = loadDailyData([baseDir baseDataDir '/' baseEnsemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    end
    
    if baseDaily{3}(1,1,1,1,1) > 100
        baseDaily{3} = baseDaily{3}-273.15;
    end
    
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
baseCutoffs = [];

for xlat = 1:size(baseData{1}, 1)
    if size(baseDist, 1) < xlat
        baseDist{xlat} = {};
    end
    
    for ylon = 1:size(baseData{1}, 2)
        baseDist{xlat}{ylon} = [];
        
        if waterGrid(xlat, ylon)
            baseMeans(xlat, ylon) = 0;
            continue;
        end
        
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
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        if testDaily{3}(1,1,1,1,1) > 100
            testDaily{3} = testDaily{3}-273.15;
        end
        
        [latIndex, lonIndex] = latLonIndexRange(testDaily, latBounds, lonBounds);
        testDaily = {testDaily{1}(latIndex, lonIndex), testDaily{2}(latIndex, lonIndex), testDaily{3}(latIndex, lonIndex, :, :, :)};
        testDaily{3} = reshape(testDaily{3}, [size(testDaily{3}, 1), size(testDaily{3}, 2), size(testDaily{3}, 3)*size(testDaily{3}, 4)*size(testDaily{3}, 5)]);
        
        if size(testDaily{3}, 1) ~= size(baseLat, 1) | size(testDaily{3}, 2) ~= size(baseLon, 2)
            testDaily = regridGriddata(testDaily, {baseLat, baseLon, []});
        end
        
        testData = {testData{:} testDaily{3}};
        clear testDaily;
    end
    
    ['loading future decades...']
    decadeCutoffs = {};
    for decade = 1:length(futureDecades)
        decadeCutoffs{decade} = [];
        curDecadeData = {};
        for y = 1:length(futureDecades{decade})
            ['year ' num2str(futureDecades{decade}(y)) '...']
        
            if testRegrid
                testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble futureRcp testVar '/regrid/' region], 'yearStart', futureDecades{decade}(y), 'yearEnd', (futureDecades{decade}(y)+yearStep)-1);
            else
                testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble futureRcp testVar], 'yearStart', futureDecades{decade}(y), 'yearEnd', (futureDecades{decade}(y)+yearStep)-1);
            end
            
            if testDaily{3}(1,1,1,1,1) > 100
                testDaily{3} = testDaily{3}-273.15;
            end

            [latIndex, lonIndex] = latLonIndexRange(testDaily, latBounds, lonBounds);
            testDaily = {testDaily{1}(latIndex, lonIndex), testDaily{2}(latIndex, lonIndex), testDaily{3}(latIndex, lonIndex, :, :, :)};
            testDaily{3} = reshape(testDaily{3}, [size(testDaily{3}, 1), size(testDaily{3}, 2), size(testDaily{3}, 3)*size(testDaily{3}, 4)*size(testDaily{3}, 5)]);

            if size(testDaily{3}, 1) ~= size(baseLat, 1) | size(testDaily{3}, 2) ~= size(baseLon, 2)
                testDaily = regridGriddata(testDaily, {baseLat, baseLon, []});
            end
            
            for xlat = 1:size(testDaily{3}, 1)
                if y == 1
                    curDecadeData{xlat} = {};
                end
                
                for ylon = 1:size(testDaily{3}, 2)
                    if y == 1
                        curDecadeData{xlat}{ylon} = [];
                    end
                    
                    curDecadeData{xlat}{ylon} = [curDecadeData{xlat}{ylon}(:); squeeze(testDaily{3}(xlat, ylon, :))];
                end
            end
            
            clear testDaily;
        end
        
        % assemble cutoffs for current decade
        for xlat = 1:length(curDecadeData)
            for ylon = 1:length(curDecadeData{xlat})
                pIndex = 1;
                
                if waterGrid(xlat, ylon)
                    decadeCutoffs{decade}(xlat, ylon, pIndex) = 0;
                    continue;
                end
                
                for p = percentiles
                    decadeCutoffs{decade}(xlat, ylon, pIndex) = prctile(curDecadeData{xlat}{ylon}, p);
                    pIndex = pIndex + 1;
                end
            end
        end
        
        clear curDecadeData;
    end
    
    testDist = {};
    testBiasCorrection{m}{3} = {basePeriodYears(1), []}
    
    for xlat = 1:size(testData{1}, 1)
        if size(testDist, 1) < xlat
            testDist{xlat} = {};
        end

        for ylon = 1:size(testData{1}, 2)
            testDist{xlat}{ylon} = [];
            
            if waterGrid(xlat, ylon)
                testBiasCorrection{m}{2}(xlat, ylon, pIndex) = 0;
                testBiasCorrection{m}{3}{2}(xlat, ylon, pIndex) = 0;
                continue;
            end
            
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
                testBiasCorrection{m}{3}{2}(xlat, ylon, pIndex) = cutoffs(pIndex);
                pIndex = pIndex+1;
            end
        end
    end
    
    % add cutoffs for each decade to mat structure
    for decade = 1:length(futureDecades)
        testBiasCorrection{m}{3+decade} = {futureDecades{decade}(1), decadeCutoffs{decade}};
    end
    clear testDist testData;
end

fileNewName = ['cmip5BiasCorrection_' testVar '_' region '_' futureRcp(1:end-1) '_tmp'];
fileName = ['cmip5BiasCorrection_' testVar '_' region '_' futureRcp(1:end-1)];
varName = ['cmip5BiasCorrection_' testVar '_' region];

if addToBC
    load([fileName '.mat']);
    eval(['bc = ' varName ';']);
    for i = 1:length(testBiasCorrection)
        bc{end+1} = testBiasCorrection{i};
    end
    eval([varName ' =  bc;']);
    save([fileNewName '.mat'], varName);
else
    eval([varName ' =  testBiasCorrection;']);
    save([fileNewName '.mat'], varName);
end


