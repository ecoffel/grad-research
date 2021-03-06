base = 'cmip5';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'ccsm4', ...
              'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fio-esm', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'giss-e2-h', 'giss-e2-h-cc', 'giss-e2-r', 'giss-e2-r-cc', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-lr', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

for m = 1:length(models)
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-historical-1961-2005-t83-p20.mat']);
    hotDryHistorical75(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-historical-1961-2005-t85-p15.mat']);
    hotDryHistorical85(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-historical-1961-2005-t95-p5.mat']);
    hotDryHistorical95(:,:,m) = hdyears;
    
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp45-2061-2085-t83-p20.mat']);
    hotDryFuture45Late75(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp45-2061-2085-t85-p15.mat']);
    hotDryFuture45Late85(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp45-2061-2085-t95-p5.mat']);
    hotDryFuture45Late95(:,:,m) = hdyears;

    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp85-2061-2085-t83-p20.mat']);
    hotDryFutureLate75(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp85-2061-2085-t85-p15.mat']);
    hotDryFutureLate85(:,:,m) = hdyears;
    load(['2017-nile-climate\output\hotDryFuture-annual-' base '-' models{m} '-rcp85-2061-2085-t95-p5.mat']);
    hotDryFutureLate95(:,:,m) = hdyears;
end


region = 'total';


load lat;
load lon;

[regionInds, regions, regionNames] = ni_getRegions();
curInds = regionInds('nile');
latIndsRegion = curInds{1};
lonIndsRegion = curInds{2};

if strcmp(region, 'total')
    curIndsBlue = regionInds(['nile-blue']);
    curIndsWhite = regionInds(['nile-white']);
    curLatIndsBlue = curIndsBlue{1} - latIndsRegion(1) + 1;
    curLonIndsBlue = curIndsBlue{2} - lonIndsRegion(1) + 1;
    curLatIndsWhite = curIndsWhite{1} - latIndsRegion(1) + 1;
    curLonIndsWhite = curIndsWhite{2} - lonIndsRegion(1) + 1;
    curLatInds = [curLatIndsBlue curLatIndsWhite];
    curLonInds = [curLonIndsBlue curLonIndsWhite];
else
    curInds = regionInds(['nile-' region]);
    curLatInds = curInds{1} - latIndsRegion(1) + 1;
    curLonInds = curInds{2} - lonIndsRegion(1) + 1;
end

% regionBounds = [[2 32]; [25, 44]];
% [latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% regionBoundsNorth = [[13 32]; [29, 34]];
% 
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
% latIndsNorth = latIndsNorth - latInds(1) + 1;
% lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
% latIndsSouth = latIndsSouth - latInds(1) + 1;
% lonIndsSouth = lonIndsSouth - lonInds(1) + 1;
% 
% if north
%     curLatInds = latIndsNorth;
%     curLonInds = lonIndsNorth;
% else
%     curLatInds = latIndsSouth;
%     curLonInds = lonIndsSouth;
% end

hotdry75 = hotDryFutureLate75;
hotdry75 = hotdry75(curLatInds, curLonInds, :);
hotdry75 = squeeze(nanmean(nanmean(hotdry75,2),1));
hotdryHist75 = hotDryHistorical75;
hotdryHist75 = hotdryHist75(curLatInds, curLonInds, :);
hotdryHist75 = squeeze(nanmean(nanmean(hotdryHist75,2),1));
% hotdry75 = hotdry75 ./ hotdryHist75;
% hotdry75(isinf(hotdry75)) = NaN;
% hotdry75(hotdryHist75 < .01) = NaN;
hotdry75 = sort(hotdry75);

hotdry45_75 = hotDryFuture45Late75;
hotdry45_75 = hotdry45_75(curLatInds, curLonInds, :);
hotdry45_75 = squeeze(nanmean(nanmean(hotdry45_75,2),1));
hotdryHist75 = hotDryHistorical75;
hotdryHist75 = hotdryHist75(curLatInds, curLonInds, :);
hotdryHist75 = squeeze(nanmean(nanmean(hotdryHist75,2),1));
% hotdry45_75 = hotdry45_75 ./ hotdryHist75;
% hotdry45_75(isinf(hotdry45_75)) = NaN;
% hotdry45_75(hotdryHist75 < .01) = NaN;
hotdry45_75 = sort(hotdry45_75);
hotdryHist75 = sort(hotdryHist75);

hotdry85 = hotDryFutureLate85;
hotdry85 = hotdry85(curLatInds, curLonInds, :);
hotdry85 = squeeze(nanmean(nanmean(hotdry85,2),1));
hotdryHist85 = hotDryHistorical85;
hotdryHist85 = hotdryHist85(curLatInds, curLonInds, :);
hotdryHist85 = squeeze(nanmean(nanmean(hotdryHist85,2),1));
% hotdry85 = hotdry85 ./ hotdryHist85;
% hotdry85(isinf(hotdry85)) = NaN;
% hotdry85(hotdryHist85 < .01) = NaN;
hotdry85 = sort(hotdry85);

hotdry45_85 = hotDryFuture45Late85;
hotdry45_85 = hotdry45_85(curLatInds, curLonInds, :);
hotdry45_85 = squeeze(nanmean(nanmean(hotdry45_85,2),1));
hotdryHist85 = hotDryHistorical85;
hotdryHist85 = hotdryHist85(curLatInds, curLonInds, :);
hotdryHist85 = squeeze(nanmean(nanmean(hotdryHist85,2),1));
% hotdry45_85 = hotdry45_85 ./ hotdryHist85;
% hotdry45_85(isinf(hotdry45_85)) = NaN;
% hotdry45_85(hotdryHist85 < .01) = NaN;
hotdry45_85 = sort(hotdry45_85);
hotdryHist85 = sort(hotdryHist85);

hotdry95 = hotDryFutureLate95;
hotdry95 = hotdry95(curLatInds, curLonInds, :);
hotdry95 = squeeze(nanmean(nanmean(hotdry95,2),1));
hotdryHist95 = hotDryHistorical95;
hotdryHist95 = hotdryHist95(curLatInds, curLonInds, :);
hotdryHist95 = squeeze(nanmean(nanmean(hotdryHist95,2),1));
% hotdry95 = hotdry95 ./ hotdryHist95;
% hotdry95(isinf(hotdry95)) = NaN;
% hotdry95(hotdryHist95 < .01) = NaN;
hotdry95 = sort(hotdry95);

hotdry45_95 = hotDryFuture45Late95;
hotdry45_95 = hotdry45_95(curLatInds, curLonInds, :);
hotdry45_95 = squeeze(nanmean(nanmean(hotdry45_95,2),1));
hotdryHist95 = hotDryHistorical95;
hotdryHist95 = hotdryHist95(curLatInds, curLonInds, :);
hotdryHist95 = squeeze(nanmean(nanmean(hotdryHist95,2),1));
% hotdry45_95 = hotdry45_95 ./ hotdryHist95;
% hotdry45_95(isinf(hotdry45_95)) = NaN;
% hotdry45_95(hotdryHist95 < .01) = NaN;
% hotdry45_95 = sort(hotdry45_95);
hotdryHist95 = sort(hotdryHist95);

ind1_75 = round(.1*length(hotdry75));
ind2_75 = round(.9*length(hotdry75));
%hotdry75(1:ind1_75) = NaN;
hotdry75(ind2_75:end) = NaN;

ind1_85 = round(.1*length(hotdry85));
ind2_85 = round(.9*length(hotdry85));
%hotdry85(1:ind1_85) = NaN;
hotdry85(ind2_85:end) = NaN;

ind1_95 = round(.1*length(hotdry95));
ind2_95 = round(.9*length(hotdry95));
%hotdry95(1:ind1_95) = NaN;
hotdry95(ind2_95:end) = NaN;

ind1_45_75 = round(.1*length(hotdry45_75));
ind2_45_75 = round(.9*length(hotdry45_75));
%hotdry45_75(1:ind1_45_75) = NaN;
hotdry45_75(ind2_45_75:end) = NaN;

ind1_45_85 = round(.1*length(hotdry45_85));
ind2_45_85 = round(.9*length(hotdry45_85));
%hotdry45_85(1:ind1_45_85) = NaN;
hotdry45_85(ind2_45_85:end) = NaN;

ind1_45_95 = round(.1*length(hotdry45_95));
ind2_45_95 = round(.9*length(hotdry45_95));
%hotdry45_95(1:ind1_45_95) = NaN;
hotdry45_95(ind2_45_95:end) = NaN;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
set(gca, 'YGrid', 'on');

b1 = boxplot(100.*[hotdryHist75 hotdryHist85 hotdryHist95], 'positions', [1.3 2.3 3.3], 'widths', [.1 .1 .1]);
b2 = boxplot(100.*[hotdry45_75 hotdry45_85 hotdry45_95], 'positions', [1.5 2.5 3.5], 'widths', [.1 .1 .1]);
b3 = boxplot(100.*[hotdry75 hotdry85 hotdry95], 'positions', [1.7 2.7 3.7], 'widths', [.1 .1 .1]);


colors = brewermap(10, 'Greens');

for bind = 1:size(b1,2)
    set(b1(:, bind), {'LineWidth', 'Color'}, {2, colors(7,:)})
    lines = findobj(b1(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
    
    h = findobj(b1, 'tag', 'Outliers');
    for iH = 1:length(h)
        h(iH).MarkerEdgeColor = colors(7,:);
    end
end

colors = brewermap(10, 'Blues');

for bind = 1:size(b2,2)
    set(b2(:, bind), {'LineWidth', 'Color'}, {2, colors(7,:)})
    lines = findobj(b2(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    
    h = findobj(b2, 'tag', 'Outliers');
    for iH = 1:length(h)
        h(iH).MarkerEdgeColor = colors(7,:);
    end
end


colors = brewermap(10, 'Reds');

for bind = 1:size(b3,2)
    set(b3(:, bind), {'LineWidth', 'Color'}, {2, colors(7,:)})
    lines = findobj(b3(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
    
    h = findobj(b3, 'tag', 'Outliers');
    for iH = 1:length(h)
        h(iH).MarkerEdgeColor = colors(7,:);
    end
end

% if north
%     ylim([0 150]);
%     set(gca, 'YTick', 0:25:150);
% else
%     ylim([0 15]);
%     set(gca, 'YTick', 0:5:15);
% end

xlim([1 4]);
ylim([0 27]);

set(gca,'TickLabelInterpreter', 'tex');    
xtickangle(0);

set(gca, 'XTick', 1.5:1:3.5, 'XTickLabels', {'T_{83}/P_{20}', 'T_{85}/P_{15}', 'T_{95}/P_{5}'});
xtickangle(90);
ylabel('Frequency (% of years)');
set(gca, 'FontSize', 36);
set(gca, 'YTick', [0:5:25]);
set(gcf, 'Position', get(0,'Screensize'));

export_fig(['hot-dry-freq-multiplier-' base '-' region '.eps']);

close all;
