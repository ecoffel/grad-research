
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

load lat;
load lon;


% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = 5:10:95;

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

absThreshRange = 35:40;
tw = false;

var1 = 'tasmax';
if tw
    var2 = 'wb-davies-jones-full';
else
    var2 = 'tasmax';
end

% load era
if ~exist('tEra')
    fprintf('loading era...\n');
    if tw
        tEra = loadDailyData('e:/data/era-interim/output/wb-davies-jones-full/regrid/world', 'startYear', 1981, 'endYear', 2005);
    else
        tEra = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', 1981, 'endYear', 2005);
    end
    tEra = tEra{3};
    if nanmean(nanmean(nanmean(nanmean(nanmean(tEra))))) > 100
        tEra = tEra - 273.15;
    end
    twEraNoWat = [];
    for y = 1:size(tEra, 3)
        for m = 1:size(tEra, 4)
            for d = 1:size(tEra, 5)
               curGrid = tEra(:, :, y, m, d);
               curGrid(waterGrid) = NaN;
               curGrid(1:15,:) = NaN;
               curGrid(75:90,:) = NaN;
               twEraNoWat(:, :, y, m, d) = curGrid;
            end
        end
    end
    
    eraThreshPerc = [];
    
    for xlat = 1:size(twEraNoWat, 1)
        for ylon = 1:size(twEraNoWat, 2)
            c = reshape(twEraNoWat(xlat, ylon, :, :, :), [numel(twEraNoWat(xlat, ylon, :, :, :)),1]);
            prcs = prctile(c, 75:100);

            for a = 1:length(absThreshRange)
                absThresh = absThreshRange(a);
                prc = find(abs(prcs-absThresh)==min(abs(prcs-absThresh)));
                if length(prc) == 0 || abs(prcs(prc)-absThresh) > 5
                    eraThreshPerc(xlat, ylon, a) = NaN;
                    continue;
                end
                eraThreshPerc(xlat, ylon, a) = prc+75-1;
            end
        end
    end
end


['loading base: ' baseDataset]
for m = 1:length(models)
    curModel = models{m};
    
    load(['2017-bowen/txx-timing/txx-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    
    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChg(:, :, tind) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        txChg(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
    
    if tw
        tChg = twChg;
    else
        tChg = txChg;
    end
    
    if exist(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-tx-count-chg-no-tx-amp-95-' num2str(absThreshRange(end)) '-' var1 '-' var2 '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'file')
        continue;
    end
    
    % temperature data (thresh, ann-max, or daily-max)
    baseData = [];
    futureDataNoTxAmp = [];
    futureDataTxAmp = [];
   
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

    twThresh = [];
    
    % over x coords
    for xlat = 1:size(baseVar1Daily, 1)
        % over y coords
        for ylon = 1:size(baseVar1Daily, 2)

            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsHist))) > 0 || waterGrid(xlat, ylon)
                baseData(xlat, ylon, 1:length(thresh)) = NaN;
                futureDataNoTxAmp(xlat, ylon, 1:length(thresh), 1:length(absThreshRange)) = NaN;
                futureDataTxAmp(xlat, ylon, 1:length(thresh), 1:length(absThreshRange)) = NaN;
                twThresh(xlat, ylon) = NaN;
                continue;
            end
            
            tmp = squeeze(baseVar1Daily(xlat, ylon, :, curTxxMonthsHist, :));
            tmp = reshape(tmp, [size(tmp,1)*size(tmp,2)*size(tmp,3), 1]);
            
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
            
            
            tmpVar2 = squeeze(baseVar2Daily(xlat, ylon, :, curTxxMonthsHist, :));
            tmpVar2 = reshape(tmpVar2, [size(tmpVar2,1)*size(tmpVar2,2)*size(tmpVar2,3), 1]);
            
            for a = 1:length(absThreshRange)
                twThresh(xlat, ylon, a) = prctile(tmpVar2, eraThreshPerc(xlat, ylon, a));
                if isnan(eraThreshPerc(xlat, ylon, a))
                    twThresh(xlat, ylon, a) = NaN;
                end

                % skip if NaN (water)
                if length(find(~isnan(tmpVar2))) == 0 || length(find(~isnan(tmp))) == 0
                    baseData(xlat, ylon, 1:length(thresh), a) = NaN;
                    futureDataNoTxAmp(xlat, ylon, 1:length(thresh), a) = NaN;
                    futureDataTxAmp(xlat, ylon, 1:length(thresh), a) = NaN;
                    continue;
                end

                % now loop through tmpVar2 and compute change with appropriate
                % decile change value
                tmpVar2FutureTxAmp = [];
                tmpVar2FutureNoTxAmp = [];
                for i = 1:length(tmpVar2)
                    chgInd = prcInd(i);

                    if isnan(chgInd)
                        tmpVar2FutureTxAmp(i) = NaN;
                        continue;
                    end
                    chgVal = tChg(xlat, ylon, chgInd);
                    tmpVar2FutureTxAmp(i) = tmpVar2(i) + chgVal;

                    % elimnate tx amp
                    if chgInd > 5
                        chgInd = 5;
                    end

                    chgVal = tChg(xlat, ylon, chgInd);
                    tmpVar2FutureNoTxAmp(i) = tmpVar2(i) + chgVal;
                end

                for t = 1:length(thresh)
                    baseData(xlat, ylon, t, a) = length(find(tmpVar2(find(prcInd==t)) > twThresh(xlat, ylon, a))) / size(baseVar2Daily, 3);
                    futureDataNoTxAmp(xlat, ylon, t, a) = length(find(tmpVar2FutureNoTxAmp(find(prcInd==t)) > twThresh(xlat, ylon, a))) / size(baseVar2Daily, 3);
                    futureDataTxAmp(xlat, ylon, t, a) = length(find(tmpVar2FutureTxAmp(find(prcInd==t)) > twThresh(xlat, ylon, a))) / size(baseVar2Daily, 3);
                end
            end
        end
    end
    %clear baseVar1Daily baseVar2Daily;
    
    chgDataNoTxAmp = futureDataNoTxAmp - baseData;
    chgDataTxAmp = futureDataTxAmp - baseData;
    
    for t = 1:size(chgDataTxAmp,3)
        for a = 1:length(absThreshRange)
            chgData = squeeze(chgDataNoTxAmp(:,:,t,a));
            save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-tx-count-chg-no-tx-amp-' num2str(thresh(t)) '-' num2str(absThreshRange(a)) '-' var1 '-' var2 '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');

            chgData = squeeze(chgDataTxAmp(:,:,t,a));
            save(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-tx-count-chg-tx-amp-' num2str(thresh(t)) '-' num2str(absThreshRange(a)) '-' var1 '-' var2 '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');
        end
    end
end

