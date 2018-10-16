models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];

histTas = [];
futTas = [];
histPr = [];
futPr = [];

models = {'csiro-mk3-6-0'};
ensembles = 1:10;

%[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({udelp{1}, udelp{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

histcorr = [];
futcorr = [];
for m = 1:length(models)
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/txx-months-' models{m} '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    for e = ensembles
        fprintf('loading %s ensemble r%di1p1...\n', models{m}, e);
        tas = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\historical\tas'], 'tas', 'startYear', 1850, 'endYear', 2005);
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\historical\pr'], 'pr', 'startYear', 1850, 'endYear', 2005);
        tasFut = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\rcp85\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
        prFut = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\rcp85\pr'], 'pr', 'startYear', 2006, 'endYear', 2099);

        lat = tas{1};
        lon = tas{2};
        
        %[latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

        tas = tas{3};%(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :);
        pr = pr{3};%(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :);
        tasFut = tasFut{3};%(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :);
        prFut = prFut{3};%(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :);
        
        for xlat = 50:size(tas, 1)
            for ylon = 1:size(tas, 2)
                t = squeeze(tas(xlat, ylon, :, [6 7 8]));
                t = reshape(t, [numel(t),1]);
                p = squeeze(pr(xlat, ylon, :, [6 7 8]));
                p = reshape(p, [numel(p),1]);
                histcorr(xlat, ylon, m, e) = corr(detrend(t), detrend(p));
                
                tf = squeeze(tasFut(xlat, ylon, :, [6 7 8]));
                tf = reshape(tf, [numel(tf),1]);
                pf = squeeze(prFut(xlat, ylon, :, [6 7 8]));
                pf = reshape(pf, [numel(pf),1]);
                futcorr(xlat, ylon, m, e) = corr(detrend(tf), detrend(pf));
                
            end
        end


        clear tas pr tasFut prFut;
    end
end

sigChg = [];
sigP = [];

for xlat = 1:size(histcorr, 1)
    for ylon = 1:size(histcorr, 2)
        h = squeeze(histcorr(xlat, ylon, :, :));
        f = squeeze(futcorr(xlat, ylon, :, :));
        
        f-h
        
        [th, tp] = ttest(f-h);
        sigP(xlat, ylon) = tp;
        if th
            sigChg(xlat, ylon) = sign(mean(f)-mean(h));
        else
            sigChg(xlat, ylon) = 0;
        end
    end
end

for m = 1:size(histTas,2)
    tn = detrend(histTas(:,m));
    pn = detrend(histPr(:,m));
    tfn = detrend(futTas(:,m));
    pfn = detrend(futPr(:,m));
    
    length(find(tfn>prctile(tfn,90) & pfn < prctile(pfn, 10)))-length(find(tn>prctile(tn,90) & pn < prctile(pn, 10)))
end
