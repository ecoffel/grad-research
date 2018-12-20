models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

twChgDueToHuss = [];
twChgDueToTx = [];
twChgDueToBoth = [];

load lat;
load lon;
load waterGrid.mat;
waterGrid = logical(waterGrid);

regenData = true;

for m = 1:length(models)
    curModel = models{m};
    
    
%     load(['E:\data\projects\bowen\temp-chg-data\baseTxDecile-' curModel '.mat']);
%     load(['E:\data\projects\bowen\temp-chg-data\baseHussDecile-' curModel '.mat']);
%     load(['E:\data\projects\bowen\temp-chg-data\futureTxDecile-' curModel '.mat']);
%     load(['E:\data\projects\bowen\temp-chg-data\futureHussDecile-' curModel '.mat']);

    if regenData
        baseHussDecile = [];
        baseTxDecile = [];
        futureHussDecile = [];
        futureTxDecile = [];

        load(['2017-bowen/txx-timing/txx-months-' curModel '-historical-cmip5-1981-2005.mat']);
        txxMonthsHist = txxMonths;

        load(['2017-bowen/txx-timing/txx-months-' curModel '-future-cmip5-2061-2085.mat']);
        txxMonthsFut = txxMonths;

        fprintf('loading base tx/huss for %s...\n', models{m});
        baseTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1981, 'endYear', 2004);
        baseHuss = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/historical/huss/regrid/world'], 'startYear', 1981, 'endYear', 2004);

        baseTx = baseTx{3};
        baseHuss = baseHuss{3};

        fprintf('loading future tx/huss for %s...\n', models{m});
        futureTx = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2061, 'endYear', 2085);
        futureHuss = loadDailyData(['e:/data/cmip5/output/' curModel '/r1i1p1/rcp85/huss/regrid/world'], 'startYear', 2061, 'endYear', 2085);

        futureTx = futureTx{3};
        futureHuss = futureHuss{3};

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

    end
    
    fprintf('computing tw for %s...\n', curModel);
    % over x coords
    for xlat = 1:size(lat, 1)
        % over y coords
        for ylon = 1:size(lat, 2)

            if regenData
                curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
                curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));
            end
            
            if  waterGrid(xlat, ylon) || xlat < 15 || xlat > 75
                twChgDueToHuss(xlat, ylon, 1:10, m) = NaN;
                twChgDueToTx(xlat, ylon, 1:10, m) = NaN;
                twChgDueToBoth(xlat, ylon, 1:10, m) = NaN;
                
                if regenData
                    futureHussDecile(xlat, ylon, 1:size(baseTx, 3), 1:10) = NaN;
                    futureTxDecile(xlat, ylon, 1:size(baseTx, 3), 1:10) = NaN;
                    baseHussDecile(xlat, ylon, 1:size(baseTx, 3), 1:10) = NaN;
                    baseTxDecile(xlat, ylon, 1:size(baseTx, 3), 1:10) = NaN;
                end
                continue;
            end

            if regenData
                for year = 1:size(baseTx, 3)
                    tx = squeeze(baseTx(xlat, ylon, year, curTxxMonthsHist, :));
                    tx = reshape(tx, [size(tx,1)*size(tx,2)*size(tx,3), 1]);

                    huss = squeeze(baseHuss(xlat, ylon, year, curTxxMonthsHist, :));
                    huss = reshape(huss, [size(huss,1)*size(huss,2)*size(huss,3), 1]);

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


                    txFut = squeeze(futureTx(xlat, ylon, year, curTxxMonthsFut, :));
                    txFut = reshape(txFut, [size(txFut,1)*size(txFut,2)*size(txFut,3), 1]);

                    hussFut = squeeze(futureHuss(xlat, ylon, year, curTxxMonthsFut, :));
                    hussFut = reshape(hussFut, [size(hussFut,1)*size(hussFut,2)*size(hussFut,3), 1]);

                    thresh = 5:10:95;
                    txFutPrc = prctile(squeeze(txFut), thresh);

                    tmpFutPrcMatch = [];
                    for t = 1:length(thresh)
                        tmpFutPrcMatch(:,t) = txFut-txFutPrc(t);
                    end

                    txFutPrc = [];
                    for d = 1:size(tmpFutPrcMatch,1)
                        ind = find(abs(tmpFutPrcMatch(d,:)) == min(abs(tmpFutPrcMatch(d,:))));
                        if length(ind) > 0
                            txFutPrc(d) = ind(1);
                        else
                            txFutPrc(d) = NaN;
                        end
                    end
                
                    for t = 1:10
                        if regenData
                            baseTxDecile(xlat, ylon, year, t) = nanmean(tx(txPrc == t));
                            baseHussDecile(xlat, ylon, year, t) = nanmean(huss(txPrc == t));
                            futureTxDecile(xlat, ylon, year, t) = nanmean(txFut(txFutPrc == t));
                            futureHussDecile(xlat, ylon, year, t) = nanmean(hussFut(txFutPrc == t));
                        end

                    end
                end

                for t = 1:10
                    twChgDueToTx(xlat, ylon, t, m) = kopp_wetBulb(squeeze(nanmean(futureTxDecile(xlat, ylon, :, t), 3)), 100200, squeeze(nanmean(futureHussDecile(xlat, ylon, :, 5), 3))) - ...
                                                     kopp_wetBulb(squeeze(nanmean(baseTxDecile(xlat, ylon, :, t), 3)), 100200, squeeze(nanmean(baseHussDecile(xlat, ylon, :, t), 3)));

                    twChgDueToHuss(xlat, ylon, t, m) = kopp_wetBulb(squeeze(nanmean(baseTxDecile(xlat, ylon, :, 5), 3)), 100200, squeeze(nanmean(futureHussDecile(xlat, ylon, :, t), 3))) - ...
                                                     kopp_wetBulb(squeeze(nanmean(baseTxDecile(xlat, ylon, :, t), 3)), 100200, squeeze(nanmean(baseHussDecile(xlat, ylon, :, t), 3)));

                    twChgDueToBoth(xlat, ylon, t, m) = kopp_wetBulb(squeeze(nanmean(futureTxDecile(xlat, ylon, :, t), 3)), 100200, squeeze(nanmean(futureHussDecile(xlat, ylon, :, t), 3))) - ...
                                                     kopp_wetBulb(squeeze(nanmean(baseTxDecile(xlat, ylon, :, t), 3)), 100200, squeeze(nanmean(baseHussDecile(xlat, ylon, :, t), 3)));
                end
            end
        end
    end
    
    baseTxDecile = squeeze(nanmean(baseTxDecile, 3));
    baseHussDecile = squeeze(nanmean(baseHussDecile, 3));
    futureTxDecile = squeeze(nanmean(futureTxDecile, 3));
    baseHussDecile = squeeze(nanmean(futureHussDecile, 3));
    
    if regenData
        save(['E:\data\projects\bowen\temp-chg-data\baseTxDecile-' curModel '.mat'], 'baseTxDecile');
        save(['E:\data\projects\bowen\temp-chg-data\baseHussDecile-' curModel '.mat'], 'baseHussDecile');
        save(['E:\data\projects\bowen\temp-chg-data\futureTxDecile-' curModel '.mat'], 'futureTxDecile');
        save(['E:\data\projects\bowen\temp-chg-data\futureHussDecile-' curModel '.mat'], 'futureHussDecile');
    end
end

save(['E:\data\projects\bowen\temp-chg-data\twChgDueToTx.mat'], 'twChgDueToTx');
save(['E:\data\projects\bowen\temp-chg-data\twChgDueToHuss.mat'], 'twChgDueToHuss');
save(['E:\data\projects\bowen\temp-chg-data\twChgDueToBoth.mat'], 'twChgDueToBoth');

load(['E:\data\projects\bowen\temp-chg-data\twChgDueToTx.mat']);
load(['E:\data\projects\bowen\temp-chg-data\twChgDueToHuss.mat']);
load(['E:\data\projects\bowen\temp-chg-data\twChgDueToBoth.mat']);


data = (squeeze(nanmean(twChgDueToHuss(:,:,5:10,:),3))-squeeze(twChgDueToHuss(:,:,5,:)));
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
                  'fileTitle', ['tw-chg-due-to-huss-decomp.eps'], ...
                  'plotXUnits', ['Change (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'colorbarArrow', 'both', ...
                  'statData', sigChg);
plotFromDataFile(saveData);