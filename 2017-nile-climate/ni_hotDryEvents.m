plotSeasonalAnnualData = false;
north = true;

coordPairs = csvread('ni-region.txt');

timePeriod = [1980 2016];

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

if ~exist('tmaxEraRaw', 'var')
    fprintf('loading ERA temps...\n');
    tmaxEraRaw = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    tmaxEraRaw{3} = tmaxEraRaw{3} - 273.15;
    % take monthly mean
    tmaxEraRaw = dailyToMonthly(tmaxEraRaw);
end

if ~exist('prEraRaw', 'var')
    fprintf('loading ERA pr...\n');
    prEraRaw = loadDailyData('e:/data/era-interim/output/tp/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    prEraRaw{3} = prEraRaw{3} .* 1000;
    % take monthly mean
    prEraRaw = dailyToMonthly(prEraRaw);
end

if ~exist('tmaxNcepRaw', 'var')
    fprintf('loading NCEP temps...\n');
    tmaxNcepRaw = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    tmaxNcepRaw{3} = tmaxNcepRaw{3} - 273.15;
    % take monthly mean
    tmaxNcepRaw = dailyToMonthly(tmaxNcepRaw);
end

if ~exist('prNcepRaw', 'var')
    fprintf('loading NCEP pr...\n');
    prNcepRaw = loadDailyData('e:/data/ncep-reanalysis/output/prate/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    prNcepRaw{3} = prNcepRaw{3} .* 3600 .* 24;
    % take monthly mean
    prNcepRaw = dailyToMonthly(prNcepRaw);
end

if ~exist('prGpcpRaw', 'var')
    fprintf('loading GPCP pr...\n');
    prGpcpRaw = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1980, 'endYear', 2016);
    
    latGpcp = prGpcpRaw{1};
    lonGpcp = prGpcpRaw{2};
    [latIndsNorthGpcp, lonIndsNorthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
    [latIndsSouthGpcp, lonIndsSouthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
    [latIndsGpcp, lonIndsGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBounds(1,:), regionBounds(2,:));
end

if ~exist('prGldasRaw', 'var')
    fprintf('loading GLDAS pr...\n');
    prGldasRaw = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1980, 'endYear', 2010);
    prGldasRaw{3} = prGldasRaw{3} .* 3600 .* 24;
    
    latGldas = prGldasRaw{1};
    lonGldas = prGldasRaw{2};
    [latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
    [latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
    [latIndsGldas, lonIndsGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBounds(1,:), regionBounds(2,:));
end

if ~exist('tmaxGldasRaw', 'var')
    fprintf('loading GLDAS tmax...\n');
    tmaxGldasRaw = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1980, 'endYear', 2010);
    tmaxGldasRaw{3} = tmaxGldasRaw{3} - 273.15;
end

if north
    tmaxEra = tmaxEraRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    tmaxNcep = tmaxNcepRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    tmaxGldas = tmaxGldasRaw{3}(latIndsNorthGldas, lonIndsNorthGldas, :, :);

    prEra = prEraRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    prNcep = prNcepRaw{3}(latIndsNorth, lonIndsNorth, :, :);
    prGpcp = prGpcpRaw{3}(latIndsNorthGpcp, lonIndsNorthGpcp, :, :);
    prGldas = prGldasRaw{3}(latIndsNorthGldas, lonIndsNorthGldas, :, :);
else
    tmaxEra = tmaxEraRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    tmaxNcep = tmaxNcepRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    tmaxGldas = tmaxGldasRaw{3}(latIndsSouthGldas, lonIndsSouthGldas, :, :);

    prEra = prEraRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    prNcep = prNcepRaw{3}(latIndsSouth, lonIndsSouth, :, :);
    prGpcp = prGpcpRaw{3}(latIndsSouthGpcp, lonIndsSouthGpcp, :, :);
    prGldas = prGldasRaw{3}(latIndsSouthGldas, lonIndsSouthGldas, :, :);
end

numYears = (timePeriod(end)-timePeriod(1)+1);

load wettest-season-ncep;
wettestSeasonNorth = mode(reshape(wettestSeason(latIndsNorth, lonIndsNorth), [numel(wettestSeason(latIndsNorth, lonIndsNorth)), 1]));
wettestSeasonSouth = mode(reshape(wettestSeason(latIndsSouth, lonIndsSouth), [numel(wettestSeason(latIndsSouth, lonIndsSouth)), 1]));

load('hottest-season-ncep.mat');
hottestSeasonNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSeasonSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

prcTmax = 75;
prcPr = 25;

hotTrends = zeros(4, 3);
hotCI = zeros(4, 3, 2);
hotSig = zeros(4, 3);
dryTrends = zeros(4, 4);
dryCI = zeros(4, 4, 2);
drySig = zeros(4, 4);
hotDryTrends = zeros(4, 3);
hotDryCI = zeros(4, 3, 2);
hotDrySig = zeros(4, 3);

figure('Color', [1,1,1]);
colors = get(gca, 'colororder');
i = 1;
for s = 1:size(seasons, 1)
    % timeseries of current season tmax/tmin
    curTmaxEra = nanmean(tmaxEra(:, :, :, seasons(s, :)), 4);
    curPrEra = nanmean(prEra(:, :, :, seasons(s, :)), 4);
    curTmaxNcep = nanmean(tmaxNcep(:, :, :, seasons(s, :)), 4);
    curPrNcep = nanmean(prNcep(:, :, :, seasons(s, :)), 4);
    curPrGpcp = nanmean(prGpcp(:, :, :, seasons(s, :)), 4);
    curPrGldas = nanmean(prGldas(:, :, :, seasons(s, :)), 4);
    curTmaxGldas = nanmean(tmaxGldas(:, :, :, seasons(s, :)), 4);
    
    % get seasonal means over time series...
    curTmaxThreshEra = prctile(curTmaxEra, prcTmax, 3);
    curPrThreshEra = prctile(curPrEra, prcPr, 3);
    
    curTmaxThreshNcep = prctile(curTmaxNcep, prcTmax, 3);
    curPrThreshNcep = prctile(curPrNcep, prcPr, 3);
    
    curPrThreshGpcp = prctile(curPrGpcp, prcPr, 3);
    curPrThreshGldas = prctile(curPrGldas, prcPr, 3);
    curTmaxThreshGldas = prctile(curTmaxGldas, prcTmax, 3);
    
    for year = 1:size(curTmaxEra, 3)
        hotEra(year) = numel(find(curTmaxEra(:, :, year) > curTmaxThreshEra));
        dryEra(year) = numel(find(curPrEra(:, :, year) < curPrThreshEra));
        hotdryEra(year) = numel(find(curTmaxEra(:, :, year) > curTmaxThreshEra & curPrEra(:, :, year) < curPrThreshEra));
        
        hotNcep(year) = numel(find(curTmaxNcep(:, :, year) > curTmaxThreshNcep));
        dryNcep(year) = numel(find(curPrNcep(:, :, year) < curPrThreshNcep));
        hotdryNcep(year) = numel(find(curTmaxNcep(:, :, year) > curTmaxThreshNcep & curPrNcep(:, :, year) < curPrThreshNcep));
        
        dryGpcp(year) = numel(find(curPrGpcp(:, :, year) < curPrThreshGpcp));
        if year <= size(curPrGldas, 3)
            dryGldas(year) = numel(find(curPrGldas(:, :, year) < curPrThreshGldas));
            hotGldas(year) = numel(find(curTmaxGldas(:, :, year) > curTmaxThreshGldas));
            hotdryGldas(year) = numel(find(curTmaxGldas(:, :, year) > curTmaxThreshGldas & curPrGldas(:, :, year) < curPrThreshGldas));
        end
    end
    
    % normalize all counts to account for different grids
    dryEra = normr(dryEra);
    dryNcep = normr(dryNcep);
    dryGpcp = normr(dryGpcp);
    dryGldas = normr(dryGldas);
    hotEra = normr(hotEra);
    hotNcep = normr(hotNcep);
    hotGldas = normr(hotGldas);
    hotdryEra = normr(hotdryEra);
    hotdryNcep = normr(hotdryNcep);
    hotdryGldas = normr(hotdryGldas);
    
    % compute trends for datasets
    fHotEra = fit((1:length(hotEra))', hotEra', 'poly1');
    fHotNcep = fit((1:length(hotNcep))', hotNcep', 'poly1');
    fHotGldas = fit((1:length(hotGldas))', hotGldas', 'poly1');
    
    hotTrends(s, 1) = fHotEra.p1;
    hotTrends(s, 2) = fHotNcep.p1;
    hotTrends(s, 3) = fHotGldas.p1;
    
    % and get CI
    c = confint(fHotEra);
    hotCI(s, 1, :) = c(:,1);
    c = confint(fHotNcep);
    hotCI(s, 2, :) = c(:,1);
    c = confint(fHotGldas);
    hotCI(s, 3, :) = c(:,1);
    
    hotSig(s, 1) = Mann_Kendall(hotEra, .05);
    hotSig(s, 2) = Mann_Kendall(hotNcep, .05);
    hotSig(s, 3) = Mann_Kendall(hotGldas, .05);
    
    fDryEra = fit((1:length(dryEra))', dryEra', 'poly1');
    fDryNcep = fit((1:length(dryNcep))', dryNcep', 'poly1');
    fDryGldas = fit((1:length(dryGldas))', dryGldas', 'poly1');
    fDryGpcp = fit((1:length(dryGpcp))', dryGpcp', 'poly1');
    
    dryTrends(s, 1) = fDryEra.p1;
    dryTrends(s, 2) = fDryNcep.p1;
    dryTrends(s, 3) = fDryGldas.p1;
    dryTrends(s, 4) = fDryGpcp.p1;
    
    c = confint(fDryEra);
    dryCI(s, 1, :) = c(:,1);
    c = confint(fDryNcep);
    dryCI(s, 2, :) = c(:,1);
    c = confint(fDryGldas);
    dryCI(s, 3, :) = c(:,1);
    c = confint(fDryGpcp);
    dryCI(s, 4, :) = c(:,1);
    
    drySig(s, 1) = Mann_Kendall(dryEra, .05);
    drySig(s, 2) = Mann_Kendall(dryNcep, .05);
    drySig(s, 3) = Mann_Kendall(dryGldas, .05);
    drySig(s, 4) = Mann_Kendall(dryGpcp, .05);
    
    fHotDryEra = fit((1:length(hotdryEra))', hotdryEra', 'poly1');
    fHotDryNcep = fit((1:length(hotdryNcep))', hotdryNcep', 'poly1');
    fHotDryGldas = fit((1:length(hotdryGldas))', hotdryGldas', 'poly1');
    
    hotDryTrends(s, 1) = fHotDryEra.p1;
    hotDryTrends(s, 2) = fHotDryNcep.p1;
    hotDryTrends(s, 3) = fHotDryGldas.p1;
    
    c = confint(fHotDryEra);
    hotDryCI(s, 1, :) = c(:,1);
    c = confint(fHotDryNcep);
    hotDryCI(s, 2, :) = c(:,1);
    c = confint(fHotDryGldas);
    hotDryCI(s, 3, :) = c(:,1);
    
    hotDrySig(s, 1) = Mann_Kendall(hotdryEra, .05);
    hotDrySig(s, 2) = Mann_Kendall(hotdryNcep, .05);
    hotDrySig(s, 3) = Mann_Kendall(hotdryGldas, .05);
    
    if plotSeasonalAnnualData
        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        ylim([0 125]);
        p1 = plot(hotEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(hotEra, 0.05)
            plot(1:length(hotEra), fHotEra(1:length(hotEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(hotNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(hotNcep, 0.05)
            plot(1:length(hotNcep), fHotNcep(1:length(hotNcep)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        p3 = plot(hotGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(hotGldas, 0.05)
            plot(1:length(hotGldas), fHotGldas(1:length(hotGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        set(gca, 'XTick', 6:10:length(hotEra), 'XTickLabels', [1985 1995 2005 2015]);
        ylim([0 1]);
        ylabel([seasonNames{s} ' hot seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'northwest');
        if north
            export_fig(['hot-season-' num2str(s) '-north.eps']);
        else
            export_fig(['hot-season-' num2str(s) '-south.eps']);
        end
        close all;

        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        p1 = plot(dryEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(dryEra, 0.05)            
            plot(1:length(dryEra), fDryEra(1:length(dryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(dryNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(dryNcep, 0.05)
            plot(1:length(dryNcep), fDryNcep(1:length(dryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
        end
        p3 = plot(dryGpcp, 'Color', colors(4,:), 'LineWidth', 2);
        if Mann_Kendall(dryGpcp, 0.05)
            plot(1:length(dryGpcp), fDryGpcp(1:length(dryGpcp)), '--', 'Color', colors(4,:), 'LineWidth', 2);
        end
        p4 = plot(dryGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(dryGldas, 0.05)
            plot(1:length(dryGldas), fDryGldas(1:length(dryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        ylabel([seasonNames{s} ' dry seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3 p4], {'ERA-Interim', 'NCEP II', 'GPCP', 'GLDAS'}, 'location', 'northwest');
        ylim([0 1]);
        set(gca, 'XTick', 6:10:length(dryEra), 'XTickLabels', [1985 1995 2005 2015]);
        if north
            export_fig(['dry-season-' num2str(s) '-north.eps']);
        else
            export_fig(['dry-season-' num2str(s) '-south.eps']);
        end
        close all;

        figure('Color', [1,1,1]);
        hold on;
        axis square;
        box on;
        grid on;
        ylim([0 125]);
        p1 = plot(hotdryEra, 'Color', colors(1,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryEra, 0.05)
            plot(1:length(hotdryEra), fHotDryEra(1:length(hotdryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
        end
        p2 = plot(hotdryNcep, 'Color', colors(2,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryNcep, 0.05)
            plot(1:length(hotdryNcep), fHotDryNcep(1:length(hotdryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
        end
        p3 = plot(hotdryGldas, 'Color', colors(3,:), 'LineWidth', 2);
        if Mann_Kendall(hotdryGldas, 0.05)
            plot(1:length(hotdryGldas), fHotDryGldas(1:length(hotdryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
        end
        set(gca, 'FontSize', 40);
        set(gca, 'XTick', 6:10:length(hotdryEra), 'XTickLabels', [1985 1995 2005 2015]);
        ylim([0 1]);
        ylabel([seasonNames{s} ' hot & dry seasons']);
        set(gcf, 'Position', get(0,'Screensize'));
        legend([p1 p2 p3], {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'northwest');
        if north
            export_fig(['hotdry-season-' num2str(s) '-north.eps']);
        else
            export_fig(['hotdry-season-' num2str(s) '-south.eps']);
        end
        close all;
    end
end

dryTrends = dryTrends .* 10;
hotTrends = hotTrends .* 10;
hotDryTrends = hotDryTrends .* 10;

figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.25 -.1 .05 .2];
for d = 1:size(dryTrends, 2)
    for s = 1:size(dryTrends, 1)
        e = errorbar(s+displace(d), dryTrends(s, d), dryTrends(s,d)-dryCI(s,d,1), dryCI(s,d,2)-dryTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), dryTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if drySig(s, d)
            plot(s+displace(d), dryTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{wettestSeasonNorth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonNorth}];
else
    ax.XTickLabels{wettestSeasonSouth} = ['\color{blue} ' ax.XTickLabels{wettestSeasonSouth}];
end

ylabel('Dry season trend');
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS', 'GPCP'}, 'location', 'southeast');
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig dry-trends-north.eps;
else
    export_fig dry-trends-south.eps;
end
close all;





figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.1 0 .1];
for d = 1:size(hotTrends, 2)
    for s = 1:size(hotTrends, 1)
        e = errorbar(s+displace(d), hotTrends(s, d), hotTrends(s,d)-hotCI(s,d,1), hotCI(s,d,2)-hotTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), hotTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if hotSig(s, d)
            plot(s+displace(d), hotTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{hottestSeasonNorth} = ['\color{red} ' ax.XTickLabels{hottestSeasonNorth}];
else
    ax.XTickLabels{hottestSeasonSouth} = ['\color{red} ' ax.XTickLabels{hottestSeasonSouth}];
end

ylabel('Hot season trend');
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'southeast');
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig hot-trends-north.eps;
else
    export_fig hot-trends-south.eps;
end
close all;




figure('Color',[1,1,1]);
colors = get(gca, 'colororder');
legItems = [];
hold on;
box on;
axis square;
grid on;
displace = [-.1 0 .1];
for d = 1:size(hotDryTrends, 2)
    for s = 1:size(hotDryTrends, 1)
        e = errorbar(s+displace(d), hotDryTrends(s, d), hotDryTrends(s,d)-hotDryCI(s,d,1), hotDryCI(s,d,2)-hotDryTrends(s,d), 'Color', colors(d,:), 'LineWidth', 2);
        p = plot(s+displace(d), hotDryTrends(s, d), 'o', 'Color', colors(d, :), 'MarkerSize', 15, 'LineWidth', 2, 'MarkerFaceColor', [1,1,1]);
        if s == 1
            legItems(end+1) = p;
        end
        if hotDrySig(s, d)
            plot(s+displace(d), hotDryTrends(s, d), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(d, :), 'Color', colors(d, :));
        end
    end
end
plot([0 5], [0 0], 'k--');
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'}, 'YTick', -.25:.1:.25);
xlim([.5 4.5]);
ylim([-.25 .25]);

% set wettest season xtick label blue
ax = gca;
ax.TickLabelInterpreter = 'tex';
if north
    ax.XTickLabels{hottestSeasonNorth} = ['\color{red} ' ax.XTickLabels{hottestSeasonNorth}];
else
    ax.XTickLabels{hottestSeasonSouth} = ['\color{red} ' ax.XTickLabels{hottestSeasonSouth}];
end

ylabel('Hot & dry season trend');
legend(legItems, {'ERA-Interim', 'NCEP II', 'GLDAS'}, 'location', 'southeast');
set(gcf, 'Position', get(0,'Screensize'));
if north
    export_fig hot-dry-trends-north.eps;
else
    export_fig hot-dry-trends-south.eps;
end
close all;