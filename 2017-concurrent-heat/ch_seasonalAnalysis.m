
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

usDataAnnMax = squeeze(nanmean(nanmean(nanmean(annMax(latIndexRangeUsne, lonIndexRangeUsne, :), 3), 2), 1));
europeDataAnnMax = squeeze(nanmean(nanmean(nanmean(annMax(latIndexRangeEurope, lonIndexRangeEurope, :), 3), 2), 1));
amazonDataAnnMax = squeeze(nanmean(nanmean(nanmean(annMax(latIndexRangeAmazon, lonIndexRangeAmazon, :), 3), 2), 1));
indiaDataAnnMax = squeeze(nanmean(nanmean(nanmean(annMax(latIndexRangeIndia, lonIndexRangeIndia, :), 3), 2), 1));;

for m = 1:12
    usDataSeaMax(m) = squeeze(nanmean(nanmean(nanmean(seaMax(latIndexRangeUsne, lonIndexRangeUsne, :, m), 3), 2), 1));
    europeDataSeaMax(m) = squeeze(nanmean(nanmean(nanmean(seaMax(latIndexRangeEurope, lonIndexRangeEurope, :, m), 3), 2), 1));
    amazonDataSeaMax(m) = squeeze(nanmean(nanmean(nanmean(seaMax(latIndexRangeAmazon, lonIndexRangeAmazon, :, m), 3), 2), 1));
    indiaDataSeaMax(m) = squeeze(nanmean(nanmean(nanmean(seaMax(latIndexRangeIndia, lonIndexRangeIndia, :, m), 3), 2), 1));
end

figure('Color',[1,1,1]);
hold on;
grid on;
box on;
axis square;
p1 = plot(1:12, usDataSeaMax, 'LineWidth', 3, 'Color', 'k');
plot(1:12, ones(1,12) .* usDataAnnMax, '--k', 'LineWidth', 2);

p2 = plot(1:12, europeDataSeaMax, 'LineWidth', 3, 'Color', 'b');
plot(1:12, ones(1,12) .* europeDataAnnMax, '--b', 'LineWidth', 2);

p3 = plot(1:12, amazonDataSeaMax, 'LineWidth', 3, 'Color', 'm');
plot(1:12, ones(1,12) .* amazonDataAnnMax, '--m', 'LineWidth', 2);

p4 = plot(1:12, indiaDataSeaMax, 'LineWidth', 3, 'Color', 'r');
plot(1:12, ones(1,12) .* indiaDataAnnMax, '--r', 'LineWidth', 2);

xlabel('Month', 'FontSize', 24);
ylabel(['Maximum temperature change (' char(176) 'C)'], 'FontSize', 24);
set(gca, 'FontSize', 24);

legend([p1, p2, p3, p4], 'us', 'europe', 'amazon', 'india');