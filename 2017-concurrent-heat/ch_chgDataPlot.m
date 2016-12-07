% should we load pre-computed files
preload = true;

season = 'all';
basePeriod = 'past';
rcp = 'rcp85';
futurePeriodYears = 2020:2080;

if strcmp(rcp, 'rcp45')
    load('chgData-cmip5-50-rcp45');
    chgData50 = chgData;

    load('chgData-cmip5-90-rcp45');
    chgData90 = chgData;
    
    load('chgData-cmip5-99-rcp45');
    chgData99 = chgData;
elseif strcmp(rcp, 'rcp85')
    load('chgData-cmip5-50-rcp85');
    chgData50 = chgData;

    load('chgData-cmip5-90-rcp85');
    chgData90 = chgData;
    
    load('chgData-cmip5-99-rcp85');
    chgData99 = chgData;
end

load waterGrid;
load lat;
load lon;
waterGrid=logical(waterGrid);

[latIndexRange, lonIndexRange] = latLonIndexRange({lat,lon,[]}, [-40 40], [0 360]);

%b=sort(reshape(baseDataLandMid, [numel(baseDataLandMid),1]));
%f=sort(reshape(futureDataLandMid, [numel(futureDataLandMid),1]));

load waterGrid;
waterGrid = logical(waterGrid);
for y = size(chgData50, 3)
    for m = size(chgData50, 4)
        curGrid = chgData50(:, :, y, m);
        curGrid(waterGrid) = NaN;
        chgData50(:, :, y, m) = curGrid;
        
        curGrid = chgData90(:, :, y, m);
        curGrid(waterGrid) = NaN;
        chgData90(:, :, y, m) = curGrid;
        
        curGrid = chgData99(:, :, y, m);
        curGrid(waterGrid) = NaN;
        chgData99(:, :, y, m) = curGrid;
    end
end

chgData50 = squeeze(nanmean(nanmean(chgData50(latIndexRange, lonIndexRange, :, :), 2), 1));
chgData90 = squeeze(nanmean(nanmean(chgData90(latIndexRange, lonIndexRange, :, :), 2), 1));
chgData99 = squeeze(nanmean(nanmean(chgData99(latIndexRange, lonIndexRange, :, :), 2), 1));

['done loading...']

% areaGlobalTrendRcp45 = areaGlobalTrendRcp45 ./ earthTotalSA .* 100;
% areaLandTrendRcp45 = areaLandTrendRcp45  ./ earthLandSA .* 100;
% 
% areaGlobalTrendRcp85 = areaGlobalTrendRcp85 ./ earthTotalSA .* 100;
% areaLandTrendRcp85 = areaLandTrendRcp85  ./ earthLandSA .* 100;
% 
% fitLandBase = fitlm(1:size(areaLandTrendBase, 2), squeeze(nanmean(areaLandTrendBase, 1)));
% fitLandRcp45 = fitlm(1:size(areaLandTrendRcp45, 2), squeeze(nanmean(areaLandTrendRcp45, 1)));
% fitLandRcp85 = fitlm(1:size(areaLandTrendRcp85, 2), squeeze(nanmean(areaLandTrendRcp85, 1)));
% 
% fitGlobalBase = fitlm(1:size(areaGlobalTrendBase, 2), squeeze(nanmean(areaGlobalTrendBase, 1)));
% fitGlobalRcp45 = fitlm(1:size(areaGlobalTrendRcp45, 2), squeeze(nanmean(areaGlobalTrendRcp45, 1)));
% fitGlobalRcp85 = fitlm(1:size(areaGlobalTrendRcp85, 2), squeeze(nanmean(areaGlobalTrendRcp85, 1)));

figure('Color',[1,1,1]);
hold on;
p1 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(chgData50, 2)), std(chgData50, [], 2), 'o', 1);
set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(p1.edge, 'Color', 'k');
%plot(basePeriodYears, fitLandBase.Fitted, '--', 'Color', [96/255.0, 188/255.0, 100/255.0]);

p2 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(chgData90, 2)), std(chgData90, [], 2), 'o', 1);
set(p2.mainLine, 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(p2.patch, 'FaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(p2.edge, 'Color', 'k');
%plot(futurePeriodYears, fitLandRcp45.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

p3 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(chgData99, 2)), std(chgData99, [], 2), 'o', 1);
set(p3.mainLine, 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(p3.patch, 'FaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(p3.edge, 'Color', 'k');
%plot(futurePeriodYears, fitLandRcp45.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

if strcmp(rcp, 'rcp45')
    title('Change in land temperature, RCP 4.5', 'FontSize', 32);
elseif strcmp(rcp, 'rcp85')
    title('Change in land temperature, RCP 8.5', 'FontSize', 32);
end

xTicks = futurePeriodYears(1):10:futurePeriodYears(end)+1;

set(gca, 'XTick', xTicks);
set(gca, 'XTickLabel', xTicks);
set(gca, 'FontSize', 26);

legend([p1.mainLine, p2.mainLine, p3.mainLine], '50th percentile', '90th percentile', '99th percentile');

ylabel([char(176) 'C']);

xlim([xTicks(1) xTicks(end)]);
ylim([0 4]);





