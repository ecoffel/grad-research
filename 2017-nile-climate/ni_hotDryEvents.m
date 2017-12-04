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

north = true;

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

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

prcTmax = 75;
prcPr = 25;
       
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
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    box on;
    grid on;
    ylim([0 125]);
    p1 = plot(hotEra, 'Color', colors(1,:), 'LineWidth', 2);
    if Mann_Kendall(hotEra, 0.05)
        f = fit((1:length(hotEra))', hotEra', 'poly1');
        plot(1:length(hotEra), f(1:length(hotEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
    end
    p2 = plot(hotNcep, 'Color', colors(2,:), 'LineWidth', 2);
    if Mann_Kendall(hotNcep, 0.05)
        f = fit((1:length(hotNcep))', hotNcep', 'poly1');
        plot(1:length(hotNcep), f(1:length(hotNcep)), '--', 'Color', colors(3,:), 'LineWidth', 2);
    end
    p3 = plot(hotGldas, 'Color', colors(3,:), 'LineWidth', 2);
    if Mann_Kendall(hotGldas, 0.05)
        f = fit((1:length(hotGldas))', hotGldas', 'poly1');
        plot(1:length(hotGldas), f(1:length(hotGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
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
    i = i+1;
    close all;
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    box on;
    grid on;
    p1 = plot(dryEra, 'Color', colors(1,:), 'LineWidth', 2);
    if Mann_Kendall(dryEra, 0.05)
        f = fit((1:length(dryEra))', dryEra', 'poly1');
        plot(1:length(dryEra), f(1:length(dryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
    end
    p2 = plot(dryNcep, 'Color', colors(2,:), 'LineWidth', 2);
    if Mann_Kendall(dryNcep, 0.05)
        f = fit((1:length(dryNcep))', dryNcep', 'poly1');
        plot(1:length(dryNcep), f(1:length(dryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
    end
    p3 = plot(dryGpcp, 'Color', colors(4,:), 'LineWidth', 2);
    if Mann_Kendall(dryGpcp, 0.05)
        f = fit((1:length(dryGpcp))', dryGpcp', 'poly1');
        plot(1:length(dryGpcp), f(1:length(dryGpcp)), '--', 'Color', colors(4,:), 'LineWidth', 2);
    end
    p4 = plot(dryGldas, 'Color', colors(3,:), 'LineWidth', 2);
    if Mann_Kendall(dryGldas, 0.05)
        f = fit((1:length(dryGldas))', dryGldas', 'poly1');
        plot(1:length(dryGldas), f(1:length(dryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
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
        f = fit((1:length(hotdryEra))', hotdryEra', 'poly1');
        plot(1:length(hotdryEra), f(1:length(hotdryEra)), '--', 'Color', colors(1,:), 'LineWidth', 2);
    end
    p2 = plot(hotdryNcep, 'Color', colors(2,:), 'LineWidth', 2);
    if Mann_Kendall(hotdryNcep, 0.05)
        f = fit((1:length(hotdryNcep))', hotdryNcep', 'poly1');
        plot(1:length(hotdryNcep), f(1:length(hotdryNcep)), '--', 'Color', colors(2,:), 'LineWidth', 2);
    end
    p3 = plot(hotdryGldas, 'Color', colors(3,:), 'LineWidth', 2);
    if Mann_Kendall(hotdryGldas, 0.05)
        f = fit((1:length(hotdryGldas))', hotdryGldas', 'poly1');
        plot(1:length(hotdryGldas), f(1:length(hotdryGldas)), '--', 'Color', colors(3,:), 'LineWidth', 2);
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
    i = i+1;
    close all;
    
%     subplot(4,3,i);
%     hold on;
%     axis square;
%     box on;
%     grid on;
%     plot(hotdryEra, 'Color', colors(2,:));
%     if Mann_Kendall(hotdryEra, 0.05)
%         f = fit((1:length(hotdryEra))', hotdryEra', 'poly1');
%         plot(1:length(hotdryEra), f(1:length(hotdryEra)), '--', 'Color', colors(2,:));
%     end
%     plot(hotdryNcep, 'Color', colors(1,:));
%     if Mann_Kendall(hotdryNcep, 0.05)
%         f = fit((1:length(hotdryNcep))', hotdryNcep', 'poly1');
%         plot(1:length(hotdryNcep), f(1:length(hotdryNcep)), '--', 'Color', colors(1,:));
%     end
%     ylim([0 125]);
%     i = i+1;
end