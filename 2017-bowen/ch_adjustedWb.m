txxWarmAnom = true;

useWb = false;
var = 'huss';

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

if ~exist('histTmax', 'var')
% load era tmax and huss
eraHuss = loadDailyData('E:\data\era-interim\output\huss\regrid\world', 'startYear', 1981, 'endYear', 2016);
eraHuss = eraHuss{3};
eraTmax = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1981, 'endYear', 2016);
eraTmax = eraTmax{3}-273.15;

histTmax = [];
histHuss = [];

for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            histTmax(xlat, ylon) = NaN;
            histHuss(xlat, ylon) = NaN;
            continue;
        end
        
        mxt = [];
        mxh = [];
        
        for year = 1:size(eraTmax, 3)
            t = eraTmax(xlat, ylon, year, :, :);
            t = reshape(t, [numel(t), 1]);
            ind = find(t == nanmax(t));

            h = eraHuss(xlat, ylon, :, :, :);
            h = reshape(h, [numel(h), 1]);
            
            mxt(year) = t(ind(1));
            mxh(year) = h(ind(1));
        end
        
        histTmax(xlat, ylon) = nanmean(mxt);
        histHuss(xlat, ylon) = nanmean(mxh);
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

amp = txxChgOnTxx;
driverRaw = efOnTxx;

amp2 = hussOnTxx;
driverRaw2 = efOnTxx;

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

tchg = [];
hchg = [];
twchg = [];
    
efChgs = -.3:.1:.3;
tChgs = 0:10;
hChgs = 0:.25e-3:3e-3;

baseH = .005;
baseT = 33;

twchgT = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgT(twchgT==0) = NaN;
twchgH = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgH(twchgH==0) = NaN;
twchgTot = zeros(size(lat, 1), size(lat, 2), length(dmodels));
twchgTot(twchgTot==0) = NaN;

for m = 1:length(dmodels)
    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
	for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            curGroup = efGroup(xlat, ylon);
            if waterGrid(xlat, ylon) || isnan(curGroup) || isnan(efOnTxx(xlat, ylon, m))
                continue;
            end

            tchg = predict(dmodels{m}{curGroup}{1}, efOnTxx(xlat, ylon, m));
            hchg = predict(dmodels{m}{curGroup}{2}, efOnTxx(xlat, ylon, m));
            twchgT(xlat, ylon, m) = kopp_wetBulb(histTmax(xlat, ylon) + tchg, 100200, histHuss(xlat, ylon)) - kopp_wetBulb(histTmax(xlat, ylon), 100200, histHuss(xlat, ylon));
            twchgH(xlat, ylon, m) = kopp_wetBulb(histTmax(xlat, ylon), 100200, histHuss(xlat, ylon) + hchg) - kopp_wetBulb(histTmax(xlat, ylon), 100200, histHuss(xlat, ylon));
            twchgTot(xlat, ylon, m) = kopp_wetBulb(histTmax(xlat, ylon) + tchg, 100200, histHuss(xlat, ylon) + hchg)-kopp_wetBulb(histTmax(xlat, ylon), 100200, histHuss(xlat, ylon));
        end
    end
    
    twchgTPer(:,:,m) = twchgT(:,:,m) ./ twchgTot(:,:,m);
    twchgHPer(:,:,m) = twchgH(:,:,m) ./ twchgTot(:,:,m);
end

result = {lat, lon, 100 .* nanmean(twchgTPer, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [25 75], ...
                  'cbXTicks', 25:10:75, ...
                  'plotTitle', ['Temperature'], ...
                  'fileTitle', ['wb-on-txx-t-contrib.eps'], ...
                  'plotXUnits', ['%'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));
plotFromDataFile(saveData);

result = {lat, lon, 100 .* nanmean(twchgHPer, 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [25 75], ...
                  'cbXTicks', 25:10:75, ...
                  'plotTitle', ['Humidity'], ...
                  'fileTitle', ['wb-on-txx-h-contrib.eps'], ...
                  'plotXUnits', ['%'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));
plotFromDataFile(saveData);


y=[nanmedian(twchgT,2)';nanmedian(twchgH,2)'];

figure('Color', [1,1,1]);
hold on;
bar(-.3:.1:.3,y','stacked')
