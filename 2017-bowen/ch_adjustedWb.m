
useMaxWbDay = true;

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
    histTx = [];
    histHussOnTXx = [];
    histHussOnTx = [];
    
    histWb = [];
    histTxOnWb = [];
    histHussOnWb = [];

    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                histTXx(xlat, ylon) = NaN;
                histTx(xlat, ylon) = NaN;
                histWb(xlat, ylon) = NaN;
                histHussOnWb(xlat, ylon) = NaN;
                histTxOnWb(xlat, ylon) = NaN;
                histHussOnTXx(xlat, ylon) = NaN;
                histHussOnTx(xlat, ylon) = NaN;
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
            histTx(xlat, ylon) = nanmean(meant);
            histHussOnTx(xlat, ylon) = nanmean(meanh);
            
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
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
end

efOnTxx(abs(efOnTxx)>1) = NaN;

if useMaxWbDay
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
    
    if length(amp2) > 0
        a2 = squeeze(amp2(:,:,m));
        a2(waterGrid) = NaN;
        a2(1:15,:) = NaN;
        a2(75:90,:) = NaN;
        a2 = reshape(a2, [numel(a2),1]);

        driver2 = squeeze(driverRaw2(:,:,m));
        driver2(waterGrid) = NaN;
        driver2(1:15,:) = NaN;
        driver2(75:90,:) = NaN;
        driver2 = reshape(driver2, [numel(driver2),1]);
    end

    efGroup(waterGrid) = NaN;
    efGroup(1:15,:) = NaN;
    efGroup(75:90,:) = NaN;
    efGroup =  reshape(efGroup, [numel(efGroup),1]);

    if length(amp2) > 0
        nn = find(isnan(a) | isnan(driver) | isnan(a2) | isnan(driver2));
        driver2(nn) = [];
        aDriver2 = a2;
        aDriver2(nn) = [];
    else
        nn = find(isnan(a) | isnan(driver));
    end

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
        
        if length(amp2) > 0
            curDriver2 = driver2(nn);
            curADriver2 = aDriver2(nn);

            dchg(2, e, m) = nanmean(curADriver2);

            f2 = fitlm(curDriver2, curADriver2, 'linear');
            dslopes(2, e, m) = f2.Coefficients.Estimate(2);
            dslopesP(2, e, m) = f2.Coefficients.pValue(2);
            
            curFits{e}{2} = f2;
            
            f3 = fitlm(curADriver2, curADriver, 'linear');
            dslopes(3, e, m) = f3.Coefficients.Estimate(2);
            dslopesP(3, e, m) = f3.Coefficients.pValue(2);
            
            curFits{e}{3} = f3;
        end
        
        dmodels{m} = curFits;

    end

end

tchgDueToEf = [];
hchgDueToEf = [];
twchg = [];
    
efChgs = -.3:.1:.3;
tChgs = 0:10;
hChgs = 0:.25e-3:3e-3;

baseH = .005;
baseT = 33;

twchgT_efchg = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgT_efchg(twchgT_efchg==0) = NaN;
twchgH_efchg = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgH_efchg(twchgH_efchg==0) = NaN;
twchgTot_efchg = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgTot_efchg(twchgTot_efchg==0) = NaN;

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
            
            if useMaxWbDay
                efChg = efOnWb;
                curHistTxx = histTxOnWb;
                curHistHuss = histHussOnWb;
                txxChg = txxOnWb;
                hussChg = hussOnWb;
            else
                efChg = efOnTxx;
                curHistTxx = histTXx;
                curHistHuss = histHussOnTXx;
                txxChg = txxChgOnTxx;
                hussChg = hussOnTxx;
            end
            
            tchgDueToEf = predict(dmodels{m}{curGroup}{1}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{1}, 0);
            hchgDueToEf = predict(dmodels{m}{curGroup}{2}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{2}, 0);
            % using ef-chg predicted t/h chg
            twchgT_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + tchgDueToEf, 100200, curHistHuss(xlat, ylon)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgH_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon) + hchgDueToEf) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgTot_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + tchgDueToEf, 100200, curHistHuss(xlat, ylon) + hchgDueToEf)-kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
%             
            % using total model projected t/h chg
            twchgT_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + txxChg(xlat, ylon, m), 100200, curHistHuss(xlat, ylon)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgH_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon) + hussChg(xlat, ylon, m)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgTot_warming(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + txxChg(xlat, ylon, m), 100200, curHistHuss(xlat, ylon) + hussChg(xlat, ylon, m))-kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));

        end
    end
    
    twchgTPer_efchg(:,:,m) = twchgT_efchg(:,:,m) ./ twchgTot_efchg(:,:,m);
    twchgHPer_efchg(:,:,m) = twchgH_efchg(:,:,m) ./ twchgTot_efchg(:,:,m);
    
    twchgTPer_warming(:,:,m) = twchgT_warming(:,:,m) ./ twchgTot_warming(:,:,m);
    twchgHPer_warming(:,:,m) = twchgH_warming(:,:,m) ./ twchgTot_warming(:,:,m);
end

result = {lat, lon, 100 .* nanmedian(twchgTPer_warming, 3)};

agreement = zeros(size(lat));
sig = zeros(size(lat));
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        for m = 1:size(twchgTPer_warming, 3)
            if twchgTPer_warming(xlat, ylon, m) >= .5
                agreement(xlat, ylon) = agreement(xlat, ylon) + 1;
            else
                agreement(xlat, ylon) = agreement(xlat, ylon) - 1;
            end
        end
    end
end

sig = double(~(abs(agreement) > 0));
sig(1:15,:) = 0;
sig(75:90,:) = 0;

if useMaxWbDay
    title = 'T_W chg on T_W day: contribution from T chg';
    file = 'wb-on-wb-contrib-warming.eps';
else
    title = 'T_W chg on TXx day: contribution from T chg';
    file = 'wb-on-txx-contrib-warming.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [25 75], ...
                  'cbXTicks', 25:5:75, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', ['%'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdYlGn'), ...
                  'statData', sig);
plotFromDataFile(saveData);





result = {lat, lon, nanmedian(twchgT_efchg, 3)};

if useMaxWbDay
    title = 'T_W chg due to EF-induced T chg: T_W day';
    file = 'tw-chg-ef-ind-t-chg-on-wb.eps';
else
    title = 'T_W chg due to EF-induced T chg: TXx day';
    file = 'tw-chg-ef-ind-t-chg-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'));
plotFromDataFile(saveData);

result = {lat, lon, nanmedian(twchgT_warming, 3)};

if useMaxWbDay
    title = 'T_W chg due to warming-induced T chg: T_W day'
    file = 'tw-chg-warming-ind-t-chg-on-wb.eps';
else
    title = 'T_W chg due to warming-induced T chg: TXx day';
    file = 'tw-chg-warming-ind-t-chg-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 4], ...
                  'cbXTicks', 0:.5:4, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));
plotFromDataFile(saveData);



result = {lat, lon, nanmedian(twchgH_efchg, 3)};

if useMaxWbDay
    title = 'T_W chg due to EF-induced H chg: T_W day';
    file = 'tw-chg-due-to-ef-ind-h-chg-on-wb.eps';
else
    title = 'T_W chg due to EF-induced H chg: TXx day';
    file = 'tw-chg-due-to-ef-ind-h-chg-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'));
plotFromDataFile(saveData);

result = {lat, lon, nanmedian(twchgH_warming, 3)};

if useMaxWbDay
    title = 'T_W chg due to warming-induced H chg: T_W day';
    file = 'tw-chg-warming-ind-h-chg-on-wb.eps';
else
    title = 'T_W chg due to warming-induced H chg: TXx day';
    file = 'tw-chg-warming-ind-h-chg-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 4], ...
                  'cbXTicks', 0:.5:4, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));
plotFromDataFile(saveData);



result = {lat, lon, nanmedian(twchgTot_efchg, 3)};

if useMaxWbDay
    title = 'T_W chg due to EF chg: T_W day';
    file = 'tw-chg-due-to-ef-chg-on-wb.eps';
else
    title = 'T_W chg due to EF chg: TXx day';
    file = 'tw-chg-due-to-ef-chg-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'));
plotFromDataFile(saveData);

result = {lat, lon, nanmedian(twchgTot_warming, 3)};

if useMaxWbDay
    title = 'T_W chg due to warming: T_W day';
    file = 'tw-chg-warming-on-wb.eps';
else
    title = 'T_W chg due to warming: TXx day';
    file = 'tw-chg-warming-on-txx.eps';
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 4], ...
                  'cbXTicks', 0:.5:4, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));
plotFromDataFile(saveData);


y=[nanmedian(twchgT_efchg,2)';nanmedian(twchgH_efchg,2)'];

figure('Color', [1,1,1]);
hold on;
bar(-.3:.1:.3,y','stacked')
