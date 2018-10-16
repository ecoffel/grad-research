% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
          
% for wb/ef
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};
      
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};


baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';


% futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2005;

futurePeriodYears = 2061:2085;

% futurePeriods = [2070:2080];

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

load lat;
load lon;

var1 = 'tasmin';

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = [0 5:10:95 100];

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' baseDataset]
for m = 1:length(models)
    curModel = models{m};
    
%     load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' curModel '-historical-cmip5-1981-2005.mat']);
%     txxMonthsHist = txxMonths;
% 
%     load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' curModel '-future-cmip5-2061-2085.mat']);
%     txxMonthsFut = txxMonths;
    
    load(['E:\data\projects\snow\tnn-timing/tnn-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = tnnMonths;

    load(['E:\data\projects\snow\tnn-timing/tnn-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = tnnMonths;
    
%     if exist(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-thresh-range-100-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '-warm-season.mat'], 'file')
%         continue;
%     end
    
    % temperature data (thresh, ann-max, or daily-max)
    baseData = [];
   
    ['loading base model ' curModel '...']

    baseVar1Daily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' var1 '/regrid/' region], 'startYear', basePeriodYears(1), 'endYear', basePeriodYears(end));

    % remove lat/lon data (we loaded this earlier)
    baseVar1Daily = baseVar1Daily{3};

    % if any kelvin values, convert to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(baseVar1Daily))))) > 100
        baseVar1Daily = baseVar1Daily - 273.15;
    end
    
    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(baseVar1Daily, 3)
        for j = 1:size(baseVar1Daily, 4)
            for k = 1:size(baseVar1Daily, 5)
                curGrid = baseVar1Daily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseVar1Daily(:, :, i, j, k) = curGrid;
            end
        end
    end

    % calculate base period thresholds

    % over x coords
    for xlat = 1:size(baseVar1Daily, 1)
        % over y coords
        for ylon = 1:size(baseVar1Daily, 2)

            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsHist))) > 0 || waterGrid(xlat, ylon)
                baseData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            tmp = squeeze(baseVar1Daily(xlat, ylon, :, curTxxMonthsHist, :));
            tmp = reshape(tmp, [size(tmp,1)*size(tmp,2)*size(tmp,3), 1]);
            
            % skip if NaN (water)
            if length(find(~isnan(tmp))) == 0
                baseData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            for t = 1:length(thresh)
                baseData(xlat, ylon, t) = prctile(squeeze(tmp), thresh(t));
            end
        end
    end
    clear baseVar1Daily;
    
    % ------------ load future data -------------    

    ['loading future: ' futureDataset]

    curModel = models{m};

    futureData = [];
    chgData = [];

    ['loading future model ' curModel '...']

    futureVar1Daily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' var1 '/regrid/' region], 'startYear', futurePeriodYears(1), 'endYear', futurePeriodYears(end));
    futureVar1Daily = futureVar1Daily{3};
    
    % convert any kelvin values to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(futureVar1Daily))))) > 100
        futureVar1Daily = futureVar1Daily - 273.15;
    end
    
    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(futureVar1Daily, 3)
        for j = 1:size(futureVar1Daily, 4)
            for k = 1:size(futureVar1Daily, 5)
                curGrid = futureVar1Daily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futureVar1Daily(:, :, i, j, k) = curGrid;
            end
        end
    end

    % over x coords
    for xlat = 1:size(futureVar1Daily, 1)
        % over y coords
        for ylon = 1:size(futureVar1Daily, 2)

            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsFut))) > 0 || waterGrid(xlat, ylon)
                futureData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            tmp = squeeze(futureVar1Daily(xlat, ylon, :, curTxxMonthsFut, :));
            tmp = reshape(tmp, [size(tmp,1)*size(tmp,2)*size(tmp,3), 1]);

            % skip if NaN (water)
            if length(find(~isnan(tmp))) == 0
                futureData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            for t = 1:length(thresh)
                futureData(xlat, ylon, t) = prctile(squeeze(tmp), thresh(t));
            end
        end
    end
    clear futureVar1Daily;

    chgData = futureData - baseData;
    
    curChg = chgData;
    for t = 1:size(curChg,3)
        chgData = squeeze(curChg(:,:,t));
        save(['e:/data/projects/snow/chgData-cmip5-percentile-chg-' num2str(thresh(t)) '-' var1 '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');
    end
end

