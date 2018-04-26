
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'historical';
timePeriod = [1980 2004];



if ~exist('era', 'var')
    fprintf('loading ERA...\n');
    era = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1980, 'endYear', 2016);
    era{3} = era{3} - 273.15;
    era = dailyToMonthly(era);
end

if ~exist('ncep', 'var')
    fprintf('loading NCEP...\n');
    ncep = loadDailyData('E:\data\ncep-reanalysis\output\tmax\regrid\world', 'startYear', 1980, 'endYear', 2016);
    ncep{3} = ncep{3} - 273.15;
    ncep = dailyToMonthly(ncep);
end

if ~exist('gldas', 'var')
    fprintf('loading GLDAS...\n');
    gldas = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1980, 'endYear', 2010);
    gldas{3} = gldas{3} - 273.15;
end

if ~exist('tempCpc', 'var')   
    tempCpc = [];
    for year = 1980:2016
        fprintf('cpc year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\temp-monthly-cpc-' num2str(year) '.mat']);
        cpcTemp{3} = cpcTemp{3};

        if length(tempCpc) == 0
            tempCpc = cpcTemp{3};
        else
            tempCpc = cat(4, tempCpc, cpcTemp{3});
        end

        clear cpcTemp;
    end
    tempCpc = permute(tempCpc, [1 2 4 3]);
end

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

latGldas = gldas{1};
lonGldas = gldas{2};
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));


lat = ncep{1};
lon = ncep{2};

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsSouthRel = latIndsSouth-latInds(1)+1;
latIndsNorthRel = latIndsNorth-latInds(1)+1;
lonIndsSouthRel = lonIndsSouth-lonInds(1)+1;
lonIndsNorthRel = lonIndsNorth-lonInds(1)+1;


cmip5 = [];
for m = 1:length(models)
    fprintf('processing %s...\n', models{m});
    t = loadDailyData(['E:\data\cmip5\output\' models{m} '\r1i1p1\historical\tasmax\regrid\world'], 'startYear', 1980, 'endYear', 2004);
    t = dailyToMonthly(t);
    t = t{3}(latInds, lonInds, :, :);
    
    cmip5(:,:,:,:,m) = t;
end

plotMap = false;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

load('hottest-season-ncep.mat');
hottestSeasonNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSeasonSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));
       
southTrends = zeros(4, 4);
southSig = zeros(4, 4);
southConfint = zeros(4, 4, 2);
       
for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPEra = squeeze(nanmean(nanmean(nanmean(era{3}(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(ncep{3}(latIndsSouth, lonIndsSouth, :, seasons(season, :)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsSouthGldas, lonIndsSouthGldas, :, seasons(season, :)), 4), 2), 1));
    regionalPCpc = squeeze(nanmean(nanmean(nanmean(tempCpc(latIndsSouthRel, lonIndsSouthRel, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    
    p1 = plot(regionalPEra, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPEra))', regionalPEra, 'poly1');
    if Mann_Kendall(regionalPEra, 0.05)
        plot(1:length(regionalPEra), f(1:length(regionalPEra)), '--', 'Color', colors(1,:));
        southSig(season, 1) = 1;
    end
    southTrends(season, 1) = f.p1;
    c = confint(f);
    southConfint(season, 1, :) = c(:,1);
    
    p2 = plot(regionalPNcep, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPNcep))', regionalPNcep, 'poly1');
    if Mann_Kendall(regionalPNcep, 0.05)
        plot(1:length(regionalPNcep), f(1:length(regionalPNcep)), '--', 'Color', colors(2,:));
        southSig(season, 2) = 1;
    end
    southTrends(season, 2) = f.p1;
    c = confint(f);
    southConfint(season, 2, :) = c(:,1);
    
    p3 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(3,:));
    f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
    if Mann_Kendall(regionalPGldas, 0.05)
        plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(3,:));
        southSig(season, 3) = 1;
    end
    southTrends(season, 3) = f.p1;
    c = confint(f);
    southConfint(season, 3, :) = c(:,1);
    
    p4 = plot(regionalPCpc, 'LineWidth', 2, 'Color', colors(4,:));
    f = fit((1:length(regionalPCpc))', regionalPCpc, 'poly1');
    if Mann_Kendall(regionalPCpc, 0.05)
        plot(1:length(regionalPCpc), f(1:length(regionalPCpc)), '--', 'Color', colors(4,:));
        southSig(season, 4) = 1;
    end
    southTrends(season, 4) = f.p1;
    c = confint(f);
    southConfint(season, 4, :) = c(:,1);
    
    
    set(gca, 'FontSize', 40);
    title(['South, season ' num2str(season)]);
    ylim([20 35]);
    ylabel([char(176) 'C']);
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPEra) length(regionalPNcep) length(regionalPGldas) length(regionalPCpc)]);
    X = [regionalPEra(1:maxlen) regionalPNcep(1:maxlen) regionalPGldas(1:maxlen) regionalPCpc(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS', 'CPC'});
    set(leg, 'location', 'northeast');
    export_fig(['temp-trends-' num2str(season) '-south.eps']);
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
displace = [-.15 -.05 .05 .15];
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

% set hottest season xtick label red
ax = gca;
ax.TickLabelInterpreter = 'tex';
ax.XTickLabels{hottestSeasonSouth} = ['\color{red} ' ax.XTickLabels{hottestSeasonSouth}];

ylabel(['Trend (' char(176) 'C/decade)']);
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'CPC'}, 'location', 'northeast');
title('South');
set(gcf, 'Position', get(0,'Screensize'));
export_fig('temp-trends-south.eps');
close all;

northTrends = zeros(4, 4);
northSig = zeros(4, 4);
northConfint = zeros(4, 4, 2);

for season = 1:size(seasons, 1)
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');

    regionalPEra = squeeze(nanmean(nanmean(nanmean(era{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(ncep{3}(latIndsNorth, lonIndsNorth, :, seasons(season, :)), 4), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(gldas{3}(latIndsNorthGldas, lonIndsNorthGldas, :, seasons(season, :)), 4), 2), 1));
    regionalPCpc = squeeze(nanmean(nanmean(nanmean(tempCpc(latIndsNorthRel, lonIndsNorthRel, :, seasons(season, :)), 4), 2), 1));
    
    hold on;
    axis square;
    grid on;
    box on;
    p1 = plot(regionalPEra, 'LineWidth', 2, 'Color', colors(1,:));
    f = fit((1:length(regionalPEra))', regionalPEra, 'poly1');
    if Mann_Kendall(regionalPEra, 0.05)
        plot(1:length(regionalPEra), f(1:length(regionalPEra)), '--', 'Color', colors(1,:));
        northSig(season, 1) = 1;
    end
    northTrends(season, 1) = f.p1;
    c = confint(f);
    northConfint(season, 1, :) = c(:,1);
    
    p2 = plot(regionalPNcep, 'LineWidth', 2, 'Color', colors(2,:));
    f = fit((1:length(regionalPNcep))', regionalPNcep, 'poly1');
    if Mann_Kendall(regionalPNcep, 0.05)
        plot(1:length(regionalPNcep), f(1:length(regionalPNcep)), '--', 'Color', colors(2,:));
        northSig(season, 2) = 1;
    end
    northTrends(season, 2) = f.p1;
    c = confint(f);
    northConfint(season, 2, :) = c(:,1);
    
    p3 = plot(regionalPGldas, 'LineWidth', 2, 'Color', colors(3,:));
    f = fit((1:length(regionalPGldas))', regionalPGldas, 'poly1');
    if Mann_Kendall(regionalPGldas, 0.05)
        plot(1:length(regionalPGldas), f(1:length(regionalPGldas)), '--', 'Color', colors(3,:));
        northSig(season, 3) = 1;
    end
    northTrends(season, 3) = f.p1;
    c = confint(f);
    northConfint(season, 3, :) = c(:,1);
    
    p4 = plot(regionalPCpc, 'LineWidth', 2, 'Color', colors(4,:));
    f = fit((1:length(regionalPCpc))', regionalPCpc, 'poly1');
    if Mann_Kendall(regionalPCpc, 0.05)
        plot(1:length(regionalPCpc), f(1:length(regionalPCpc)), '--', 'Color', colors(4,:));
        northSig(season, 4) = 1;
    end
    northTrends(season, 4) = f.p1;
    c = confint(f);
    northConfint(season, 4, :) = c(:,1);
    
    set(gca, 'FontSize', 40);
    title(['North, season ' num2str(season)]);
    ylim([10 40]);
    ylabel([char(176) 'C']);
    xlabel('year');
    % calculate correlation across 4 datasets
    maxlen = min([length(regionalPEra) length(regionalPNcep) length(regionalPGldas)]);
    X = [regionalPEra(1:maxlen) regionalPNcep(1:maxlen) regionalPGldas(1:maxlen)];
    corr(X)
    
    set(gcf, 'Position', get(0,'Screensize'));
    leg = legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS', 'CPC'});
    set(leg, 'location', 'northeast');
    export_fig(['temp-trends-' num2str(season) '-north.eps']);
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
displace = [-.15 -.05 .05 .15];
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

% set hottest season xtick label red
ax = gca;
ax.TickLabelInterpreter = 'tex';
ax.XTickLabels{hottestSeasonNorth} = ['\color{red} ' ax.XTickLabels{hottestSeasonNorth}];

ylabel(['Trend (' char(176) 'C/decade)']);
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'CPC'}, 'location', 'southeast');
title('North');
set(gcf, 'Position', get(0,'Screensize'));
export_fig temp-trends-north.eps;
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