
useWb = false;
useWarmSeason = false;

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

load(['2017-bowen/txx-timing/txx-months-era-1981-2016.mat']);
txxMonthsHist = txxMonths;

if ~exist('histTXx', 'var')
    % load era tmax and huss
    eraHuss = loadDailyData('E:\data\era-interim\output\huss\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraHuss = eraHuss{3};
    eraTmax = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraTmax = eraTmax{3}-273.15;
    
    histTXx = [];
    histTxWarmSeason = [];
    histHussOnTXx = [];
    histHussWarmSeason = [];
    
    histWb = [];
    histTxOnWb = [];
    histHussOnWb = [];

    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                histTXx(xlat, ylon) = NaN;
                histTxWarmSeason(xlat, ylon) = NaN;
                histWb(xlat, ylon) = NaN;
                histHussOnWb(xlat, ylon) = NaN;
                histTxOnWb(xlat, ylon) = NaN;
                histHussOnTXx(xlat, ylon) = NaN;
                histHussWarmSeason(xlat, ylon) = NaN;
                continue;
            end

            mxt = [];
            meant = [];
            mxh = [];
            meanh = [];
            
            % max wb
            mxwb = [];
            % max t and h on wb day
            mxwbt = [];
            mxwbh = [];

            eraMonths = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            
            for year = 1:size(eraTmax, 3)
                t = eraTmax(xlat, ylon, year, :, :);
                t = reshape(t, [numel(t), 1]);
                indt = find(t == nanmax(t));
                
                h = eraHuss(xlat, ylon, :, :, :);
                h = reshape(h, [numel(h), 1]);

                mxt(year) = t(indt(1));
                mxh(year) = h(indt(1));
                
                meant(year) = squeeze(nanmean(nanmean(eraTmax(xlat, ylon, year, eraMonths, :), 5), 4));
                meanh(year) = squeeze(nanmean(nanmean(eraHuss(xlat, ylon, year, eraMonths, :), 5), 4));
            end

            histTXx(xlat, ylon) = nanmean(mxt);
            histHussOnTXx(xlat, ylon) = nanmean(mxh);
            histTxWarmSeason(xlat, ylon) = nanmean(meant);
            histHussWarmSeason(xlat, ylon) = nanmean(meanh);
            
        end
    end
end


models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};


for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxChg-' models{m}]);
    txxChgOnTxx(:, :, m) = txxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    wbOnTxx(:,:,m) = wbTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    hussOnTxx(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    efOnTxx(:,:,m) = efTxxChg;
    efOnTxx(:,1,m) = (efOnTxx(:,end,m)+efOnTxx(:,2,m)) ./ 2;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
    efOnWb(:,1,m) = (efOnWb(:,end,m)+efOnWb(:,2,m)) ./ 2;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efWarmChg-movingWarm-' models{m}]);
    efChgWarmSeason(:, :, m) = efWarmChg;
    efChgWarmSeason(:,1,m) = (efChgWarmSeason(:,end,m)+efChgWarmSeason(:,2,m)) ./ 2;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\hussWarmChg-movingWarm-' models{m}]);
    hussChgWarmSeason(:, :, m) = hussWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
end


amp = hussChgWarmSeason;
driverRaw = txChgWarmSeason;

rind = 1;
efind = 1;
dmodels = {};
dslopes = [];
dslopesP = [];

dchg = [];

for m = 1:length(models)

   curFits = {};
    
   load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);

    a = squeeze(amp(:,:,m));
    a(waterGrid) = NaN;
    a(1:15,:) = NaN;
    a(75:90,:) = NaN;
    a = reshape(a, [numel(a),1]);

    driver = squeeze(driverRaw(:,:,m));
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
        
        dchg(1, e, m) = nanmean(curADriver);

        f = fitlm(curDriver, curADriver, 'linear');
        dslopes(1, e, m) = f.Coefficients.Estimate(2);
        dslopesP(1, e, m) = f.Coefficients.pValue(2); 
        
        curFits{e} = {f};
        
        dmodels{m} = curFits;

    end

end


hchgDueToMedT = [];
twchgMedT_predHuss = [];
twchgMedT_fullHuss = [];

for m = 1:length(dmodels)
    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
    threshChgTx = [];

    tind = 1;
    for t = 0:10:100
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
            if waterGrid(xlat, ylon) || isnan(curGroup)
                twchgMedT_predHuss(xlat, ylon) = NaN;
                twchgMedT_fullHuss(xlat, ylon) = NaN;
                hchgDueToMedT(xlat, ylon) = NaN;
                continue;
            end
            
            curHistTxx = histTxWarmSeason;
            curHistHuss = histHussWarmSeason;
            txxChg = txChgWarmSeason;
            hussChg = hussChgWarmSeason;

            hchgDueToMedT(xlat, ylon) = predict(dmodels{m}{curGroup}{1}, threshChgTx(xlat, ylon, 6));
            
            % using ef-chg predicted t/h chg
            twchgMedT_predHuss(xlat, ylon) = kopp_wetBulb(curHistTxx(xlat, ylon) + threshChgTx(xlat, ylon, 6), 100200, curHistHuss(xlat, ylon) + hchgDueToMedT(xlat, ylon)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgMedT_fullHuss(xlat, ylon) = kopp_wetBulb(curHistTxx(xlat, ylon) + threshChgTx(xlat, ylon, 6), 100200, curHistHuss(xlat, ylon) + hussChg(xlat, ylon,m)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
        end
    end
    
    save(['E:\data\projects\bowen\temp-chg-data\chgData-tw-med-temp-pred-huss-' models{m} '-rcp85-2061-2085.mat'], 'twchgMedT_predHuss');
    save(['E:\data\projects\bowen\temp-chg-data\chgData-tw-med-temp-full-huss-' models{m} '-rcp85-2061-2085.mat'], 'twchgMedT_fullHuss');
end
