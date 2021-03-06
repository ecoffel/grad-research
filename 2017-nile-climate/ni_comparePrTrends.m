regionBounds = [[2 32]; [25, 44]];
%regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsSouth = [[8 13]; [34, 40]];
regionBoundsNorth = [[13 32]; [29, 34]];

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1981, 'endYear', 2016);
end

if ~exist('era', 'var')
    fprintf('loading ERA...\n');
    era = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', 1981, 'endYear', 2016);
    era{3} = era{3} .* 1000;
    era = dailyToMonthly(era);
end

if ~exist('ncep', 'var')
    fprintf('loading NCEP...\n');
    ncep = loadDailyData('E:\data\ncep-reanalysis\output\prate\regrid\world', 'startYear', 1981, 'endYear', 2016);
    ncep{3} = ncep{3} .* 3600 .* 24;
    ncep = dailyToMonthly(ncep);
end

if ~exist('gldas', 'var')
    fprintf('loading GLDAS...\n');
    gldas = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
    gldas{3} = gldas{3} .* 3600 .* 24;
end

if ~exist('chirps', 'var')
    fprintf('loading CHIRPS...\n');
    chirps = [];
    
    % load pre-processed chirps with nile region selected
    for year = 1981:1:2016
        fprintf('chirps year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-' num2str(year) '.mat']);
        chirpsPr{3} = chirpsPr{3};
        
        if length(chirps) == 0
            chirps = chirpsPr{3};
        else
            chirps = cat(4, chirps, chirpsPr{3});
        end
        
        clear chirpsPr;
    end
    % flip to (x, y, year, month)
    chirps = permute(chirps, [1 2 4 3]);
    % add initial year to align time series
%     chirps = padarray(chirps,[0 0 1 0],'pre');
%     % remove zeros
%     chirps(chirps == 0) = NaN;
end


latGpcp = gpcp{1};
lonGpcp = gpcp{2};
[latIndsNorthGpcp, lonIndsNorthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGpcp, lonIndsSouthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

latGldas = gldas{1};
lonGldas = gldas{2};
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

% load global chirps lat/lon grids
load lat-chirps;
load lon-chirps;

[latIndChirps, lonIndChirps] = latLonIndexRange({latChirps, lonChirps, []}, regionBounds(1,:), regionBounds(2,:));
[latIndChirpsNorth, lonIndChirpsNorth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndChirpsSouth, lonIndChirpsSouth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndChirpsNorth = latIndChirpsNorth - latIndChirps(1) + 1;
lonIndChirpsNorth = lonIndChirpsNorth - lonIndChirps(1) + 1;
latIndChirpsSouth = latIndChirpsSouth - latIndChirps(1) + 1;
lonIndChirpsSouth = lonIndChirpsSouth - lonIndChirps(1) + 1;

lat = ncep{1};
lon = ncep{2};
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];
       
load wettest-season-ncep;
wettestSeasonNorth = mode(reshape(wettestSeason(latIndsNorth, lonIndsNorth), [numel(wettestSeason(latIndsNorth, lonIndsNorth)), 1]));
wettestSeasonSouth = mode(reshape(wettestSeason(latIndsSouth, lonIndsSouth), [numel(wettestSeason(latIndsSouth, lonIndsSouth)), 1]));

southTrends = zeros(4, 5);
southSig = zeros(4, 5);
southConfint = zeros(4, 5, 2);
       
for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(gpcp{3}(latIndsSouthGpcp, lonIndsSouthGpcp, :, seasons(season, :)), 4), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(era{3}(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(ncep{3}(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsSouthGldas, lonIndsSouthGldas, :, seasons(season, :)), 4), 2), 1));
    regionalPChirps = squeeze(nanmean(nanmean(nanmean(chirps(latIndChirpsSouth, lonIndChirpsSouth, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    p1 = plot(regionalPGpcp, 'LineWidth', 2, 'Color', colors(4,:));
    f = fit((1:length(regionalPGpcp))', regionalPGpcp, 'poly1');
    if Mann_Kendall(regionalPGpcp, 0.05)
        plot(1:length(regionalPGpcp), f(1:length(regionalPGpcp)), '--', 'Color', colors(4,:));
        southSig(season, 4) = 1;
    end
    southTrends(season, 4) = f.p1;
    c = confint(f);
    southConfint(season, 4, :) = c(:,1);
    
    p2 = plot(regionalPEra, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPEra))', regionalPEra, 'poly1');
    if Mann_Kendall(regionalPEra, 0.05)
        plot(1:length(regionalPEra), f(1:length(regionalPEra)), '--', 'Color', colors(1,:));
        southSig(season, 1) = 1;
    end
    southTrends(season, 1) = f.p1;
    c = confint(f);
    southConfint(season, 1, :) = c(:,1);
    
    p3 = plot(regionalPNcep, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPNcep))', regionalPNcep, 'poly1');
    if Mann_Kendall(regionalPNcep, 0.05)
        plot(1:length(regionalPNcep), f(1:length(regionalPNcep)), '--', 'Color', colors(2,:));
        southSig(season, 2) = 1;
    end
    southTrends(season, 2) = f.p1;
    c = confint(f);
    southConfint(season, 2, :) = c(:,1);
    
    p4 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(3,:));
    f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
    if Mann_Kendall(regionalPGldas, 0.05)
        plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(3,:));
        southSig(season, 3) = 1;
    end
    southTrends(season, 3) = f.p1;
    c = confint(f);
    southConfint(season, 3, :) = c(:,1);
    
    p5 = plot(regionalPChirps, 'LineWidth', 2, 'Color', colors(5,:));
    f = fit((1:length(regionalPChirps))', regionalPChirps, 'poly1');
    if Mann_Kendall(regionalPChirps, 0.05)
        plot(1:length(regionalPChirps), f(1:length(regionalPChirps)), '--', 'Color', colors(5,:));
        southSig(season, 5) = 1;
    end
    southTrends(season, 5) = f.p1;
    c = confint(f);
    southConfint(season, 5, :) = c(:,1);
    
    set(gca, 'FontSize', 40);
    title(['South, season ' num2str(season)]);
    ylim([0 10]);
    ylabel('mm/day');
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPGpcp) length(regionalPEra) length(regionalPNcep) length(regionalPGldas) length(regionalPChirps)]);
    X = [regionalPGpcp(1:maxlen) regionalPEra(1:maxlen) regionalPNcep(1:maxlen) regionalPGldas(1:maxlen) regionalPChirps(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2 p3 p4 p5], {'GPCP', 'ERA-Interim', 'NCEP II', 'GLDAS', 'CHIRPS-v2'});
    set(leg, 'location', 'northeast');
    export_fig(['pr-trends-' num2str(season) '-south.eps']);
    close all;
end

% /year -> /decade
southTrends = southTrends .* 10;
southConfint = southConfint .* 10;

figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.2 -.1 .0 .1 .2];
for d = 1:size(southSig, 2)
    for s = 1:size(southSig, 1)
        e = errorbar(s+displace(d), southTrends(s, d), southTrends(s,d)-southConfint(s,d,1), southConfint(s,d,2)-southTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), southTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if southSig(s, d)
            plot(s+displace(d), southTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', [-1 -.75 -.5 -.25 0 .25 .5 .75 1]);
xlim([.5 4.5]);
ylim([-1 1]);
ylabel('Trend (mm/day/decade)');
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'GPCP', 'CHIRPS-v2'}, 'location', 'northwest');
title('South');

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
ax.XTickLabels{wettestSeasonSouth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonSouth}];

set(gcf, 'Position', get(0,'Screensize'));
export_fig('pr-trends-south.eps');
close all;

northTrends = zeros(4, 4);
northSig = zeros(4, 4);
northConfint = zeros(4, 4, 2);

for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(gpcp{3}(latIndsNorthGpcp, lonIndsNorthGpcp, :, seasons(season, :)), 4), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(era{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(ncep{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsNorthGldas, lonIndsNorthGldas, :, seasons(season, :)), 4), 2), 1));
    regionalPChirps = squeeze(nanmean(nanmean(nanmean(chirps(latIndChirpsNorth, lonIndChirpsNorth, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    p1 = plot(regionalPGpcp, 'LineWidth', 2, 'Color', colors(4,:));
    f = fit((1:length(regionalPGpcp))', regionalPGpcp, 'poly1');
    if Mann_Kendall(regionalPGpcp, 0.05)
        plot(1:length(regionalPGpcp), f(1:length(regionalPGpcp)), '--', 'Color', colors(4,:));
        northSig(season, 4) = 1;
    end
    northTrends(season, 4) = f.p1;
    c = confint(f);
    northConfint(season, 4, :) = c(:,1);
    
    p2 = plot(regionalPEra, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPEra))', regionalPEra, 'poly1');
    if Mann_Kendall(regionalPEra, 0.05)
        plot(1:length(regionalPEra), f(1:length(regionalPEra)), '--', 'Color', colors(1,:));
        northSig(season, 1) = 1;
    end
    northTrends(season, 1) = f.p1;
    c = confint(f);
    northConfint(season, 1, :) = c(:,1);
    
    p3 = plot(regionalPNcep, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPNcep))', regionalPNcep, 'poly1');
    if Mann_Kendall(regionalPNcep, 0.05)
        plot(1:length(regionalPNcep), f(1:length(regionalPNcep)), '--', 'Color', colors(2,:));
        northSig(season, 2) = 1;
    end
    northTrends(season, 2) = f.p1;
    c = confint(f);
    northConfint(season, 2, :) = c(:,1);
    
    p4 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(3,:));
    f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
    if Mann_Kendall(regionalPGldas, 0.05)
        plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(3,:));
        northSig(season, 3) = 1;
    end
    northTrends(season, 3) = f.p1;
    c = confint(f);
    northConfint(season, 3, :) = c(:,1);
    
    p5 = plot(regionalPChirps, 'LineWidth', 2, 'Color', colors(5,:));
    f = fit((1:length(regionalPChirps))', regionalPChirps, 'poly1');
    if Mann_Kendall(regionalPChirps, 0.05)
        plot(1:length(regionalPChirps), f(1:length(regionalPChirps)), '--', 'Color', colors(5,:));
        northSig(season, 5) = 1;
    end
    northTrends(season, 5) = f.p1;
    c = confint(f);
    northConfint(season, 5, :) = c(:,1);
    
    set(gca, 'FontSize', 40);
    title(['North, season ' num2str(season)]);
    ylim([0 10]);
    ylabel('mm/day');
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPGpcp) length(regionalPEra) length(regionalPNcep) length(regionalPGldas) length(regionalPChirps)]);
    X = [regionalPGpcp(1:maxlen) regionalPEra(1:maxlen) regionalPNcep(1:maxlen) regionalPGldas(1:maxlen) regionalPChirps(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2 p3 p4 p5], {'GPCP', 'ERA-Interim', 'NCEP II', 'GLDAS', 'CHIRPS-v2'});
    set(leg, 'location', 'northeast');
    export_fig(['pr-trends-' num2str(season) '-north.eps']);
    close all;
end

% /year -> /decade
northTrends = northTrends .* 10;
northConfint = northConfint .* 10;

figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.2 -.1 0 .1 .2];
for d = 1:size(northSig, 2)
    for s = 1:size(northSig, 1)
        e = errorbar(s+displace(d), northTrends(s, d), northTrends(s,d)-northConfint(s,d,1), northConfint(s,d,2)-northTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), northTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if northSig(s, d)
            plot(s+displace(d), northTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', [-1 -.75 -.5 -.25 0 .25 .5 .75 1]);
xlim([.5 4.5]);
ylim([-1 1]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
ax.XTickLabels{wettestSeasonNorth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonNorth}];

ylabel('Trend (mm/day/decade)');
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'GPCP', 'CHIRPS-v2'}, 'location', 'northwest');
title('North');
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-trends-north.eps;
close all;

if plotMap
    trend = [];
    sig = [];

    fprintf('processing trends...\n');
    for xlat = 1:size(latGpcp,1)
        for ylon = 1:size(latGpcp, 2)
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

        result = {latGpcp(latIndsSouth,lonIndsSouthGpcp), lon(latIndsSouth,lonIndsSouthGpcp), trend(latIndsSouth,lonIndsSouthGpcp,season)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-3 3], ...
                          'cbXTicks', -3:1:3, ...
                          'plotTitle', ['Pr trend'], ...
                          'fileTitle', ['gpcp-pr-trend-' num2str(season) '.png'], ...
                          'plotXUnits', ['mm/day'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'RdBu'), ...
                          'statData', ~logical(sig(latIndsSouth,lonIndsSouthGpcp, season)), ...
                          'plotCountries', true);
        plotFromDataFile(saveData);
    end
end