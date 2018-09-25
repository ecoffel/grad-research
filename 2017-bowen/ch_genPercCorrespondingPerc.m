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

var1 = 'wb-davies-jones-full';
var2 = 'tasmax';

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = 5:10:95;

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
    
    if exist(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-percentile-percentile-95-' var1 '-' var2 '-' curModel '-historical-' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end)) '.mat'], 'file')
        continue;
    end
    
    % temperature data (thresh, ann-max, or daily-max)
    baseData = [];
   
    ['loading base model ' curModel '...']

    baseVar1Daily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' var1 '/regrid/' region], 'startYear', basePeriodYears(1), 'endYear', basePeriodYears(end));
    baseVar2Daily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' var2 '/regrid/' region], 'startYear', basePeriodYears(1), 'endYear', basePeriodYears(end));

    % remove lat/lon data (we loaded this earlier)
    baseVar1Daily = baseVar1Daily{3};
    baseVar2Daily = baseVar2Daily{3};

    % if any kelvin values, convert to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(baseVar1Daily))))) > 100
        baseVar1Daily = baseVar1Daily - 273.15;
    end
    
    if nanmean(nanmean(nanmean(nanmean(nanmean(baseVar2Daily))))) > 100
        baseVar2Daily = baseVar2Daily - 273.15;
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
                
                curGrid = baseVar2Daily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseVar2Daily(:, :, i, j, k) = curGrid;
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
            
            tmpVar2 = squeeze(baseVar2Daily(xlat, ylon, :, curTxxMonthsHist, :));
            tmpVar2 = reshape(tmpVar2, [size(tmpVar2,1)*size(tmpVar2,2)*size(tmpVar2,3), 1]);

            % skip if NaN (water)
            if length(find(~isnan(tmpVar2))) == 0 || length(find(~isnan(tmp))) == 0
                baseData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            prc = prctile(squeeze(tmp), thresh);
            
            tmpMatch = [];
            
            for t = 1:length(thresh)
                tmpMatch(:,t) = tmp-prc(t);
            end
            
            prcInd = [];
            
            for d = 1:size(tmpMatch,1)
                ind = find(abs(tmpMatch(d,:)) == min(abs(tmpMatch(d,:))));
                if length(ind) > 0
                    prcInd(d) = ind(1);
                else
                    prcInd(d) = NaN;
                end
            end
            
            
            
            
            
            prc2 = prctile(squeeze(tmpVar2), thresh);
            
            tmpMatch = [];
            
            for t = 1:length(thresh)
                tmpMatch(:,t) = tmpVar2-prc2(t);
            end
            
            prc2Ind = [];
            
            for d = 1:size(tmpMatch,1)
                ind = find(abs(tmpMatch(d,:)) == min(abs(tmpMatch(d,:))));
                if length(ind) > 0
                    prc2Ind(d) = ind(1);
                else
                    prc2Ind(d) = NaN;
                end
            end
            
            
            for t = 1:length(thresh)
                baseData(xlat, ylon, t) = mode(prc2Ind(find(prcInd==t)));
            end
        end
    end
    clear baseVar1Daily baseVar2Daily;
    
    % ------------ load future data -------------    

    ['loading future: ' futureDataset]

    curModel = models{m};

    futureData = [];
    chgData = [];

    ['loading future model ' curModel '...']

    futureVar1Daily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' var1 '/regrid/' region], 'startYear', futurePeriodYears(1), 'endYear', futurePeriodYears(end));
    futureVar1Daily = futureVar1Daily{3};
    
    futureVar2Daily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' var2 '/regrid/' region], 'startYear', futurePeriodYears(1), 'endYear', futurePeriodYears(end));
    futureVar2Daily = futureVar2Daily{3};

    % convert any kelvin values to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(futureVar1Daily))))) > 100
        futureVar1Daily = futureVar1Daily - 273.15;
    end
    if nanmean(nanmean(nanmean(nanmean(nanmean(futureVar2Daily))))) > 100
        futureVar2Daily = futureVar2Daily - 273.15;
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
                
                curGrid = futureVar2Daily(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futureVar2Daily(:, :, i, j, k) = curGrid;
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
            
            tmpVar2 = squeeze(futureVar2Daily(xlat, ylon, :, curTxxMonthsFut, :));
            tmpVar2 = reshape(tmpVar2, [size(tmpVar2,1)*size(tmpVar2,2)*size(tmpVar2,3), 1]);

            % skip if NaN (water)
            if length(find(~isnan(tmpVar2))) == 0 || length(find(~isnan(tmp))) == 0
                futureData(xlat, ylon, 1:length(thresh)) = NaN;
                continue;
            end
            
            prc = prctile(squeeze(tmp), thresh);
            
            tmpMatch = [];
            
            for t = 1:length(thresh)
                tmpMatch(:,t) = tmp-prc(t);
            end
            
            prcInd = [];
            
            for d = 1:size(tmpMatch,1)
                ind = find(abs(tmpMatch(d,:)) == min(abs(tmpMatch(d,:))));
                if length(ind) > 0
                    prcInd(d) = ind(1);
                else
                    prcInd(d) = NaN;
                end
            end
            
            
            
            
            prc2 = prctile(squeeze(tmpVar2), thresh);
            
            tmpMatch = [];
            
            for t = 1:length(thresh)
                tmpMatch(:,t) = tmpVar2-prc2(t);
            end
            
            prc2Ind = [];
            
            for d = 1:size(tmpMatch,1)
                ind = find(abs(tmpMatch(d,:)) == min(abs(tmpMatch(d,:))));
                if length(ind) > 0
                    prc2Ind(d) = ind(1);
                else
                    prc2Ind(d) = NaN;
                end
            end
            
            
            for t = 1:length(thresh)
                futureData(xlat, ylon, t) = mode(prc2Ind(find(prcInd==t)));
            end
        end
    end
    clear futureVar1Daily futureVar2Daily;

    for t = 1:size(baseData,3)
        save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-percentile-percentile-' num2str(thresh(t)) '-' var1 '-' var2 '-' curModel '-historical-' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end)) '.mat'], 'baseData');
        save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-percentile-percentile-' num2str(thresh(t)) '-' var1 '-' var2 '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'futureData');
    end
end

