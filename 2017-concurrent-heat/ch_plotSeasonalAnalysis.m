
load waterGrid;
load lat;
load lon;
waterGrid=logical(waterGrid);

[latIndexRangeWorld, lonIndexRangeWorld] = latLonIndexRange({lat,lon,[]}, [-90 90], [0 360]);
[latIndexRangeUsne, lonIndexRangeUsne] = latLonIndexRange({lat,lon,[]}, [30 55], [-100 -62] + 360);
[latIndexRangeEurope, lonIndexRangeEurope] = latLonIndexRange({lat,lon,[]}, [35, 60], [-10+360, 40]);
[latIndexRangeAmazon, lonIndexRangeAmazon] = latLonIndexRange({lat,lon,[]}, [-20, 10], [-70, -40]+360);
[latIndexRangeIndia, lonIndexRangeIndia] = latLonIndexRange({lat,lon,[]}, [8, 34], [67, 90]);
[latIndexRangeTropics, lonIndexRangeTropics] = latLonIndexRange({lat,lon,[]}, [-20 20], [0 360]);

load chg-data\chgData-cmip5-seasonal-monthly-max-rcp85-2070-2080.mat
seaMax = chgData;

load chg-data\chgData-cmip5-seasonal-monthly-mean-max-rcp85-2070-2080.mat
seaMeanMax = chgData;

load chg-data\chgData-cmip5-ann-max-rcp85-2070-2080.mat
annMax = chgData;

maps = false;

if maps
    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        a=annMax-meanMax(:,:,:,m);
        plotModelData({lat,lon,nanmean(a,3)},'world', 'caxis', [-3 3],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;

    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        plotModelData({lat,lon,nanmean(seaMeanMax(:,:,:,m),3)},'world', 'caxis', [0 9],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;

    figure;
    hold on;
    for m=1:12
        subplot(3,4,m);
        hold on;
        plotModelData({lat,lon,nanmean(seaMax(:,:,:,m),3)},'world', 'caxis', [0 9],'nonewfig',true);
        title(num2str(m),'FontSize',30);
    end
    tightfig;
end

usDataSeaMax = [];
europeDataSeaMax = [];
amazonDataSeaMax = [];
indiaDataSeaMax = [];

usDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeUsne, lonIndexRangeUsne, :), 2), 1));
europeDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeEurope, lonIndexRangeEurope, :), 2), 1));
amazonDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeAmazon, lonIndexRangeAmazon, :), 2), 1));
indiaDataAnnMax = squeeze(nanmean(nanmean(annMax(latIndexRangeIndia, lonIndexRangeIndia, :), 2), 1));;

for m = 1:12
    usDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeUsne, lonIndexRangeUsne, :, m), 2), 1));
    europeDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeEurope, lonIndexRangeEurope, :, m), 2), 1));
    amazonDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeAmazon, lonIndexRangeAmazon, :, m), 2), 1));
    indiaDataSeaMax(m, :) = squeeze(nanmean(nanmean(seaMax(latIndexRangeIndia, lonIndexRangeIndia, :, m), 2), 1));
end

usDataSeaMax = sort(usDataSeaMax, 2);
europeDataSeaMax = sort(europeDataSeaMax, 2);
amazonDataSeaMax = sort(amazonDataSeaMax, 2);
indiaDataSeaMax = sort(indiaDataSeaMax, 2);

% show 25th - 75th percentile range
lowInd = round(0.25 * size(usDataSeaMax, 2));
highInd = round(0.75 * size(usDataSeaMax, 2));

figure('Color',[1,1,1]);
hold on;
grid on;
box on;
axis square;
p1 = shadedErrorBar(1:12, nanmean(usDataSeaMax, 2), range(usDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
set(p1.mainLine, 'Color', [0.4 0.4 0.4], 'LineWidth', 3);
set(p1.patch, 'FaceColor', [0.6 0.6 0.6]);
set(p1.edge, 'Color', 'w');
plot(1:12, ones(1,12) .* nanmean(usDataAnnMax), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);

p2 = shadedErrorBar(1:12, nanmean(europeDataSeaMax, 2), range(europeDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
set(p2.mainLine, 'Color', [70/255.0, 159/255.0, 242/255.0], 'LineWidth', 3);
set(p2.patch, 'FaceColor', [70/255.0, 159/255.0, 242/255.0]);
set(p2.edge, 'Color', 'w');
plot(1:12, ones(1,12) .* nanmean(europeDataAnnMax), '--', 'Color', [70/255.0, 159/255.0, 242/255.0], 'LineWidth', 2);

p3 = shadedErrorBar(1:12, nanmean(amazonDataSeaMax, 2), range(amazonDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
set(p3.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
set(p3.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
set(p3.edge, 'Color', 'w');
plot(1:12, ones(1,12) .* nanmean(amazonDataAnnMax), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

p4 = shadedErrorBar(1:12, nanmean(indiaDataSeaMax, 2), range(indiaDataSeaMax(:, lowInd:highInd), 2) ./ 2.0, '-', 1);
set(p4.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
set(p4.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
set(p4.edge, 'Color', 'w');
plot(1:12, ones(1,12) .* nanmean(indiaDataAnnMax), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
ylabel(['Maximum temperature change (' char(176) 'C)'], 'FontSize', 24);
set(gca, 'FontSize', 24);
ylim([0 8]);

legend([p1.mainLine, p2.mainLine, p3.mainLine, p4.mainLine], 'Eastern U.S.', 'Western Europe', 'Amazon', 'India');