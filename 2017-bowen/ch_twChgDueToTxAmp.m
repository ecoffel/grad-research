
useWb = false;
useWarmSeason = false;

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

calcTxHussRegressions = true;

% load(['2017-bowen/txx-timing/txx-months-era-1981-2016.mat']);
% txxMonthsHist = txxMonths;
% histTXx = [];
% if ~exist('histTXx', 'var')
%     % load era tmax and huss
%     eraHuss = loadDailyData('E:\data\era-interim\output\huss\regrid\world', 'startYear', 1981, 'endYear', 2016);
%     eraHuss = eraHuss{3};
%     eraTmax = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
%     eraTmax = eraTmax{3}-273.15;
% 
%     histTXx = [];
%     histTxWarmSeason = [];
%     histHussOnTXx = [];
%     histHussWarmSeason = [];
%     
%     histWb = [];
%     histTxOnWb = [];
%     histHussOnWb = [];
% 
%     histTDist = zeros(size(lat,1), size(lon,2), 11);
%     histTDist(histTDist == 0) = NaN;
%     histHDist = zeros(size(lat,1), size(lon,2), 11);
%     histHDist(histHDist == 0) = NaN;
%     
%     for xlat = 1:size(lat, 1)
%         for ylon = 1:size(lat, 2)
%             
%             curHDist = [];
%             curTDist = [];
%             
%             for year = 1:size(eraTmax, 3)
%                 t = eraTmax(xlat, ylon, year, :, :);
%                 t = reshape(t, [numel(t), 1]);
%                 indt = find(t == nanmax(t));
%                 
%                 h = eraHuss(xlat, ylon, year, :, :);
%                 h = reshape(h, [numel(h), 1]);
% 
%                 curHDist(:, year) = prctile(h, 0:10:100);
%                 curTDist(:, year) = prctile(t, 0:10:100);
%             end
% 
%             histTDist(xlat, ylon, :) = nanmean(curTDist, 2);
%             histHDist(xlat, ylon, :) = nanmean(curHDist, 2);            
%         end
%     end
% end
% 
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};
          

for m = 1:length(models)
    curModel = models{m};

    if exist(['E:/data/projects/bowen/temp-huss-regressions/temp-huss-regression-' curModel '-historical.mat'], 'file')
        load(['E:/data/projects/bowen/temp-huss-regressions/temp-huss-regression-' curModel '-historical.mat']);
        txHussIntercept(:, :, m) = regression{1};
        txHussSlope(:, :, m) = regression{2};
        txHussR2(:, :, m) = regression{3};
        continue;
    end

    load(['2017-bowen/txx-timing/txx-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;

    % temperature data (thresh, ann-max, or daily-max)
    baseSlope = [];
    baseIntercept = [];
    baseR2 = [];
    
    futSlope = [];
    futIntercept = [];
    futR2 = [];

    fprintf('loading base model %s...\n', curModel);

    baseTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2004);
    baseHuss = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/huss/regrid/world'], 'startYear', 1981, 'endYear', 2004);
    
    fprintf('loading future model %s...\n', curModel);
    futureTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    futureHuss = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/huss/regrid/world'], 'startYear', 2061, 'endYear', 2085);

    baseTx = baseTx{3};
    baseHuss = baseHuss{3};
    
    futureTx = futureTx{3};
    futureHuss = futureHuss{3};

    % if any kelvin values, convert to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(baseTx))))) > 100
        baseTx = baseTx - 273.15;
    end
    
    if nanmean(nanmean(nanmean(nanmean(nanmean(futureTx))))) > 100
        futureTx = futureTx - 273.15;
    end

    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(baseTx, 3)
        for j = 1:size(baseTx, 4)
            for k = 1:size(baseTx, 5)
                curGrid = baseTx(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseTx(:, :, i, j, k) = curGrid;

                curGrid = baseHuss(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseHuss(:, :, i, j, k) = curGrid;
            end
        end
    end
    
    for i = 1:size(futureTx, 3)
        for j = 1:size(futureTx, 4)
            for k = 1:size(futureTx, 5)
                curGrid = futureTx(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futureTx(:, :, i, j, k) = curGrid;

                curGrid = futureHuss(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futureHuss(:, :, i, j, k) = curGrid;
            end
        end
    end

    % calculate base period thresholds

    histTx = {};
    histHuss = {};
    histTw = {};

    fprintf('regressing...\n');
    % over x coords
    for xlat = 1:size(baseTx, 1)
        histTx{xlat} = {};
        histHuss{xlat} = {};
        histTw{xlat} = {};

        % over y coords
        for ylon = 1:size(baseTx, 2)
            histTx{xlat}{ylon} = {};
            histHuss{xlat}{ylon} = {};
            histTw{xlat}{ylon} = {};

            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsHist))) > 0 || waterGrid(xlat, ylon)
                baseSlope(xlat, ylon) = NaN;
                baseIntercept(xlat, ylon) = NaN;
                baseR2(xlat, ylon) = NaN;
                continue;
            end

            tx = squeeze(baseTx(xlat, ylon, :, curTxxMonthsHist, :));
            tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);

            huss = squeeze(baseHuss(xlat, ylon, :, curTxxMonthsHist, :));
            huss = reshape(huss, [size(huss,1)*size(huss,2)*size(huss,3), 1]);

            % compute historical wet bulb
            tw = [];
            for d = 1:length(tx)
                tw(d) = kopp_wetBulb(tx(d), 100200, huss(d));
            end

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

            for t = 1:length(thresh)
                ind = find(txPrc == t);
                histTx{xlat}{ylon}{t} = tx(ind);
                histHuss{xlat}{ylon}{t} = huss(ind);
                histTw{xlat}{ylon}{t} = tw(ind);
            end

            % skip if NaN (water)
            if length(find(~isnan(huss))) == 0 || length(find(~isnan(tx))) == 0
                baseSlope(xlat, ylon) = NaN;
                baseIntercept(xlat, ylon) = NaN;
                baseR2(xlat, ylon) = NaN;
                continue;
            end

            f = fitlm(tx, huss);
            baseSlope(xlat, ylon) = f.Coefficients.Estimate(2);
            baseIntercept(xlat, ylon) = f.Coefficients.Estimate(1);
            baseR2(xlat, ylon) = f.Rsquared.Ordinary;
            
            
            % -------------------------------------------------------------
            
            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsFut))) > 0 || waterGrid(xlat, ylon)
                futSlope(xlat, ylon) = NaN;
                futIntercept(xlat, ylon) = NaN;
                futR2(xlat, ylon) = NaN;
                continue;
            end

            tx = squeeze(futureTx(xlat, ylon, :, curTxxMonthsFut, :));
            tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);

            huss = squeeze(futureHuss(xlat, ylon, :, curTxxMonthsFut, :));
            huss = reshape(huss, [size(huss,1)*size(huss,2)*size(huss,3), 1]);

            % skip if NaN (water)
            if length(find(~isnan(huss))) == 0 || length(find(~isnan(tx))) == 0
                futSlope(xlat, ylon) = NaN;
                futIntercept(xlat, ylon) = NaN;
                futR2(xlat, ylon) = NaN;
                continue;
            end

            f = fitlm(tx, huss);
            futSlope(xlat, ylon) = f.Coefficients.Estimate(2);
            futIntercept(xlat, ylon) = f.Coefficients.Estimate(1);
            futR2(xlat, ylon) = f.Rsquared.Ordinary;

        end
    end

    regression = {baseIntercept, baseSlope, baseR2};
    save(['e:/data/projects/bowen/temp-huss-regressions/temp-huss-regression-' curModel '-historical.mat'], 'regression');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-tx-tx-deciles-' curModel '-historical.mat'], 'histTx');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-tw-tx-deciles-' curModel '-historical.mat'], 'histTw');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-huss-tx-deciles-' curModel '-historical.mat'], 'histHuss');
end




% load load future model and calc tx-induced huss for each future
% day
for m = 1:length(models)
    curModel = models{m};

    if exist(['e:/data/projects/bowen/temp-huss-regressions/tx-predicted-huss-future-' curModel '.mat'])
        continue;
    end
    
    load(['e:/data/projects/bowen/temp-huss-regressions/temp-huss-regression-' curModel '-historical.mat']);
    txHussIntercept = regression{1};
    txHussSlope = regression{2};
    
    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;

    fprintf('loading future model %s...\n', curModel);

    futTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    futTx = futTx{3};
    
    % if any kelvin values, convert to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(futTx))))) > 100
        futTx = futTx - 273.15;
    end
    
    % set water grid cells to NaN
    % include loops for month and day (5D) in case we are using
    % seasonal change metric
    for i = 1:size(futTx, 3)
        for j = 1:size(futTx, 4)
            for k = 1:size(futTx, 5)
                curGrid = futTx(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futTx(:, :, i, j, k) = curGrid;
            end
        end
    end

    % calculate base period thresholds

    txHussFut = {};
    twFut = {};
    fprintf('calculating future huss, tw...\n');
    % over x coords
    for xlat = 1:size(futTx, 1)
        txHussFut{xlat} = {};
        twFut{xlat} = {};
        % over y coords
        for ylon = 1:size(futTx, 2)
            twFut{xlat}{ylon} = {};
            txHussFut{xlat}{ylon} = {};
            
            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsFut))) > 0 || waterGrid(xlat, ylon)
                txHussFut{xlat}{ylon} = NaN;
                twFut{xlat}{ylon} = NaN;
                continue;
            end
            
            tx = squeeze(futTx(xlat, ylon, :, curTxxMonthsFut, :));
            tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);
            
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
            
            % predict future huss due to tx variation
            hussPred = txHussIntercept(xlat, ylon) + [(ones(size(tx)) .* txHussSlope(xlat, ylon)) .* tx];
            twPred = [];
            for d = 1:length(hussPred)
                 twPred(d) = kopp_wetBulb(tx(d), 100200, hussPred(d));
            end
            
            % group all days by tx decile
            for t = 1:10
                ind = find(txPrc == t);
                txHussFut{xlat}{ylon}{t} = hussPred(ind);
                twFut{xlat}{ylon}{t} = twPred(ind);
            end
        end
    end
    
    save(['e:/data/projects/bowen/temp-huss-regressions/tx-predicted-huss-future-' curModel '.mat'], 'txHussFut');
    save(['e:/data/projects/bowen/temp-huss-regressions/tx-predicted-tw-future-' curModel '.mat'], 'twFut');
    
end

% calc tx amplification
hussChgTxAmp = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
hussChgTxAmp(hussChgTxAmp == 0) = NaN;
hussChgNoTxAmp = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
hussChgNoTxAmp(hussChgNoTxAmp == 0) = NaN;
twChgTxAmp = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
twChgTxAmp(twChgTxAmp == 0) = NaN;
twChgNoTxAmp = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
twChgNoTxAmp(twChgNoTxAmp == 0) = NaN;

twFutDiff = [];
hussFutDiff = [];

fprintf('calculating tx amplification effects...\n');
for m = 1:length(models)
    curModel = models{m};
    load(['e:/data/projects/bowen/temp-huss-regressions/tx-predicted-huss-future-' curModel '.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/tx-predicted-tw-future-' curModel '.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-tx-tx-deciles-' curModel '-historical.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-tw-tx-deciles-' curModel '-historical.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-huss-tx-deciles-' curModel '-historical.mat']);
    
    for xlat = 1:length(histTx)
        for ylon = 1:length(histTx{xlat})
            for t = 1:10
                
                if length(txHussFut{xlat}{ylon})>1 && length(histHuss{xlat}{ylon})>1
                    hussChgTxAmp(xlat, ylon, t, m) = nanmean(txHussFut{xlat}{ylon}{t}) - nanmean(histHuss{xlat}{ylon}{t});
                    hussFutDiff(xlat, ylon, t, m) = nanmean(txHussFut{xlat}{ylon}{t});
                end
                
                if length(twFut{xlat}{ylon})>1 && length(histTw{xlat}{ylon})>1
                    twChgTxAmp(xlat, ylon, t, m) = nanmean(twFut{xlat}{ylon}{t}) - nanmean(histTw{xlat}{ylon}{t});
                    twFutDiff(xlat, ylon, t, m) = nanmean(twFut{xlat}{ylon}{t});
                end
                
                if t <= 5
                    if length(txHussFut{xlat}{ylon})>1 && length(histHuss{xlat}{ylon})>1
                        hussChgNoTxAmp(xlat, ylon, t, m) = nanmean(txHussFut{xlat}{ylon}{t}) - nanmean(histHuss{xlat}{ylon}{t});
                    end
                    
                    if length(twFut{xlat}{ylon})>1 && length(histTw{xlat}{ylon})>1
                        twChgNoTxAmp(xlat, ylon, t, m) = nanmean(twFut{xlat}{ylon}{t}) - nanmean(histTw{xlat}{ylon}{t});
                    end
                else
                    % remove tx amp by constraining future change to median
                    % change
                    if length(txHussFut{xlat}{ylon})>1 && length(histHuss{xlat}{ylon})>1
                        hussChgNoTxAmp(xlat, ylon, t, m) = nanmean(txHussFut{xlat}{ylon}{5}) - nanmean(histHuss{xlat}{ylon}{t});
                    end
                    
                    if length(twFut{xlat}{ylon})>1 && length(histTw{xlat}{ylon})>1
                        twChgNoTxAmp(xlat, ylon, t, m) = nanmean(twFut{xlat}{ylon}{5}) - nanmean(histTw{xlat}{ylon}{t});
                    end
                end
            end
        end
    end
        
     
end

for m = 1:length(models)
    
    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgHuss(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChg(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
end
data = (squeeze(nanmean(twChgTxAmp(:,:,5:10,:),3))-squeeze(twChgTxAmp(:,:,5,:)));

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
                  'colorbarArrow', 'both', ...
                  'statData', sigChg);
plotFromDataFile(saveData);
