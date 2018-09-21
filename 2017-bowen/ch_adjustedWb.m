
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

% result = {lat, lon, nanmedian(wbChgOnWb, 3)};
% 
% agreement = zeros(size(lat));
% sig = zeros(size(lat));
% for xlat = 1:size(lat, 1)
%     for ylon = 1:size(lat, 2)
%         if waterGrid(xlat, ylon)
%             continue;
%         end
%         
%         med = nanmedian(wbChgOnWb(xlat, ylon, :), 3);
%         num = length(find(~isnan(squeeze(wbChgOnWb(xlat, ylon, :)))));
%         agreement(xlat, ylon) = ~(length(find(sign(wbChgOnWb(xlat, ylon, :)) == sign(med))) > .66*num);
%     end
% end
% 
% agreement(1:15,:) = 0;
% agreement(75:90,:) = 0;
% 
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [0 4], ...
%                   'cbXTicks', 0:.5:4, ...
%                   'plotTitle', ['T_W chg on T_W day'], ...
%                   'fileTitle', ['wb-chg-wb.eps'], ...
%                   'plotXUnits', [char(176) 'C'], ...
%                   'blockWater', true, ...
%                   'colormap', brewermap([], 'Reds'), ...
%                   'statData', agreement);
% plotFromDataFile(saveData);


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

amp3 = txChgWarmSeason;
driverRaw3 = efChgWarmSeason;

amp4 = hussChgWarmSeason;
driverRaw4 = efChgWarmSeason;

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

    a3 = squeeze(amp3(:,:,m));
    a3(waterGrid) = NaN;
    a3(1:15,:) = NaN;
    a3(75:90,:) = NaN;
    a3 = reshape(a3, [numel(a3),1]);

    driver3 = squeeze(driverRaw3(:,:,m));
    driver3(waterGrid) = NaN;
    driver3(1:15,:) = NaN;
    driver3(75:90,:) = NaN;
    driver3 = reshape(driver3, [numel(driver3),1]);
    
    a4 = squeeze(amp4(:,:,m));
    a4(waterGrid) = NaN;
    a4(1:15,:) = NaN;
    a4(75:90,:) = NaN;
    a4 = reshape(a4, [numel(a4),1]);

    driver4 = squeeze(driverRaw4(:,:,m));
    driver4(waterGrid) = NaN;
    driver4(1:15,:) = NaN;
    driver4(75:90,:) = NaN;
    driver4 = reshape(driver4, [numel(driver4),1]);
    
    efGroup(waterGrid) = NaN;
    efGroup(1:15,:) = NaN;
    efGroup(75:90,:) = NaN;
    efGroup =  reshape(efGroup, [numel(efGroup),1]);

    if length(amp2) > 0
        nn = find(isnan(a) | isnan(driver) | isnan(a2) | isnan(driver2));
        driver2(nn) = [];
        driver3(nn) = [];
        driver4(nn) = [];
        aDriver2 = a2;
        aDriver2(nn) = [];
        aDriver3 = a3;
        aDriver3(nn) = [];
        aDriver4 = a4;
        aDriver4(nn) = [];
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

            curDriver3 = driver3(nn);
            curADriver3 = aDriver3(nn);

            f3 = fitlm(curDriver3, curADriver3, 'linear');
            dslopes(3, e, m) = f3.Coefficients.Estimate(2);
            dslopesP(3, e, m) = f3.Coefficients.pValue(2);
            
            curFits{e}{3} = f3;
            
            curDriver4 = driver4(nn);
            curADriver4 = aDriver4(nn);
            
            f4 = fitlm(curDriver4, curADriver4, 'linear');
            dslopes(4, e, m) = f4.Coefficients.Estimate(2);
            dslopesP(4, e, m) = f4.Coefficients.pValue(2);
            
            curFits{e}{4} = f4;
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

tchgDueToEf = zeros(size(lat, 1), size(lat, 2), length(dmodels));
tchgDueToEf(tchgDueToEf==0) = NaN;
hchgDueToEf = zeros(size(lat, 1), size(lat, 2), length(dmodels));
hchgDueToEf(tchgDueToEf==0) = NaN;

for m = 1:length(dmodels)
    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
	for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            curGroup = efGroup(xlat, ylon);
            if waterGrid(xlat, ylon) || isnan(curGroup) || isnan(efOnWb(xlat, ylon, m))
                continue;
            end
            
            if useWarmSeason
                efChg = efChgWarmSeason;
                curHistTxx = histTxWarmSeason;
                curHistHuss = histHussWarmSeason;
                txxChg = txChgWarmSeason;
                hussChg = hussChgWarmSeason;
            else
                if useWb
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
            end
            
            if useWarmSeason
                tchgDueToEf(xlat, ylon, m) = predict(dmodels{m}{curGroup}{3}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{3}, 0);
                hchgDueToEf(xlat, ylon, m) = predict(dmodels{m}{curGroup}{4}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{4}, 0);
            else
                tchgDueToEf(xlat, ylon, m) = predict(dmodels{m}{curGroup}{1}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{1}, 0);
                hchgDueToEf(xlat, ylon, m) = predict(dmodels{m}{curGroup}{2}, efChg(xlat, ylon, m)) - predict(dmodels{m}{curGroup}{2}, 0);
            end
            % using ef-chg predicted t/h chg
            twchgT_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + tchgDueToEf(xlat, ylon, m), 100200, curHistHuss(xlat, ylon)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgH_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon) + hchgDueToEf(xlat, ylon, m)) - kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
            twchgTot_efchg(xlat, ylon, m) = kopp_wetBulb(curHistTxx(xlat, ylon) + tchgDueToEf(xlat, ylon, m), 100200, curHistHuss(xlat, ylon) + hchgDueToEf(xlat, ylon, m))-kopp_wetBulb(curHistTxx(xlat, ylon), 100200, curHistHuss(xlat, ylon));
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

save('twchgTPer_warming_txx', 'twchgTPer_warming');

result = {lat, lon, 100 .* nanmedian(twchgTPer_warming, 3)};

agreement = zeros(size(lat));
sig = zeros(size(lat));
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        for m = 1:size(twchgTPer_warming, 3)
            if twchgTPer_warming(xlat, ylon, m) >= .5
                agreement(xlat, ylon) = agreement(xlat, ylon) + 1;
            end
        end
    end
end

sig = double(~(abs(agreement) > .66*length(models) | abs(agreement) < .33*length(models)));
sig(1:15,:) = 0;
sig(75:90,:) = 0;

if useWarmSeason
    title = 'T_W chg in warm season: contribution from T chg';
    file = 'wb-in-warm-season-contrib-warming.eps';
else
    if useWb
        title = 'T_W chg on T_W day: contribution from T chg';
        file = 'wb-on-wb-contrib-warming.eps';
    else
        title = 'T_W chg on TXx day: contribution from T chg';
        file = 'wb-on-txx-contrib-warming.eps';
    end
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





result = {lat, lon, nanmean(twchgT_efchg, 3)};

agreement = zeros(size(lat));
sig = zeros(size(lat));
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        
        med = nanmean(twchgH_efchg(xlat, ylon, :), 3);
        agreement(xlat, ylon) = ~(length(find(sign(twchgH_efchg(xlat, ylon, :)) == sign(med))) > .66*length(models));
    end
end

agreement(1:15,:) = 0;
agreement(75:90,:) = 0;

if useWarmSeason
    title = 'T_W chg due to EF-induced T chg: warm season';
    file = 'tw-chg-ef-ind-t-chg-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to EF-induced T chg: T_W day';
        file = 'tw-chg-ef-ind-t-chg-on-wb.eps';
    else
        title = 'T_W chg due to EF-induced T chg: TXx day';
        file = 'tw-chg-ef-ind-t-chg-on-txx.eps';
    end
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', agreement);
plotFromDataFile(saveData);

result = {lat, lon, nanmean(twchgT_warming, 3)};

if useWarmSeason
    title = 'T_W chg due to warming-induced T chg: warm season'
    file = 'tw-chg-warming-ind-t-chg-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to warming-induced T chg: T_W day'
        file = 'tw-chg-warming-ind-t-chg-on-wb.eps';
    else
        title = 'T_W chg due to warming-induced T chg: TXx day';
        file = 'tw-chg-warming-ind-t-chg-on-txx.eps';
    end
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



result = {lat, lon, nanmean(twchgH_efchg, 3)};

agreement = zeros(size(lat));
sig = zeros(size(lat));
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        
        med = nanmean(twchgH_efchg(xlat, ylon, :), 3);
        agreement(xlat, ylon) = ~(length(find(sign(twchgH_efchg(xlat, ylon, :)) == sign(med))) > .66*length(models));
    end
end

agreement(1:15,:) = 0;
agreement(75:90,:) = 0;

if useWarmSeason
    title = 'T_W chg due to EF-induced H chg: warm season';
    file = 'tw-chg-due-to-ef-ind-h-chg-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to EF-induced H chg: T_W day';
        file = 'tw-chg-due-to-ef-ind-h-chg-on-wb.eps';
    else
        title = 'T_W chg due to EF-induced H chg: TXx day';
        file = 'tw-chg-due-to-ef-ind-h-chg-on-txx.eps';
    end
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', agreement);
plotFromDataFile(saveData);

result = {lat, lon, nanmean(twchgH_warming, 3)};

if useWarmSeason
    title = 'T_W chg due to warming-induced H chg: warm season';
    file = 'tw-chg-warming-ind-h-chg-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to warming-induced H chg: T_W day';
        file = 'tw-chg-warming-ind-h-chg-on-wb.eps';
    else
        title = 'T_W chg due to warming-induced H chg: TXx day';
        file = 'tw-chg-warming-ind-h-chg-on-txx.eps';
    end
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



result = {lat, lon, nanmean(twchgTot_efchg, 3)};

agreement = zeros(size(lat));
sig = zeros(size(lat));
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            continue;
        end
        
        med = nanmean(twchgTot_efchg(xlat, ylon, :), 3);
        agreement(xlat, ylon) = ~(length(find(sign(twchgTot_efchg(xlat, ylon, :)) == sign(med))) > .66*length(models));
    end
end

agreement(1:15,:) = 0;
agreement(75:90,:) = 0;

if useWarmSeason
    title = 'T_W chg due to EF chg: warm season';
    file = 'tw-chg-due-to-ef-chg-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to EF chg: T_W day';
        file = 'tw-chg-due-to-ef-chg-on-wb.eps';
    else
        title = 'T_W chg due to EF chg: TXx day';
        file = 'tw-chg-due-to-ef-chg-on-txx.eps';
    end
end

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [title], ...
                  'fileTitle', [file], ...
                  'plotXUnits', [char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'), ...
                  'statData', agreement);
plotFromDataFile(saveData);

result = {lat, lon, nanmean(twchgTot_warming, 3)};

if useWarmSeason
    title = 'T_W chg due to warming: warm season';
    file = 'tw-chg-warming-in-warm-season.eps';
else
    if useWb
        title = 'T_W chg due to warming: T_W day';
        file = 'tw-chg-warming-on-wb.eps';
    else
        title = 'T_W chg due to warming: TXx day';
        file = 'tw-chg-warming-on-txx.eps';
    end
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
