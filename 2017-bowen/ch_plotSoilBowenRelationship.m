
% load NCEP temp / soil moisture and bowen relationships
load C:\git-ecoffel\grad-research\2017-bowen\bowen\monthly-soilw-temp\monthlySoilwTemp-ncep-reanalysis-historical--1985-2004.mat
ncepSoilw = dailySoilwTemp;
clear dailySoilwTemp;

load C:\git-ecoffel\grad-research\2017-bowen\bowen\monthly-bowen-temp\monthlyBowenTemp-ncep-reanalysis-historical--1985-2004.mat
ncepBowen = monthlyBowenTemp;
clear monthlyBowenTemp;

% constrain to -60 - 60 lat
latRange = 15:75;

load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);

regionIds = [2,4,7];


regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa

           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end


% soil and bowen for each year for each month / gridcell
soil = zeros(size(lat, 1), size(lat, 2), 12, 20);
soil(soil == 0) = NaN;
bowen = zeros(size(lat, 1), size(lat, 2), 12, 20);
bowen(bowen == 0) = NaN;

for month = 1:12
    for xlat = latRange
        for ylon = 1:length(ncepSoilw{1}{month}{xlat})
            
            % water cells are empty
            if length(ncepSoilw{1}{month}{xlat}{ylon}) > 0
                soil(xlat, ylon, month, :) = ncepSoilw{2}{month}{xlat}{ylon};
                bowen(xlat, ylon, month, :) = ncepBowen{2}{month}{xlat}{ylon};
            end
        end
    end
end

% limit bad bowen values
bowen(bowen < 0) = 0;
bowen(bowen > 50) = 0;

dispLatRange = 15:75;
dispLonRange = 1:180;
dispMonths = 1:12;

% soilw / bowen slopes at different grid cells
slopes = zeros(size(lat, 1), size(lat, 2), length(dispMonths));
slopes(slopes == 0) = NaN';

for xlat = dispLatRange
    for ylon = dispLonRange
        
        if waterGrid(xlat, ylon)
            continue;
        end
        
        for month = dispMonths
            s = squeeze(soil(xlat, ylon, month, :));
            b = squeeze(bowen(xlat, ylon, month, :));

            nn = find(~isnan(s) & ~isnan(b) & b > 0 & s > 0);
            s = s(nn);
            b = b(nn);

            s = s ./ norm(s);
            b = b ./ norm(b);

            % if we have soil and bowen data
            if range(s) > 0
                f = fit(s, b, 'poly1');
                slopes(xlat, ylon, month) = f.p1;
            else
                slopes(xlat, ylon, month) = NaN;
            end
        end
    end
end

% kill off near-water tiles or bad results
slopes(slopes < -16) = NaN;
slopes(slopes > 16) = NaN;

figure('Color', [1,1,1]);
hold on;
box on;
%grid on;
axis square;

colors = distinguishable_colors(length(regionIds));

regionalSlopes = {};

legItems = [];

for r = 1:length(regionIds)
    regionId = regionIds(r);
    
    % select slopes for current region
    curLat = regionLatLonInd{regionId}{1};
    curLon = regionLatLonInd{regionId}{2};
    
    curSlopes = slopes(curLat, curLon, :);
    
    regionalSlopes{r} = curSlopes;
    
    ypos = [];
    for month = 1:12 
        ypos(month) = -nanmean(nanmean(squeeze(curSlopes(:, :, month))));
    end
    
    p = plot(dispMonths, ypos, 'LineWidth', 3, 'Color', colors(r, :));
    legItems(r) = p;
    
    for month = dispMonths
        % plot marker
        plot(month, ypos(month), 'o', 'LineWidth', 2, 'MarkerSize', 10, 'Color', colors(r, :));%[178/255.0, 113/255.0, 60/255.0]);
        
        % list of all months except current one
        otherMonths = 1:12;
        otherMonths(month) = [];
        
        % test significance between this month and all other months in the
        % year
        [h, p] = kstest2(reshape(curSlopes(:, :, month), [numel(curSlopes(:, :, month)), 1]), ...   
                         reshape(curSlopes(:, :, otherMonths), [numel(curSlopes(:, :, otherMonths)), 1]), 'alpha', 0.05);

        % fill marker if significant
        if h
            plot(month, ypos(month), 'o', 'LineWidth', 1, 'MarkerSize', 10, 'MarkerFaceColor', colors(r, :), 'MarkerEdgeColor', colors(r, :), 'Color', colors(r, :));
        end
    end
    
    % plot regional slope mean across year
    plot(1:12, ones(1,12) .* nanmean(ypos), '--', 'LineWidth', 2, 'Color', colors(r, :));
end

% plot zero line
plot(0:13, zeros(length(0:13),1), '--k', 'LineWidth', 2);

xlabel('Month', 'FontSize', 36);
set(gca, 'FontSize', 36);
title('Bowen ratio sensitivity to soil moisture', 'FontSize', 32);
xlim([0.5 12.5]);
ylim([-5 10]);
set(gca, 'XTick', 1:12);

legend(legItems, {'Eastern U.S.', 'Europe', 'Amazon'});



% result = {lat, lon, slopes};
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [-15 0], ...
%                   'cbXTicks', -15:5:0, ...
%                   'plotTitle', ['Soil moisture & Bowen ratio'], ...
%                   'fileTitle', ['slope-soilw-bowen.png'], ...
%                   'plotXUnits', ['Slope'], ...
%                   'blockWater', true, ...
%                   'colormap', cmocean('-turbid'), ...
%                   'magnify', '2');
% plotFromDataFile(saveData);

% plotModelData({lat,lon,slopes},'world','caxis',[-50,0]);

% select subset of data and reshape to 1D
% soilDisp = reshape(soil(dispLatRange, dispLonRange, dispMonth, :), [numel(soil(dispLatRange, dispLonRange, dispMonth, :)), 1]);
% bowenDisp = reshape(bowen(dispLatRange, dispLonRange, dispMonth, :), [numel(bowen(dispLatRange, dispLonRange, dispMonth, :)), 1]);
% 
% % remove zeros or nan
% ind = find(~(soilDisp==0) & ~(bowenDisp==0) & ~isnan(soilDisp) & ~isnan(bowenDisp));
% soilDisp = soilDisp(ind);
% bowenDisp = bowenDisp(ind);
% 
% % normalize
% soilDisp = soilDisp ./ norm(soilDisp);
% bowenDisp = bowenDisp ./ norm(bowenDisp);
% 
% scatter(soilDisp,bowenDisp);