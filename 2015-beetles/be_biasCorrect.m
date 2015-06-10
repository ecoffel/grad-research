% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'cmip5';
testDataset = 'cmip5';

baseModels = {'ccsm4', 'cesm1-bgc', ...
          'gfdl-cm3', 'mpi-esm-mr', ...
          'gfdl-esm2m', 'gfdl-esm2g', ...
          'canesm2', 'noresm1-m', ...
          'hadgem2-es', 'cesm1-cam5', ...
          'cmcc-cm', 'cmcc-cms', ...    
          'cnrm-cm5', 'ipsl-cm5a-mr', ...
          'bnu-esm', 'miroc-esm', ...
          'mri-cgcm3'};

ncepVar = 'tmin';
cmip5Var = 'tasmin';

percentiles = 10:10:100;

baseRegrid = true;

basePeriodYears = 1985:2004;

baseDir = 'e:/data/';
yearStep = 1;

basePeriod = basePeriodYears;
baseRcp = 'historical/';
baseDataDir = 'cmip5/output';
ensemble = 'r1i1p1/';

ncepData = {};

% load sample cmip5 grid
baseGridMonthly = loadMonthlyData('E:\data\cmip5\output\bnu-esm\r1i1p1\historical\tasmax\regrid', 'tasmax', 'yearStart', 1981, 'yearEnd', 1981);
baseGrid = {baseGridMonthly{1}{1}{1}, baseGridMonthly{1}{1}{2}, []};
clear baseGridMonthly;

% first load ncep reananlysis
['loading ncep base']
for y = basePeriod(1):yearStep:basePeriod(end)
    ['year ' num2str(y) '...']
    
    baseDaily = loadDailyData(['e:/data/ncep-reanalysis/output/' ncepVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
    baseDaily{3} = baseDaily{3}-273.15;
    baseDaily{3} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

    ncepData = {ncepData{:} baseDaily{3}};
    clear baseDaily;
end

ncepDist = {};
ncepMeans = [];

for xlat = 1:size(ncepData{1}, 1)
    if size(ncepDist, 1) < xlat
        ncepDist{xlat} = {};
    end
    
    for ylon = 1:size(ncepData{1}, 2)
        ncepDist{xlat}{ylon} = [];
        for n = 1:length(ncepData)
            ncepDist{xlat}{ylon} = [ncepDist{xlat}{ylon}(:); squeeze(ncepData{n}(xlat, ylon, :))];
        end
        pIndex = 1;
        cutoffs = [];
        for p = percentiles
            % store cuttoffs so we take mean between each percentile
            cutoffs(pIndex) = prctile(ncepDist{xlat}{ylon}, p);
            if pIndex == 1
                ncepMeans(xlat, ylon, pIndex) = nanmean(ncepDist{xlat}{ylon}(ncepDist{xlat}{ylon}(:) < cutoffs(pIndex)));
            else
                ncepMeans(xlat, ylon, pIndex) = nanmean(ncepDist{xlat}{ylon}(ncepDist{xlat}{ylon}(:) < cutoffs(pIndex) & ncepDist{xlat}{ylon}(:) > cutoffs(pIndex-1)));
            end
            pIndex = pIndex+1;
        end
    end
end

clear ncepDist ncepData;

cmip5Corr = [];
cmip5BiasCorrection = {};
    
for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    cmip5Data = {};
    cmip5BiasCorrection{m} = {baseModels{m}, []};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        
        baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp cmip5Var '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        baseDaily{3} = baseDaily{3}-273.15;
        baseDaily{3} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
        cmip5Data = {cmip5Data{:} baseDaily{3}};
        clear baseDaily;
    end
    
    cmip5Dist = {};

    for xlat = 1:size(cmip5Data{1}, 1)
        if size(cmip5Dist, 1) < xlat
            cmip5Dist{xlat} = {};
        end

        for ylon = 1:size(cmip5Data{1}, 2)
            cmip5Dist{xlat}{ylon} = [];
            for n = 1:length(cmip5Data)
                cmip5Dist{xlat}{ylon} = [cmip5Dist{xlat}{ylon}(:); squeeze(cmip5Data{n}(xlat, ylon, :))];
            end
            pIndex = 1;
            cutoffs = [];
            for p = percentiles
                % store cuttoffs so we take mean between each percentile
                cutoffs(pIndex) = prctile(cmip5Dist{xlat}{ylon}, p);
                if pIndex == 1
                    curMean = nanmean(cmip5Dist{xlat}{ylon}(cmip5Dist{xlat}{ylon}(:) < cutoffs(pIndex)));
                else
                    curMean = nanmean(cmip5Dist{xlat}{ylon}(cmip5Dist{xlat}{ylon}(:) < cutoffs(pIndex) & cmip5Dist{xlat}{ylon}(:) > cutoffs(pIndex-1)));
                end
                cmip5BiasCorrection{m}{2}(xlat, ylon, pIndex) = curMean - ncepMeans(xlat, ylon, pIndex);
                pIndex = pIndex+1;
            end
        end
    end
    clear cmip5Dist cmip5Data;
end

save cmip5BiasCorrection;



