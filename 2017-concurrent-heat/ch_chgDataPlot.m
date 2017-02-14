% should we load pre-computed files
preload = true;

season = 'all';
basePeriod = 'past';
rcp = 'rcp45';
futurePeriodYears = 2020:2080;

thresh = [1 10:10:90 99];
threshInd = [find(thresh == 1), find(thresh == 10), find(thresh == 50), find(thresh == 90), find(thresh == 99)];

chgDataBaseDir = 'chg-data/';

if strcmp(rcp, 'rcp45')
    load([chgDataBaseDir 'chgData-cmip5-thresh-rcp45']);
elseif strcmp(rcp, 'rcp85')
    load([chgDataBaseDir 'chgData-cmip5-thresh-rcp85']);
end

load waterGrid;
load lat;
load lon;
waterGrid=logical(waterGrid);

[latIndexRangeWorld, lonIndexRangeWorld] = latLonIndexRange({lat,lon,[]}, [-90 90], [0 360]);
[latIndexRangeUsne, lonIndexRangeUsne] = latLonIndexRange({lat,lon,[]}, [30 55], [-100 -62] + 360);
[latIndexRangeIndia, lonIndexRangeIndia] = latLonIndexRange({lat,lon,[]}, [8, 34], [67, 90]);
[latIndexRangeTropics, lonIndexRangeTropics] = latLonIndexRange({lat,lon,[]}, [-20 20], [0 360]);
[latIndexRangeChina, lonIndexRangeChina] = latLonIndexRange({lat,lon,[]}, [20, 55], [75, 135]);

['done loading...']

figure('Color',[1,1,1]);

subplot(1,2,1);
hold on;
lWorld_y = squeeze(nanmean(nanmean(nanmean(chgData(latIndexRangeWorld, lonIndexRangeWorld, :, :, end-20:end), 5), 2), 1));
lUsne_y = squeeze(nanmean(nanmean(nanmean(chgData(latIndexRangeUsne, lonIndexRangeUsne, :, :, end-20:end), 5), 2), 1));
lIndia_y = squeeze(nanmean(nanmean(nanmean(chgData(latIndexRangeIndia, lonIndexRangeIndia, :, :, end-20:end), 5), 2), 1));
lTropics_y = squeeze(nanmean(nanmean(nanmean(chgData(latIndexRangeTropics, latIndexRangeTropics, :, :, end-20:end), 5), 2), 1));
lChina_y = squeeze(nanmean(nanmean(nanmean(chgData(latIndexRangeChina, latIndexRangeChina, :, :, end-20:end), 5), 2), 1));

lWorld = plot(thresh, nanmean(lWorld_y), 'k', 'LineWidth', 2);
lUsne = plot(thresh, nanmean(lUsne_y), 'Color', [96/255.0, 188/255.0, 100/255.0], 'LineWidth', 2);
lIndia = plot(thresh, nanmean(lIndia_y), 'Color', [66/255.0, 134/255.0, 244/255.0], 'LineWidth', 2);
lTropics = plot(thresh, nanmean(lTropics_y), 'Color', [255/255.0, 108/255.0, 71/255.0], 'LineWidth', 2);
lChina = plot(thresh, nanmean(lChina_y), 'Color', [224/255.0, 79/255.0, 247/255.0], 'LineWidth', 2);

% lWorld = shadedErrorBar(thresh, nanmean(lWorld_y), std(lWorld_y), 'o', 1);
% set(lWorld.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
% set(lWorld.patch, 'FaceColor', 'k');
% set(lWorld.edge, 'Color', 'k');
% 
% lUsne = shadedErrorBar(thresh, nanmean(lUsne_y), std(lUsne_y), 'o', 1);
% set(lUsne.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
% set(lUsne.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
% set(lUsne.edge, 'Color', 'k');
% 
% lIndia = shadedErrorBar(thresh, nanmean(lIndia_y), std(lIndia_y), 'o', 1);
% set(lIndia.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
% set(lIndia.patch, 'FaceColor', [66/255.0, 134/255.0, 244/255.0]);
% set(lIndia.edge, 'Color', 'k');
% 
% lTropics = shadedErrorBar(thresh, nanmean(lTropics_y), std(lTropics_y), 'o', 1);
% set(lTropics.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
% set(lTropics.patch, 'FaceColor', [255/255.0, 108/255.0, 71/255.0]);
% set(lTropics.edge, 'Color', 'k');

xlabel('Percentile', 'FontSize', 28);
ylabel(['Temperature change (' char(176) 'C)'], 'FontSize', 28);
set(gca, 'FontSize', 28);
set(gca, 'XTick', [1 25 50 75 99]);
ylim([0 6]);
xlim([0 100]);

legend([lWorld, lTropics, lUsne, lIndia, lChina], 'World', 'Tropics', 'U.S. Northeast', 'India', 'China');

subplot(1,2,2);
hold on;
perc1_y = squeeze(nanmean(nanmean(chgData(latIndexRangeWorld, lonIndexRangeWorld, :, threshInd(1), :), 2), 1));
perc50_y = squeeze(nanmean(nanmean(chgData(latIndexRangeWorld, lonIndexRangeWorld, :, threshInd(3), :), 2), 1));
perc99_y = squeeze(nanmean(nanmean(chgData(latIndexRangeWorld, lonIndexRangeWorld, :, threshInd(5), :), 2), 1));

perc1 = shadedErrorBar(futurePeriodYears, nanmean(perc1_y), std(perc1_y), 'o', 1);
set(perc1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(perc1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(perc1.edge, 'Color', 'k');

perc50 = shadedErrorBar(futurePeriodYears, nanmean(perc50_y), std(perc50_y), 'o', 1);
set(perc50.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(perc50.patch, 'FaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(perc50.edge, 'Color', 'k');

perc99 = shadedErrorBar(futurePeriodYears, nanmean(perc99_y), std(perc99_y), 'o', 1);
set(perc99.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(perc99.patch, 'FaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(perc99.edge, 'Color', 'k');

%plot(futurePeriodYears, squeeze(nanmean(nanmean(chgData(:,:,threshInd(1),:), 2), 1)), 'b');
%plot(futurePeriodYears, squeeze(nanmean(nanmean(chgData(:,:,threshInd(3),:), 2), 1)), 'k');
%plot(futurePeriodYears, squeeze(nanmean(nanmean(chgData(:,:,threshInd(5),:), 2), 1)), 'r');
set(gca, 'FontSize', 28);
ylim([0 6]);

legend([perc1.mainLine, perc50.mainLine, perc99.mainLine], '1st percentile', '50th percentile', '99th percentile');





