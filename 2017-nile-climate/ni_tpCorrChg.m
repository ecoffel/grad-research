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
    for e = ensembles
        fprintf('loading %s ensemble r%di1p1...\n', models{m}, e);
        tas = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\historical\tas'], 'tas', 'startYear', 1850, 'endYear', 2005);
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r' num2str(e) 'i1p1\historical\pr'], 'pr', 'startYear', 1850, 'endYear', 2005);
%         tasFut = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\rcp85\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
%         prFut = loadMonthlyData(['E:\data\cmip5\output\' models{m} '\mon\r1i1p1\rcp85\pr'], 'pr', 'startYear', 2006, 'endYear', 2099);

        [latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({tas{1}, tas{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

        t = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)),2);
        p = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);

        histTas(:,m) = t;
        histPr(:,m) = p;

%         tf = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
%         pf = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, :), 2), 1)), 2);
% 
%         futTas(:,m) = tf;
%         futPr(:,m) = pf;

        histcorr(m) = corr(detrend(t), detrend(p))
        %futcorr(m) = corr(detrend(tf), detrend(pf))

        fitlm(detrend(t), detrend(p))
        %fitlm(detrend(tf), detrend(pf))

        clear tas pr;
    end
end

for m = 1:size(histTas,2)
    tn = detrend(histTas(:,m));
    pn = detrend(histPr(:,m));
    tfn = detrend(futTas(:,m));
    pfn = detrend(futPr(:,m));
    
    length(find(tfn>prctile(tfn,90) & pfn < prctile(pfn, 10)))-length(find(tn>prctile(tn,90) & pn < prctile(pn, 10)))
end
