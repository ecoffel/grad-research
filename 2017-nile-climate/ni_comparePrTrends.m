fprintf('loading data...\n');
gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1980, 'endYear', 2016);

lat = gpcp{1};
lon = gpcp{2};
data = gpcp{3};

plotMap = false;

regionBoundsNorth = [[13 32]; [29, 34]];
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalP = squeeze(nanmean(nanmean(nanmean(data(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalP, 'LineWidth', 2);
    if Mann_Kendall(regionTotalP, 0.05)
        f = fit((1:length(regionTotalP))', regionTotalP, 'poly1');
        plot(1:length(regionTotalP), f(1:length(regionTotalP)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([0 6]);
    ylabel('mm/day');
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-gpcp-south.eps;
close all;

figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalP = squeeze(nanmean(nanmean(nanmean(data(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalP, 'LineWidth', 2);
    if Mann_Kendall(regionTotalP, 0.05)
        f = fit((1:length(regionTotalP))', regionTotalP, 'poly1');
        plot(1:length(regionTotalP), f(1:length(regionTotalP)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([0 6]);
    ylabel('mm/day');
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-chg-gpcp-north.eps;
close all;

if plotMap
    trend = [];
    sig = [];

    fprintf('processing trends...\n');
    for xlat = 1:size(lat,1)
        for ylon = 1:size(lat, 2)
            for season = 1:size(seasons, 1)
                d = squeeze(data(xlat, ylon, :, seasons(season,:)));
                d = d ./ nanmean(d) .* 100;
                nn = find(~isnan(d));
                d = d(nn);
                if length(d) < 30
                    continue; 
                end

                f = fit((1:length(d))', d, 'poly1');
                trend(xlat, ylon, season) = f.p1;
                sig(xlat, ylon, season) = Mann_Kendall(d, 0.05);
            end
        end
    end

    for season = 1:size(seasons, 1)

        result = {lat(latIndsSouth,lonIndsSouth), lon(latIndsSouth,lonIndsSouth), trend(latIndsSouth,lonIndsSouth,season)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-3 3], ...
                          'cbXTicks', -3:1:3, ...
                          'plotTitle', ['Pr trend'], ...
                          'fileTitle', ['gpcp-pr-trend-' num2str(season) '.png'], ...
                          'plotXUnits', ['mm/day'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'RdBu'), ...
                          'statData', ~logical(sig(latIndsSouth,lonIndsSouth, season)), ...
                          'plotCountries', true);
        plotFromDataFile(saveData);
    end
end