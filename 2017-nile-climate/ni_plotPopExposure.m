load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2010.mat

load E:\data\ssp-pop\ssp2\output\ssp2\regrid\ssp2_2030.mat
load E:\data\ssp-pop\ssp2\output\ssp2\regrid\ssp2_2040.mat
load E:\data\ssp-pop\ssp2\output\ssp2\regrid\ssp2_2050.mat
load E:\data\ssp-pop\ssp2\output\ssp2\regrid\ssp2_2060.mat
load E:\data\ssp-pop\ssp2\output\ssp2\regrid\ssp2_2070.mat

load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2030.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2040.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2050.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2060.mat
load E:\data\ssp-pop\ssp3\output\ssp3\regrid\ssp3_2070.mat

load E:\data\ssp-pop\ssp4\output\ssp4\regrid\ssp4_2030.mat
load E:\data\ssp-pop\ssp4\output\ssp4\regrid\ssp4_2040.mat
load E:\data\ssp-pop\ssp4\output\ssp4\regrid\ssp4_2050.mat
load E:\data\ssp-pop\ssp4\output\ssp4\regrid\ssp4_2060.mat
load E:\data\ssp-pop\ssp4\output\ssp4\regrid\ssp4_2070.mat

load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2030.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2040.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2050.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2060.mat
load E:\data\ssp-pop\ssp5\output\ssp5\regrid\ssp5_2070.mat



load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-historical-1981-2005-t90-p10.mat']);
hotDryHistorical90 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp45-2031-2055.mat']);
hotDryFuture45Early90 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp45-2056-2080.mat']);
hotDryFuture45Late90 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2031-2055.mat']);
hotDryFuture85Early90 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2056-2080.mat']);
hotDryFuture85Late90 = hotDryFuture;

north = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

if north
    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;
else
    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;
end

sspHist = ssp3_2010{3}(latInds, lonInds);
ssp2Early = (ssp2_2030{3}(latInds, lonInds) + ssp2_2040{3}(latInds, lonInds) + ssp2_2050{3}(latInds, lonInds)) ./ 3;
ssp3Early = (ssp3_2030{3}(latInds, lonInds) + ssp3_2040{3}(latInds, lonInds) + ssp3_2050{3}(latInds, lonInds)) ./ 3;
ssp4Early = (ssp4_2030{3}(latInds, lonInds) + ssp4_2040{3}(latInds, lonInds) + ssp4_2050{3}(latInds, lonInds)) ./ 3;
ssp5Early = (ssp5_2030{3}(latInds, lonInds) + ssp5_2040{3}(latInds, lonInds) + ssp5_2050{3}(latInds, lonInds)) ./ 3;

ssp2Late = (ssp2_2050{3}(latInds, lonInds) + ssp2_2060{3}(latInds, lonInds) + ssp2_2070{3}(latInds, lonInds)) ./ 3;
ssp3Late = (ssp3_2050{3}(latInds, lonInds) + ssp3_2060{3}(latInds, lonInds) + ssp3_2070{3}(latInds, lonInds)) ./ 3;
ssp4Late = (ssp4_2050{3}(latInds, lonInds) + ssp4_2060{3}(latInds, lonInds) + ssp4_2070{3}(latInds, lonInds)) ./ 3;
ssp5Late = (ssp5_2050{3}(latInds, lonInds) + ssp5_2060{3}(latInds, lonInds) + ssp5_2070{3}(latInds, lonInds)) ./ 3;

expHist = squeeze(sum(sum(hotDryHistorical90 .* repmat(sspHist, [1 1 size(hotDryHistorical90, 3)]))));

exp45Late2 = squeeze(sum(sum(hotDryFuture45Late90 .* repmat(ssp2Late, [1 1 size(hotDryFuture45Late90, 3)]))));
exp45Late4 = squeeze(sum(sum(hotDryFuture45Late90 .* repmat(ssp4Late, [1 1 size(hotDryFuture45Late90, 3)]))));
exp45Late2(end+1) = NaN;
exp45Late4(end+1) = NaN;
exp45Early2 = squeeze(sum(sum(hotDryFuture45Early90 .* repmat(ssp2Early, [1 1 size(hotDryFuture45Late90, 3)]))));
exp45Early4 = squeeze(sum(sum(hotDryFuture45Early90 .* repmat(ssp4Early, [1 1 size(hotDryFuture45Late90, 3)]))));
exp45Early4(end+1) = NaN;
exp45Early2(end+1) = NaN;

exp85Late3 = squeeze(sum(sum(hotDryFuture85Late90 .* repmat(ssp3Late, [1 1 size(hotDryHistorical90, 3)]))));
exp85Late5 = squeeze(sum(sum(hotDryFuture85Late90 .* repmat(ssp5Late, [1 1 size(hotDryHistorical90, 3)]))));
exp85Early3 = squeeze(sum(sum(hotDryFuture85Early90 .* repmat(ssp3Early, [1 1 size(hotDryHistorical90, 3)]))));
exp85Early5 = squeeze(sum(sum(hotDryFuture85Early90 .* repmat(ssp5Early, [1 1 size(hotDryHistorical90, 3)]))));

figure('Color', [1, 1, 1]);
hold on;
axis square;
box on;
grid on;

b = boxplot([expHist exp45Early2 exp45Early4 exp85Early3 exp85Early5 exp45Late2 exp45Late4 exp85Late3 exp85Late5], ...
            'positions', [1 1.8 1.9 2.1 2.2 2.8 2.9 3.1 3.2], 'colors', 'gbbrrbbrr');

for bind = 1:size(b, 2)
    if ismember(bind, [2 3 6 7])
        set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    elseif bind == 1
        set(b(:, bind), {'LineWidth', 'Color'}, {2, [110, 191, 66]./255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    elseif ismember(bind, [4 5 8 9])
        set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
        lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    end
end
    
xlim([.5 3.7]);
ylim([0 2.1e8]);
set(gca, 'XTick', [1 2 3], 'XTickLabels', {'1981 - 2005', '2031 - 2055', '2056 - 2080'});
xtickangle(45);
set(gca, 'YTick', 0:.2e8:2.1e8, 'YTickLabels', 0:.2:2.2);
ylabel('Exposure (100 millions)');
set(gca, 'FontSize', 36);
set(gcf, 'Position', get(0,'Screensize'));
export_fig nile-pop-exposure.eps;
close all;



