
regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];

load E:\data\ssp-pop\ssp1\output\ssp1\ssp1_2010.mat;
[latIndsEthiopiaSSP, lonIndsEthiopiaSSP] = latLonIndexRange({ssp1_2010{1},ssp1_2010{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%                       'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                       'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                       'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%                       'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', ...
              'inmcm4', 'miroc5', 'miroc-esm', ...
              'ipsl-cm5a-mr', 'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
if ~exist('tas')
    indhd = {};
    indh = {};
    for mind = 1:length(models)
        fprintf('loading %s historical...\n', models{mind});

        tas = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\tas'], 'tas', 'startYear', 1900, 'endYear', 2005);
        tasFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\tas'], 'tas', 'startYear', 2006, 'endYear', 2099);
        pr = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\pr'], 'pr', 'startYear', 1900, 'endYear', 2005);
        prFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\pr'], 'pr', 'startYear', 2006, 'endYear', 2099);
        mrros = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\historical\mrro'], 'mrro', 'startYear', 1900, 'endYear', 2005);
        mrrosFut = loadMonthlyData(['E:\data\cmip5\output\' models{mind} '\mon\r1i1p1\rcp85\mrro'], 'mrro', 'startYear', 2006, 'endYear', 2099);

        [latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5] = latLonIndexRange({mrros{1}, mrros{2},[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

        tdata(:,mind) = nanmean(squeeze(nanmean(nanmean(tas{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
        mdata(:,mind) = nanmean(squeeze(nanmean(nanmean(mrros{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
        pdata(:,mind) = nanmean(squeeze(nanmean(nanmean(pr{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
        
        tfdata(:,mind) = nanmean(squeeze(nanmean(nanmean(tasFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
        pfdata(:,mind) = nanmean(squeeze(nanmean(nanmean(prFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
        mfdata(:,mind) = nanmean(squeeze(nanmean(nanmean(mrrosFut{3}(latIndsEthiopiaCmip5, lonIndsEthiopiaCmip5, :, 5:9), 2), 1)), 2);
    end
end


bwfpLat = [];
bwfpLon = [];
bwfp = [];
bwfpEthiopia = [];
gwfp = [];
gwfpEthiopia = [];

sspEthiopiaLon = ssp1_2010{2}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
sspEthiopiaLat = ssp1_2010{1}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);
sspEthiopia = ssp1_2010{3}(latIndsEthiopiaSSP, lonIndsEthiopiaSSP);


for m = 1:12
    fprintf('loading bwfp/gwfp...\n');
    load(['E:\data\bgwfp\output\bwfp\bwfp_' num2str(m)]);
    eval(['bwfp(:, :, ' num2str(m) ') = bwfp_' num2str(m) '{3};']);
    
    load(['E:\data\bgwfp\output\gwfp\gwfp_' num2str(m)]);
    eval(['gwfp(:, :, ' num2str(m) ') = gwfp_' num2str(m) '{3};']);
    
    if m == 1
        bwfpLat = bwfp_1{1};
        bwfpLon = bwfp_1{2};
        
        [latIndsEthiopiaBW, lonIndsEthiopiaBW] = latLonIndexRange({bwfpLat,bwfpLon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
    end
    
    fprintf('loading bwfp/gwfp month %d...\n', m);
    tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
    bwfpEthiopia(:, :, m) = tmp{3};
    tmp = regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), gwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
    gwfpEthiopia(:, :, m) = tmp{3};
    
    eval(['clear bwfp_' num2str(m) ';']);
    eval(['clear gwfp_' num2str(m) ';']);
end

bwfp = squeeze(nansum(nansum(bwfpEthiopia(:, :, 5:9),2),1));
gwfp = squeeze(nansum(nansum(gwfpEthiopia(:, :, 5:9),2),1));

mdiff = mdata ./ nanmean(mdata,1);
mfdiff = mfdata ./ nanmean(mdata,1);

mprc = [];
for mind = 1:length(models)
    mprc(:, mind) = [mdiff(:,mind); mfdiff(:,mind)];
end

pcBwfp = [];
pcGwfp = [];
rangeBW = [];
rangeGW = [];

for s = 1:5
    decind = 1;
    for dec = 2020:10:2080
        load(['E:\data\ssp-pop\ssp' num2str(s) '\output\ssp' num2str(s) '\ssp' num2str(s) '_' num2str(dec) '.mat']);
        eval(['ssp = ssp' num2str(s) '_' num2str(dec) '{3};']);
        for m = 1:length(models)
            pcBwfp(decind, m, s) = (nanmean(bwfp) * nanmean(mfdiff(dec-2020+14:dec-2020+23, m))) / nansum(nansum(ssp(latIndsEthiopiaSSP, lonIndsEthiopiaSSP)));
            pcGwfp(decind, m, s) = (nanmean(gwfp) * nanmean(mfdiff(dec-2020+14:dec-2020+23, m))) / nansum(nansum(ssp(latIndsEthiopiaSSP, lonIndsEthiopiaSSP)));
        end
        decind = decind+1;
    end
    rangeBW(:,s) = ((nanmean(pcBwfp(end-2:end,:,s),1)-pcBwfp(1,:,s)) ./ pcBwfp(1,:,s))';
    rangeGW(:,s) = ((nanmean(pcGwfp(end-2:end,:,s),1)-pcGwfp(1,:,s)) ./ pcGwfp(1,:,s))';
end

colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1]);

b = boxplot(rangeBW .* 100, 'widths', .8);

set(b, {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([0 6], [0 0], '--k', 'linewidth', 2);

set(gca, 'fontsize', 36);
xlabel('SSP');
ylabel('% change per capita BW');
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-chg-2060-2090.eps;
close all;


tprc = 75;
pprc = 25;

mAnomHd = [];
mAnomD = [];
mAnomH = [];
for mind = 1:length(models)
    mAnomHd(mind) = (mean(mdata(find(tdata(:,mind)>prctile(tdata(:,mind),tprc) & pdata(:,mind)<prctile(pdata(:,mind),pprc)), mind))-mean(mdata(:,mind)))/mean(mdata(:,mind));
    mAnomD(mind) = (mean(mdata(find(tdata(:,mind)<prctile(tdata(:,mind),tprc) & pdata(:,mind)<prctile(pdata(:,mind),pprc)), mind))-mean(mdata(:,mind)))/mean(mdata(:,mind));
    mAnomH(mind) = (mean(mdata(find(tdata(:,mind)>prctile(tdata(:,mind),tprc) & pdata(:,mind)>prctile(pdata(:,mind),pprc)), mind))-mean(mdata(:,mind)))/mean(mdata(:,mind));
end

mAnom = {mAnomHd', mAnomD', mAnomH'};
save(['manom-' num2str(tprc) '-' num2str(pprc) '.mat'], 'mAnom');


figure('Color', [1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 2.5 1]);

b = boxplot([mAnomHd' mAnomD' mAnomH'] .* 100, 'widths', .8);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:,1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:,2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorH})
lines = findobj(b(:,3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([0 6], [0 0], '--k', 'linewidth', 2);

set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'Hot + Dry', 'Dry', 'Hot'});
xtickangle(45);
ylabel('BW anomaly (%)');
set(gcf, 'Position', get(0,'Screensize'));
export_fig bw-hd-d-h-anom-p34-t74.eps;
close all;



% convert to mm/monthregridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);regridGriddata({bwfpLat(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfpLon(latIndsEthiopiaBW, lonIndsEthiopiaBW), bwfp(latIndsEthiopiaBW, lonIndsEthiopiaBW, m)}, {ssp1_2010{1}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{2}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP), ssp1_2010{3}(latIndsEthiopiaSSP,lonIndsEthiopiaSSP)}, false);
%bwfp = bwfp .* 3600 .* 24 .* 30;
%bwfpEthiopia = bwfpEthiopia .* 3600 .* 24 .* 30;

