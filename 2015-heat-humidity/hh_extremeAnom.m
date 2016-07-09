% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'future';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

baseModels = {'csiro-mk3-6-0'};
testModels = {'csiro-mk3-6-0'};
% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
% testModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'tasmax';
testVar = '';

baseRegrid = true;
testRegrid = true;

region = 'world';
rcp = 'rcp45';
ensembles = 1:10;

plotRegion = 'world';

plotEachModel = true;

plotTitle = ['CMIP5 annual maximum wet-bulb'];

basePeriodYears = 1985:2004;
testPeriodYears = 2050:2070;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportFormat = 'png';

blockWater = true;
baseBiasCorrect = true;
testBiasCorrect = true;

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
    findMax = true;
    months = [12 1 2];
    maxMinStr = 'maximum';
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

if strcmp(baseVar, 'wb')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 10];
    else
        plotRange = [0 35];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'rh')
    plotRange = [0 100];
    plotXUnits = '%';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 10];
    else
        plotRange = [-40 40];
    end
    plotXUnits = 'degrees C';
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/';
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = [rcp '/'];
end

if strcmp(testPeriod, 'past')
    testPeriod = basePeriodYears;
    testRcp = 'historical/';
elseif strcmp(testPeriod, 'future')
    testPeriod = testPeriodYears;
    testRcp = [rcp '/'];
end

baseExt = {};
futureExt = {};

for e = ensembles

    testDatasetStr = testDataset;
    if ~strcmp(testVar, '')
        if strcmp(testDatasetStr, 'cmip5')
            if length(testModels) == 1
                testDatasetStr = ['cmip5-' testModels{1}];
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
        elseif strcmp(testDatasetStr, 'narr')
            testDatasetStr = ['narr'];
            testDataDir = 'narr/output';
            testEnsemble = '';
            testRcp = '';
        end

    end

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

    fileTimeStr = '';
    if ~strcmp(testVar, '')
        fileTimeStr = [testDatasetStr testBcStr '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDatasetStr '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
    else
        fileTimeStr = [testBcStr '-' season '-' maxMinFileStr '-' baseDatasetStr '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
    end

    fileTitle = ['extremeAnom-' baseVar '-' rcp '-' fileTimeStr];

    baseExt{e} = {};
    futureExt{e} = {};
    
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

            if ~strcmp(baseVar, 'rh') && baseDaily{3}(1,1,1,1,1) > 100
                baseDaily{3} = baseDaily{3} - 273.15;
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

    if ~strcmp(testVar, '')
        for m = 1:length(testModels)
            if strcmp(testModels{m}, '')
                curModel = testModels{m};
            else
                curModel = [testModels{m} '/'];
            end

            futureExt{e}{m} = {};

            ['loading ' curModel ' future']
            for y = testPeriod(1):yearStep:testPeriod(end)
                ['year ' num2str(y) '...']
                % load daily data, for cmip5
                if testRegrid
                    testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/' region testBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                else
                    testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                end

                % for ncep
                %testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

                % for narr
                %testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

                if ~strcmp(testVar, 'rh') && testDaily{3}(1,1,1,1,1) > 100
                    testDaily{3} = testDaily{3} - 273.15;
                end

                if annualmean
                    testDailyExtTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
                else
                    testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);
                end

                futureExt{e}{m} = {futureExt{e}{m}{:}, testDailyExtTmp{:}};
                clear testDaily testDailyExtTmp;
            end
        end
    end
end

['done loading...']

if plotEachModel
    modelAvg = [];
    baseAvg = [];

    % average over ensembles, models, and years
    for e = 1:length(baseExt)
        for m = 1:length(baseExt{e})
            for y = 1:length(baseExt{e}{m})
                baseAvg(:,:,e,m,y) = baseExt{e}{m}{y}{3};
            end
        end
    end
    
    baseAvg = nanmean(baseAvg, 5);
    
    if ~strcmp(testVar, '')
        for e = 1:length(futureExt)
            for m = 1:length(futureExt{e})
                for y = 1:length(futureExt{e}{m})
                    modelAvg(:,:,e,m,y) = futureExt{e}{m}{y}{3};
                end
            end
        end
        
        % average over years
        modelAvg = nanmean(modelAvg, 5);

        % ensembles
        for e = ensembles
            % models
            for i = 1:size(modelAvg, 4)
                curBaseAvg = {baseExt{1}{1}{1}{1}, baseExt{1}{1}{1}{2}, baseAvg(:, :, e, i)};
                curModelAvg = {futureExt{1}{1}{1}{1}, futureExt{1}{1}{1}{2}, modelAvg(:, :, e, i)};

                if strcmp(baseDataset, 'ncep') && strcmp(testDataset, 'narr')
                    curBaseAvg{2} = curBaseAvg{2}-360;
                    curModelAvg{3} = curModelAvg{3}-273.15;
                end

                % regrid the base data if needed
                if size(curBaseAvg{3}) ~= size(curModelAvg{3})
                    baseExtAvgRegrid = regridGriddata(curBaseAvg, curModelAvg);
                else
                    baseExtAvgRegrid = curBaseAvg;
                end

                xdim = 1:min(size(curModelAvg{3}, 1), size(baseExtAvgRegrid{3}, 1));
                ydim = 1:min(size(curModelAvg{3}, 2), size(baseExtAvgRegrid{3}, 2));
                result = {curModelAvg{1}, curModelAvg{2}, curModelAvg{3}(xdim, ydim)-baseExtAvgRegrid{3}(xdim, ydim)};

                % fix this to work with ensembles
                saveData = struct('data', {result}, ...
                                  'plotRegion', plotRegion, ...
                                  'plotRange', plotRange, ...
                                  'plotTitle', [plotTitle ' (' baseModels{i} '), (r' num2str(e) 'i1p1)'], ...
                                  'fileTitle', [fileTitle '-r' num2str(e) 'i1p1-' baseModels{i} '.' exportFormat], ...
                                  'plotXUnits', plotXUnits, ...
                                  'plotCountries', false, ...
                                  'plotStates', true, ...
                                  'blockWater', blockWater);

                plotFromDataFile(saveData);
            end
        end
    else
        for e = 1:size(baseAvg, 3)
            for i = 1:size(baseAvg, 4)
                curBaseAvg = {baseExt{1}{1}{1}{1}, baseExt{1}{1}{1}{2}, baseAvg(:, :, e, i)};
                result = curBaseAvg;

                % also fix this to work with ensembles
                saveData = struct('data', {result}, ...
                                  'plotRegion', plotRegion, ...
                                  'plotRange', plotRange, ...
                                  'plotTitle', [plotTitle ' (' baseModels{i} '), (r' num2str(e) 'i1p1)'] , ...
                                  'fileTitle', [fileTitle '-r' num2str(e) 'i1p1-' baseModels{i} '.' exportFormat], ...
                                  'plotXUnits', plotXUnits, ...
                                  'plotCountries', false, ...
                                  'plotStates', true, ...
                                  'blockWater', blockWater);

                plotFromDataFile(saveData);
            end
        end
    end
else
    modelAvg = [];
    baseAvg = [];

    % average over ensembles and models and years
    for e = 1:length(baseExt)
        for m = 1:length(baseExt{e})
            for y = 1:length(baseExt{e}{m})
                baseAvg(:,:,e,m,y) = baseExt{e}{m}{y}{3};
            end
        end
    end

    % construct plotable structures
    baseAvg = {baseExt{1}{1}{1}{1}, baseExt{1}{1}{1}{2}, squeeze(nanmean(nanmean(nanmean(baseAvg, 5), 4), 3))};

    if ~strcmp(testVar, '')
        for e = 1:length(futureExt)
            for m = 1:length(futureExt{e})
                for y = 1:length(futureExt{e}{m})
                    modelAvg(:,:,e,m,y) = futureExt{e}{m}{y}{3};
                end
            end
        end
        modelAvg = {futureExt{1}{1}{1}{1}, futureExt{1}{1}{1}{2}, nanmean(nanmean(nanmean(modelAvg, 5), 4), 3)};

        if strcmp(baseDataset, 'ncep') && strcmp(testDataset, 'narr')
            baseAvg{2} = baseAvg{2}-360;
            modelAvg{3} = modelAvg{3}-273.15;
        end

        % regrid the base data if needed
        if size(baseAvg{3}) ~= size(modelAvg{3})
            baseExtAvgRegrid = regridGriddata(baseAvg, modelAvg);
        else
            baseExtAvgRegrid = baseAvg;
        end

        xdim = 1:min(size(modelAvg{3}, 1), size(baseExtAvgRegrid{3}, 1));
        ydim = 1:min(size(modelAvg{3}, 2), size(baseExtAvgRegrid{3}, 2));
        result = {modelAvg{1}, modelAvg{2}, modelAvg{3}(xdim, ydim)-baseExtAvgRegrid{3}(xdim, ydim)};
    else
        result = baseAvg;
    end

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

