
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
    eraWb = loadDailyData('E:\data\era-interim\output\wb-davies-jones-full\regrid\world', 'startYear', 1981, 'endYear', 2016);
    eraWb = eraWb{3};
    
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
                
                wb = eraWb(xlat, ylon, year, :, :);
                wb = reshape(wb, [numel(wb), 1]);
                indwb = find(wb == nanmax(wb));

                h = eraHuss(xlat, ylon, :, :, :);
                h = reshape(h, [numel(h), 1]);

                mxt(year) = t(indt(1));
                mxh(year) = h(indt(1));
                
                if length(indwb) > 0
                    mxwb(year) = wb(indwb(1));
                    mxwbt(year) = t(indwb(1));
                    mxwbh(year) = h(indwb(1));
                else
                    mxwb(year) = NaN;
                    mxwbt(year) = NaN;
                    mxwbh(year) = NaN;
                end
                
                meant(year) = squeeze(nanmean(nanmean(eraTmax(xlat, ylon, year, eraMonths, :), 5), 4));
                meanh(year) = squeeze(nanmean(nanmean(eraHuss(xlat, ylon, year, eraMonths, :), 5), 4));
            end

            histTXx(xlat, ylon) = nanmean(mxt);
            histHussOnTXx(xlat, ylon) = nanmean(mxh);
            histTxWarmSeason(xlat, ylon) = nanmean(meant);
            histHussWarmSeason(xlat, ylon) = nanmean(meanh);
            
            histWb(xlat, ylon) = nanmean(mxwb);
            histHussOnWb(xlat, ylon) = nanmean(mxwbh);
            histTxOnWb(xlat, ylon) = nanmean(mxwbt);
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

efOnTxx(abs(efOnTxx)>1) = NaN;
efOnWb(abs(efOnWb)>1) = NaN;



if useWb
    amp = txxOnWb;
    driverRaw = efOnWb;

    amp2 = hussOnWb;
    driverRaw2 = efOnWb;
else
    amp = txxChgOnTxx;
    driverRaw = efOnTxx;

    amp2 = hussOnTxx;
    driverRaw2 = efOnTxx;
end

unit = 'unit EF';

twchgT_warming = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgT_warming(twchgT_warming==0) = NaN;
twchgH_warming = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgH_warming(twchgH_warming==0) = NaN;
twchgTot_warming = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgTot_warming(twchgTot_warming==0) = NaN;

for m = 1:length(dmodels)
    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
	for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            curGroup = efGroup(xlat, ylon);
            if waterGrid(xlat, ylon) || isnan(curGroup) || isnan(efOnWb(xlat, ylon, m))
                continue;
            end
            
            curHistTxx = histTxWarmSeason;
            curHistHuss = histHussWarmSeason;
            txxChg = txChgWarmSeason;
            hussChg = hussChgWarmSeason;

            % using total model projected t/h chg
            twchgT_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + txxChg(xlat, ylon, m), 100200, curHistHuss(xlat, ylon)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgH_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon) + hussChg(xlat, ylon, m)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgTot_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + txxChg(xlat, ylon, m), 100200, curHistHuss(xlat, ylon) + hussChg(xlat, ylon, m))-kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));

        end
    end
    
    twchgTPer_warming(:,:,m) = twchgT_warming(:,:,m) ./ twchgTot_warming(:,:,m);
    twchgHPer_warming(:,:,m) = twchgH_warming(:,:,m) ./ twchgTot_warming(:,:,m);
end

