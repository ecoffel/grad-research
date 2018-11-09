% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';

excludeTropics = false;

hottestSeasonType = 'all-txx';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
% for wb/ef
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};


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

baseVar = 'huss';
futureVar = 'huss';

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = 0:5:100;

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' baseDataset]
for m = 1:length(models)
    curModel = models{m};
    
    load(['2017-bowen/txx-timing/txx-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    
    if exist(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-thresh-range-100-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '-warm-season.mat'], 'file')
        continue;
    end
    
    % temperature data (thresh, ann-max, or daily-max)
    baseData = [];
   
    ['loading base model ' curModel '...']

    baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'startYear', basePeriodYears(1), 'endYear', basePeriodYears(end));

    % remove lat/lon data (we loaded this earlier)
    baseDaily = baseDaily{3};

    % if any kelvin values, convert to C
%     if nanmean(nanmean(nanmean(nanmean(nanmean(baseDaily))))) > 100
%         baseDaily = baseDaily - 273.15;
%     end

    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(baseDaily, 3)
        for j = 1:size(baseDaily, 4)
            for k = 1:size(baseDaily, 5)
                curGrid = baseDaily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseDaily(:, :, i, j, k) = curGrid;
            end
        end
    end

    % calculate base period thresholds

    % loop over all thresholds
    for t = 1:length(thresh)
        % over x coords
        for xlat = 1:size(baseDaily, 1)
            % over y coords
            for ylon = 1:size(baseDaily, 2)

                curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
                
                % skip if NaN (water)
                if length(find(isnan(curTxxMonthsHist))) > 0
                    baseData(xlat, ylon, t) = NaN;
                    continue;
                end

                tmp = squeeze(baseDaily(xlat, ylon, :, curTxxMonthsHist, :));
                tmp = reshape(tmp, [size(tmp,1)*size(tmp,2)*size(tmp,3), 1]);
                
                % calculate threshold at current (x,y) and
                % percentile 
                baseData(xlat, ylon, t) = prctile(squeeze(tmp), thresh(t));
            end
        end
    end
    clear baseDaily;
    
    % ------------ load future data -------------    

    ['loading future: ' futureDataset]

    curModel = models{m};

    futureData = [];
    chgData = [];

    ['loading future model ' curModel '...']

    futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'startYear', futurePeriodYears(1), 'endYear', futurePeriodYears(end));
    futureDaily = futureDaily{3};

    % convert any kelvin values to C
%     if nanmean(nanmean(nanmean(nanmean(nanmean(futureDaily))))) > 100
%         futureDaily = futureDaily - 273.15;
%     end

    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(futureDaily, 3)
        for j = 1:size(futureDaily, 4)
            for k = 1:size(futureDaily, 5)
                curGrid = futureDaily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futureDaily(:, :, i, j, k) = curGrid;
            end
        end
    end


    % loop over thresholds
    for t = 1:length(thresh)
        % latitude
        for xlat = 1:size(futureDaily, 1)
            % longitude
            for ylon = 1:size(futureDaily, 2)

                curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));
                
                % skip if NaN (water)
                if length(find(isnan(curTxxMonthsFut))) > 0
                    futureData(xlat, ylon, t) = NaN;
                    continue;
                end

                tmp = squeeze(futureDaily(xlat, ylon, :, curTxxMonthsFut, :));
                tmp = reshape(tmp, [size(tmp,1)*size(tmp,2)*size(tmp,3), 1]);
                
                % calculate threshold at current (x,y) and
                % percentile 
                futureData(xlat, ylon, t) = prctile(squeeze(tmp), thresh(t));
            end
        end
    end

    chgData = futureData - baseData;
    
    clear futureDaily;

    curChg = chgData;
    for t = 1:size(curChg,3)
        chgData = squeeze(curChg(:,:,t));
        save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-thresh-range-' num2str(thresh(t)) '-' baseVar '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '-warm-season.mat'], 'chgData');
    end
end

