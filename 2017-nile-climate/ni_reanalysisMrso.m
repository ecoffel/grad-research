dataset = 'ncep-reanalysis';
var = 'soilw10';

fprintf('loading data...\n');
mrso = loadDailyData(['E:\data\' dataset '\output\' var '\regrid\world'], 'startYear', 1980, 'endYear', 2016);
mrso = dailyToMonthly(mrso);

lat = mrso{1};
lon = mrso{2};
data = mrso{3};

plotMap = false;

regionBoundsNorth = [[13 32]; [29, 34]];
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

mrsoNorth = {};
mrsoSouth = {};
       
figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalMrso = squeeze(nanmean(nanmean(nanmean(data(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    
    mrsoSouth{season} = regionTotalMrso;
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalMrso, 'LineWidth', 2);
    if Mann_Kendall(regionTotalMrso, 0.05)
        f = fit((1:length(regionTotalMrso))', regionTotalMrso, 'poly1');
        plot(1:length(regionTotalMrso), f(1:length(regionTotalMrso)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([-1 1]);
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['pr-chg-' dataset '-south.eps']);
close all;

figure('Color', [1,1,1]);
for season = 1:size(seasons, 1)
    regionTotalMrso = squeeze(nanmean(nanmean(nanmean(data(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    
    mrsoNorth{season} = regionTotalMrso;
    
    subplot(2,2,season);
    hold on;
    axis square;
    grid on;
    box on;
    plot(regionTotalMrso, 'LineWidth', 2);
    if Mann_Kendall(regionTotalMrso, 0.05)
        f = fit((1:length(regionTotalMrso))', regionTotalMrso, 'poly1');
        plot(1:length(regionTotalMrso), f(1:length(regionTotalMrso)), '--');
    end
    title(['Season ' num2str(season)]);
    ylim([-1 1]);
    xlabel('year');
end
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['pr-chg-' dataset '-north.eps']);
close all;

save(['2017-nile-climate/mrso-' dataset '-north.mat'], 'mrsoNorth');
save(['2017-nile-climate/mrso-' dataset '-south.mat'], 'mrsoSouth');
