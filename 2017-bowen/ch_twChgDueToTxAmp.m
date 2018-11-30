
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

    if exist(['E:/data/projects/bowen/temp-huss-regressions/temp-ef-huss-regression-' curModel '-historical.mat'], 'file')
        load(['E:/data/projects/bowen/temp-huss-regressions/temp-ef-huss-regression-' curModel '-historical.mat']);
        txHussIntercept(:, :, :, m) = regression{1};
        txHussSlope(:, :, :, m) = regression{2};
        efHussSlope(:, :, :, m) = regression{3};
        interceptSlope(:, :, :, m) = regression{4};
        txHussR2(:, :, :, m) = regression{5};
        continue;
    end

    load(['2017-bowen/txx-timing/txx-months-' curModel '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;

    % temperature data (thresh, ann-max, or daily-max)
    baseSlopeTxHuss = [];
    baseSlopeEfHuss = [];
    baseSlopeInteraction = [];
    baseIntercept = [];
    baseR2 = [];

    fprintf('loading base model %s...\n', curModel);

    baseTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2004);
    baseHuss = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/huss/regrid/world'], 'startYear', 1981, 'endYear', 2004);
    baseEf = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/ef/regrid/world'], 'startYear', 1981, 'endYear', 2004);
    
    baseTx = baseTx{3};
    baseHuss = baseHuss{3};
    baseEf = baseEf{3};
    
    % if any kelvin values, convert to C
    if nanmean(nanmean(nanmean(nanmean(nanmean(baseTx))))) > 100
        baseTx = baseTx - 273.15;
    end
    
    baseEf(baseEf < 0 | baseEf > 1) = NaN;
   
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
                
                curGrid = baseEf(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                baseEf(:, :, i, j, k) = curGrid;
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

            if length(find(isnan(curTxxMonthsHist))) > 0 || waterGrid(xlat, ylon) || xlat < 15 || xlat > 75
                baseSlopeTxHuss(xlat, ylon, 1:10) = NaN;
                baseSlopeEfHuss(xlat, ylon, 1:10) = NaN;
                baseSlopeInteraction(xlat, ylon, 1:10) = NaN;
                baseIntercept(xlat, ylon, 1:10) = NaN;
                baseR2(xlat, ylon, 1:10) = NaN;
                continue;
            end

            tx = squeeze(baseTx(xlat, ylon, :, curTxxMonthsHist, :));
            tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);

            huss = squeeze(baseHuss(xlat, ylon, :, curTxxMonthsHist, :));
            huss = reshape(huss, [size(huss,1)*size(huss,2)*size(huss,3), 1]);
            
            ef = squeeze(baseEf(xlat, ylon, :, curTxxMonthsHist, :));
            ef = reshape(ef, [size(ef,1)*size(ef,2)*size(ef,3), 1]);

            

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

            % compute historical wet bulb
            tw = [];
            for t = 1:10
                tw(t) = kopp_wetBulb(nanmean(tx(txPrc == t)), 100200, nanmean(huss(txPrc == t)));
            end
            
            for t = 1:length(thresh)
                ind = find(txPrc == t);
                histTx{xlat}{ylon}{t} = nanmean(tx(ind));
                histHuss{xlat}{ylon}{t} = nanmean(huss(ind));
                histTw{xlat}{ylon}{t} = tw(t);
            end

            % skip if NaN (water)
            if length(find(~isnan(huss))) == 0 || length(find(~isnan(tx))) == 0
                baseSlopeTxHuss(xlat, ylon, 1:10) = NaN;
                baseSlopeEfHuss(xlat, ylon, 1:10) = NaN;
                baseSlopeInteraction(xlat, ylon, 1:10) = NaN;
                baseIntercept(xlat, ylon, 1:10) = NaN;
                baseR2(xlat, ylon, 1:10) = NaN;
                continue;
            end

            for t = 1:length(thresh)
                ind = find(txPrc == t);
                if length(ind) > 50
                f = fitlm([tx(ind), ef(ind)], huss(ind), 'interactions');
                baseSlopeTxHuss(xlat, ylon, t) = f.Coefficients.Estimate(2);
                baseSlopeEfHuss(xlat, ylon, t) = f.Coefficients.Estimate(3);
                baseSlopeInteraction(xlat, ylon, t) = f.Coefficients.Estimate(4);
                baseIntercept(xlat, ylon, t) = f.Coefficients.Estimate(1);
                baseR2(xlat, ylon, t) = f.Rsquared.Ordinary;
                else
                    baseSlopeTxHuss(xlat, ylon, t) = NaN;
                    baseSlopeEfHuss(xlat, ylon, t) = NaN;
                    baseSlopeInteraction(xlat, ylon, t) = NaN;
                    baseIntercept(xlat, ylon, t) = NaN;
                    baseR2(xlat, ylon, t) = NaN;
                end
            end
            
            
        end
    end

    regression = {baseIntercept, baseSlopeTxHuss, baseSlopeEfHuss, baseSlopeInteraction, baseR2};
    save(['e:/data/projects/bowen/temp-huss-regressions/temp-ef-huss-regression-' curModel '-historical.mat'], 'regression');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-tx-tx-deciles-' curModel '-historical.mat'], 'histTx');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-tw-tx-deciles-' curModel '-historical.mat'], 'histTw');
    save(['e:/data/projects/bowen/temp-huss-regressions/hist-huss-tx-deciles-' curModel '-historical.mat'], 'histHuss');
end

% load load future model and calc tx-induced huss for each future
% day
for m = 1:length(models)
    curModel = models{m};

    if exist(['e:/data/projects/bowen/temp-huss-regressions/tx-ef-predicted-huss-future-' curModel '.mat'])
        continue;
    end
    
    load(['e:/data/projects/bowen/temp-huss-regressions/temp-ef-huss-regression-' curModel '-historical.mat']);
    baseIntercept = regression{1};
    baseSlopeTxHuss = regression{2};
    baseSlopeEfHuss = regression{3};
    baseSlopeInteraction = regression{4};
    
    load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;

    fprintf('loading future model %s...\n', curModel);

    futTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    futTx = futTx{3};
    
    futEf = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/ef/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    futEf = futEf{3};
    
    futEf(futEf < 0 | futEf > 1) = NaN;
    
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
                
                curGrid = futEf(:, :, i, j, k);
                curGrid(waterGrid) = NaN;
                futEf(:, :, i, j, k) = curGrid;
            end
        end
    end

    % calculate base period thresholds

    twDueToEf = zeros(size(lat,1), size(lat,2), 10);
    twDueToEf(twDueToEf == 0) = NaN;
    twDueToTx = zeros(size(lat,1), size(lat,2), 10);
    twDueToTx(twDueToTx == 0) = NaN;
    twTotal = zeros(size(lat,1), size(lat,2), 10);
    twTotal(twTotal == 0) = NaN;

    hussDueToEf = zeros(size(lat,1), size(lat,2), 10);
    hussDueToEf(hussDueToEf == 0) = NaN;
    hussDueToTx = zeros(size(lat,1), size(lat,2), 10);
    hussDueToTx(hussDueToTx == 0) = NaN;
    hussTotal = zeros(size(lat,1), size(lat,2), 10);
    hussTotal(hussTotal == 0) = NaN;
    
    fprintf('calculating future huss, tw...\n');
    % over x coords
    for xlat = 1:size(futTx, 1)

        % over y coords
        for ylon = 1:size(futTx, 2)
            
            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));

            if length(find(isnan(curTxxMonthsFut))) > 0 || waterGrid(xlat, ylon)
                twDueToEf(xlat, ylon, 1:10) = NaN;
                twDueToTx(xlat, ylon, 1:10) = NaN;
                twTotal(xlat, ylon, 1:10) = NaN;
                
                hussDueToEf(xlat, ylon, 1:10) = NaN;
                hussDueToTx(xlat, ylon, 1:10) = NaN;
                hussTotal(xlat, ylon, 1:10) = NaN;
                continue;
            end
            
            tx = squeeze(futTx(xlat, ylon, :, curTxxMonthsFut, :));
            tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);
            
            ef = squeeze(futEf(xlat, ylon, :, curTxxMonthsFut, :));
            ef = reshape(ef, [size(ef,1)*size(ef,2)*size(ef,3), 1]);
            
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
            for t = 1:10
                ind = find(txPrc == t);
                hussDueToTx(xlat, ylon, t) = nanmean(baseIntercept(xlat, ylon, t) + ...
                                            ([(ones(size(tx(ind))) .* baseSlopeTxHuss(xlat, ylon, t)) .* tx(ind)]) + ...
                                            ([(ones(size(tx(ind))) .* baseSlopeInteraction(xlat, ylon, t)) .* tx(ind) .* nanmean(ef(ind))]));
                hussDueToEf(xlat, ylon, t) = nanmean(baseIntercept(xlat, ylon, t) + ...
                                             ([(ones(size(ef(ind))) .* baseSlopeEfHuss(xlat, ylon, t)) .* ef(ind)]) + ...
                                             ([(ones(size(ef(ind))) .* baseSlopeInteraction(xlat, ylon, t)) .* ef(ind) .* nanmean(tx(ind))]));
                hussTotal(xlat, ylon, t) = nanmean(baseIntercept(xlat, ylon, t) + ...
                                           ([(ones(size(tx(ind))) .* baseSlopeTxHuss(xlat, ylon, t)) .* tx(ind)]) + ...
                                           ([(ones(size(ef(ind))) .* baseSlopeEfHuss(xlat, ylon, t)) .* ef(ind)]) + ...
                                           ([(ones(size(ef(ind))) .* baseSlopeInteraction(xlat, ylon, t)) .* ef(ind) .* tx(ind)]));
                twDueToTx(xlat, ylon, t) = kopp_wetBulb(nanmean(tx(ind)), 100200, hussDueToTx(xlat, ylon, t));
                twDueToEf(xlat, ylon, t) = kopp_wetBulb(nanmean(tx(ind)), 100200, hussDueToEf(xlat, ylon, t));
                twTotal(xlat, ylon, t) = kopp_wetBulb(nanmean(tx(ind)), 100200, hussTotal(xlat, ylon, t));
            
            end

        end
    end
    
    hussFut = {hussDueToTx, hussDueToEf, hussTotal};
    twFut = {twDueToTx, twDueToEf, twTotal};
    save(['e:/data/projects/bowen/temp-huss-regressions/tx-ef-predicted-huss-future-' curModel '.mat'], 'hussFut');
    save(['e:/data/projects/bowen/temp-huss-regressions/tx-ef-predicted-tw-future-' curModel '.mat'], 'twFut');
    
end

% calc tx amplification
hussChgTx = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
hussChgTx(hussChgTx == 0) = NaN;
hussChgEf = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
hussChgEf(hussChgEf == 0) = NaN;
hussChgTotal = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
hussChgTotal(hussChgTotal == 0) = NaN;

twChgTx = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
twChgTx(twChgTx == 0) = NaN;
twChgEf = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
twChgEf(twChgEf == 0) = NaN;
twChgTotal = zeros([size(lat, 1), size(lat, 2), 10, length(models)]);
twChgTotal(twChgTotal == 0) = NaN;

futHussModel = [];
futHussReg = [];
threshChgHuss = [];
fprintf('calculating tx amplification effects...\n');
for m = 1:length(models)
    curModel = models{m};
    load(['e:/data/projects/bowen/temp-huss-regressions/tx-ef-predicted-huss-future-' curModel '.mat']);
    
%     futHuss = loadDailyData(['e:/data/cmip5/output/access1-0/r1i1p1/rcp85/huss/regrid/world'], 'startYear', 2061, 'endYear', 2085);
%     futHussModel(:,:,m) = nanmean(nanmean(nanmean(futHuss{3},5),4),3);
%     
    hussDueToTx = hussFut{1};
    hussDueToEf = hussFut{2};
    hussTotal = hussFut{3};
    
    futHussReg(:,:,:,m) = hussTotal;
    
    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgHuss(:, :, tind, m) = chgData;
        tind=tind+1;
    end
    
    load(['e:/data/projects/bowen/temp-huss-regressions/tx-ef-predicted-tw-future-' curModel '.mat']);
    twDueToTx = twFut{1};
    twDueToEf = twFut{2};
    twTotal = twFut{3};
    
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-tx-tx-deciles-' curModel '-historical.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-tw-tx-deciles-' curModel '-historical.mat']);
    load(['e:/data/projects/bowen/temp-huss-regressions/hist-huss-tx-deciles-' curModel '-historical.mat']);
    
    for xlat = 1:length(histTx)
        for ylon = 1:length(histTx{xlat})
            for t = 1:10
                
                if length(histHuss{xlat}{ylon}) == 10
                    hussChgTx(xlat, ylon, t, m) = hussDueToTx(xlat, ylon, t) - nanmean(histHuss{xlat}{ylon}{t});
                    hussChgEf(xlat, ylon, t, m) = hussDueToEf(xlat, ylon, t) - nanmean(histHuss{xlat}{ylon}{t});
                    hussChgTotal(xlat, ylon, t, m) = hussTotal(xlat, ylon, t) - nanmean(histHuss{xlat}{ylon}{t});
                end
                
                if length(histTw{xlat}{ylon}) == 10
                    twChgTx(xlat, ylon, t, m) = twDueToTx(xlat, ylon, t) - nanmean(histTw{xlat}{ylon}{t});
                    twChgEf(xlat, ylon, t, m) = twDueToEf(xlat, ylon, t) - nanmean(histTw{xlat}{ylon}{t});
                    twChgTotal(xlat, ylon, t, m) = twTotal(xlat, ylon, t) - nanmean(histTw{xlat}{ylon}{t});
                end
                
            end
        end
    end
        
     
end


        
        
data = 1000.*(squeeze(nanmean(hussChgTotal(:,:,5:10,:),3))-squeeze(hussChgTotal(:,:,5,:)));

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
                  'plotRange', [-2 2], ...
                  'cbXTicks', -2:.5:2, ...
                  'plotTitle', [], ...
                  'fileTitle', ['huss-chg-due-to-tx-amp-reg-total-decile.eps'], ...
                  'plotXUnits', ['Change (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'BrBG'), ...
                  'colorbarArrow', 'both', ...
                  'statData', sigChg);
plotFromDataFile(saveData);






