
load 2017-nile-climate/output/pe-era-interim.mat;
eraPE = peSeasonal;

load 2017-nile-climate/output/pe-ncep-reanalysis.mat;
ncepPE = peSeasonal;

regionBounds = [[2 32]; [25, 44]];
regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

% latGldas = gldas{1};
% lonGldas = gldas{2};
% [latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% [latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

load lat;
load lon;

[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

latIndsNorth = latIndsNorth-latInds(1)+1;
lonIndsNorth = lonIndsNorth-lonInds(1)+1;

latIndsSouth = latIndsSouth-latInds(1)+1;
lonIndsSouth = lonIndsSouth-lonInds(1)+1;

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

southTrends = zeros(4, 2);
southSig = zeros(4, 2);
southConfint = zeros(4, 2, 2);
       
for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPEEra = squeeze(nanmean(nanmean(eraPE{season}(latIndsSouth, lonIndsSouth, :), 2), 1));
    regionalPENcep = squeeze(nanmean(nanmean(ncepPE{season}(latIndsSouth, lonIndsSouth, :), 2), 1));
%     regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsSouthGldas, lonIndsSouthGldas, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    
    p1 = plot(regionalPEEra, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPEEra))', regionalPEEra, 'poly1');
    if Mann_Kendall(regionalPEEra, 0.05)
        plot(1:length(regionalPEEra), f(1:length(regionalPEEra)), '--', 'Color', colors(1,:));
        southSig(season, 1) = 1;
    end
    southTrends(season, 1) = f.p1;
    c = confint(f);
    southConfint(season, 1, :) = c(:,1);
    
    p2 = plot(regionalPENcep, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPENcep))', regionalPENcep, 'poly1');
    if Mann_Kendall(regionalPENcep, 0.05)
        plot(1:length(regionalPENcep), f(1:length(regionalPENcep)), '--', 'Color', colors(2,:));
        southSig(season, 2) = 1;
    end
    southTrends(season, 2) = f.p1;
    c = confint(f);
    southConfint(season, 2, :) = c(:,1);
    
%     p4 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(4,:));
%     f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
%     if Mann_Kendall(regionalPGldas, 0.05)
%         plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(4,:));
%         southSig(season, 4) = 1;
%     end
%     southTrends(season, 4) = f.p1;
%     c = confint(f);
%     southConfint(season, 4, :) = c(:,1);
    
    set(gca, 'FontSize', 40);
    title(['South, season ' num2str(season)]);
    ylim([-5 5]);
    ylabel('mm/day');
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPEEra) length(regionalPENcep)]);
    X = [regionalPEEra(1:maxlen) regionalPENcep(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2], {'ERA-Interim', 'NCEP II'});
    set(leg, 'location', 'northeast');
    export_fig(['pe-trends-' num2str(season) '-south.eps']);
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
displace = [-.1 0 .1];
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
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'northwest');
title('South');

set(gcf, 'Position', get(0,'Screensize'));
export_fig('pe-dataset-corr-south.eps');
close all;

northTrends = zeros(4, 4);
northSig = zeros(4, 4);
northConfint = zeros(4, 4, 2);

for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(gpcp{3}(latIndsNorthGpcp, lonIndsNorthGpcp, :, seasons(season, :)), 4), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(era{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(ncepPr{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsNorthGldas, lonIndsNorthGldas, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    p1 = plot(regionalPGpcp, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPGpcp))', regionalPGpcp, 'poly1');
    if Mann_Kendall(regionalPGpcp, 0.05)
        plot(1:length(regionalPGpcp), f(1:length(regionalPGpcp)), '--', 'Color', colors(1,:));
        northSig(season, 1) = 1;
    end
    northTrends(season, 1) = f.p1;
    c = confint(f);
    northConfint(season, 1, :) = c(:,1);
    
    p2 = plot(regionalPEra, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPEra))', regionalPEra, 'poly1');
    if Mann_Kendall(regionalPEra, 0.05)
        plot(1:length(regionalPEra), f(1:length(regionalPEra)), '--', 'Color', colors(2,:));
        northSig(season, 2) = 1;
    end
    northTrends(season, 2) = f.p1;
    c = confint(f);
    northConfint(season, 2, :) = c(:,1);
    
    p3 = plot(regionalPNcep, 'LineWidth', 2, 'Color', colors(3,:));
    f = fit((1:length(regionalPNcep))', regionalPNcep, 'poly1');
    if Mann_Kendall(regionalPNcep, 0.05)
        plot(1:length(regionalPNcep), f(1:length(regionalPNcep)), '--', 'Color', colors(3,:));
        northSig(season, 3) = 1;
    end
    northTrends(season, 3) = f.p1;
    c = confint(f);
    northConfint(season, 3, :) = c(:,1);
    
    p4 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(4,:));
    f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
    if Mann_Kendall(regionalPGldas, 0.05)
        plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(4,:));
        northSig(season, 4) = 1;
    end
    northTrends(season, 4) = f.p1;
    c = confint(f);
    northConfint(season, 4, :) = c(:,1);
    
    set(gca, 'FontSize', 40);
    title(['North, season ' num2str(season)]);
    ylim([0 10]);
    ylabel('mm/day');
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPGpcp) length(regionalPEra) length(regionalPNcep) length(regionalPGldas)]);
    X = [regionalPGpcp(1:maxlen) regionalPEra(1:maxlen) regionalPNcep(1:maxlen) regionalPGldas(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2 p3 p4], {'GPCP', 'ERA-Interim', 'NCEP II', 'GLDAS'});
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
displace = [-.12 -.02 .06 .14];
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
ylabel('Trend (mm/day/decade)');
legend(legItems, {'GPCP', 'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'northwest');
title('North');
set(gcf, 'Position', get(0,'Screensize'));
export_fig pr-dataset-corr-north.eps;
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