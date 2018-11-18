
useWb = false;
useWarmSeason = false;

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

load(['2017-bowen/txx-timing/txx-months-era-1981-2016.mat']);
txxMonthsHist = txxMonths;

if ~exist('eraTxHist', 'var')
    eraTxHist = [];
    eraHussHist = [];
    
    % load era tmax and huss
    eraHuss = loadDailyData('E:\data\era-interim\output\huss\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraHuss = eraHuss{3};
    eraTmax = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraTmax = eraTmax{3}-273.15;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                eraTxHist(xlat, ylon, 1:10) = NaN;
                eraHussHist(xlat, ylon, 1:10) = NaN;
                continue;
            end

            eraMonths = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            
            tx = eraTmax(xlat, ylon, :, :, :);
            tx = reshape(tx, [numel(tx), 1]);
            
            thresh = 5:10:95;
            txPrc = prctile(squeeze(tx), thresh);

            tmpPrcMatch = [];
            for t = 1:length(thresh)
                tmpPrcMatch(:,t) = tx-txPrc(t);
            end

            txPrc = [];
            for d = 1:size(tmpPrcMatch,1)
                ind = find(abs(tmpPrcMatch(d,:)) == min(abs(tmpPrcMatch(d,:))));
                if length(ind) > 0
                    txPrc(d) = ind(1);
                else
                    txPrc(d) = NaN;
                end
            end

            huss = eraHuss(xlat, ylon, :, :, :);
            huss = reshape(huss, [numel(huss), 1]);
            
            for t = 1:length(thresh)
                eraTxHist(xlat, ylon, t) = nanmean(tx(txPrc == t));
                eraHussHist(xlat, ylon, t) = nanmean(huss(txPrc == t));
            end
        end
    end
end


models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};


for m = 1:length(models)
    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgHuss(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
end

rind = 1;
efind = 1;
dmodels = {};
dslopes = [];
dslopesP = [];

dchg = [];

for m = 1:length(models)

   curFits = {};
    
   for t = 1:10
        curFits{t} = {};
   
        load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
        
        a = squeeze(threshChgHuss(:,:,t,m));
        a(waterGrid) = NaN;
        a(1:15,:) = NaN;
        a(75:90,:) = NaN;
        a = reshape(a, [numel(a),1]);

        driver = squeeze(threshChgTx(:,:,t,m));
        driver(waterGrid) = NaN;
        driver(1:15,:) = NaN;
        driver(75:90,:) = NaN;
        driver = reshape(driver, [numel(driver),1]);

        efGroup(waterGrid) = NaN;
        efGroup(1:15,:) = NaN;
        efGroup(75:90,:) = NaN;
        efGroup =  reshape(efGroup, [numel(efGroup),1]);

        nn = find(isnan(a) | isnan(driver));

        driver(nn) = [];
        aDriver = a;
        aDriver(nn) = [];

        efGroup(nn) = [];

        for e = 1:5
            % all ef vals
            if e == 5
                nn = 1:length(driver);
            else
                % others
                nn = find(efGroup == e);
            end

            curDriver = driver(nn);
            curADriver = aDriver(nn);

            dchg(e, t, m) = nanmean(curADriver);

            f = fitlm(curDriver, curADriver, 'linear');
            dslopes(e, t, m) = f.Coefficients.Estimate(2);
            dslopesP(e, t, m) = f.Coefficients.pValue(2); 

            curFits{t}{e} = {f};
        end
        dmodels{m} = curFits;
    end
end


hchgDueToTxAmp = [];
twChgDueToTxAmp = [];

for m = 1:length(dmodels)
    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
    threshChgTx = [];

    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind) = chgData;
        tind = tind+1;
    end
    
	for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            curGroup = efGroup(xlat, ylon);
            if ylon == 1
                curGroup = round(mean([efGroup(xlat,end) efGroup(xlat,2)]));
            end
            
            if waterGrid(xlat, ylon) || isnan(curGroup) || xlat < 15 || xlat > 75
                hchgDueToTxAmp(xlat, ylon, 1:10, m) = NaN;
                twChgDueToTxAmp(xlat, ylon, 1:10, m) = NaN;
                continue;
            end
            
            for t = 1:10
                histTx = eraTxHist(xlat, ylon, t);
                histHuss = eraHussHist(xlat, ylon, t);
                
                hchgDueToTxAmp(xlat, ylon, t, m) = predict(dmodels{m}{t}{curGroup}{1}, threshChgTx(xlat, ylon, t));
                twChgDueToTxAmp(xlat, ylon, t, m) = kopp_wetBulb(histTx + threshChgTx(xlat, ylon, t), 100200, histHuss + hchgDueToTxAmp(xlat, ylon, t, m)) - ...
                                                    kopp_wetBulb(histTx, 100200, histHuss);
            end
            
        end
    end
end

data = (squeeze(nanmean(twChgDueToTxAmp(:,:,5:10,:),3))-squeeze(twChgDueToTxAmp(:,:,5,:)));
plotData = [];
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            plotData(xlat, ylon) = NaN;
            sigChg(xlat, ylon) = 0;
            continue;
        end
        med = nanmedian(data(xlat, ylon, :), 3);
        if ~isnan(med)
            plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);
            sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(plotData(xlat, ylon)))) < .66*size(data, 3);
        else
            sigChg(xlat, ylon) = 1;
        end
    end
end

sigChg(1:15,:) = 0;
sigChg(75:90,:) = 0;
plotData(1:15,:) = NaN;
plotData(75:90,:) = NaN;

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:.25:1, ...
                  'plotTitle', [], ...
                  'fileTitle', ['tw-chg-due-to-tx-amp.eps'], ...
                  'plotXUnits', ['Change (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'colorbarArrow', 'left', ...
                  'statData', sigChg);
plotFromDataFile(saveData);