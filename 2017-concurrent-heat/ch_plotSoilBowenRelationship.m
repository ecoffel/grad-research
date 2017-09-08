
% load NCEP temp / soil moisture and bowen relationships
load C:\git-ecoffel\grad-research\2017-concurrent-heat\bowen\monthly-soilw-temp\monthlySoilwTemp-ncep-reanalysis-historical--1985-2004.mat
ncepSoilw = dailySoilwTemp;
clear dailySoilwTemp;

load C:\git-ecoffel\grad-research\2017-concurrent-heat\bowen\monthly-bowen-temp\monthlyBowenTemp-ncep-reanalysis-historical--1985-2004.mat
ncepBowen = monthlyBowenTemp;
clear monthlyBowenTemp;

% constrain to -60 - 60 lat
latRange = 15:75;

load lat;
load lon;
load waterGrid;
waterGrid = logical(waterGrid);


regionIds = [1, 2, 4, 7];

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
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

dispLatRange = 45:75;
dispLonRange = 1:180;
dispMonth = 6:9;

% soilw / bowen slopes at different grid cells
slopes = zeros(size(lat));
slopes(slopes == 0) = NaN';

for xlat = dispLatRange
    for ylon = dispLonRange
        s = soil(xlat, ylon, dispMonth, :);
        s = reshape(s, [numel(s), 1]);
        
        b = bowen(xlat, ylon, dispMonth, :);
        b = reshape(b, [numel(s), 1]);
        
        nn = find(~isnan(s) & ~isnan(b) & b > 0 & s > 0);
        s = s(nn);
        b = b(nn);
        
        s = s ./ norm(s);
        b = b ./ norm(b);
        
        if length(s) > 10*length(dispMonth) && length(b) > 10*length(dispMonth) && range(s) > 0
            f = fit(s, b, 'poly1');
            slopes(xlat, ylon) = f.p1;
        else
            slopes(xlat, ylon) = NaN;
        end
    end
end

% kill off near-water tiles or bad results
slopes(slopes < -16) = NaN;
slopes(slopes > 16) = NaN;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

regionalSlopes = {};

for r = 1:length(regionIds)
    regionId = regionIds(r);
    
    % select slopes for current region
    curLat = regionLatLonInd{regionId}{1};
    curLon = regionLatLonInd{regionId}{2};
    
    curSlopes = slopes(curLat, curLon);
    curSlopes = reshape(curSlopes, [numel(curSlopes), 1]);
    
    regionalSlopes{r} = curSlopes;
    
    errorbar(r, nanmean(curSlopes), nanstd(curSlopes), 'o', 'LineWidth', 2, 'MarkerSize', 15, 'Color', [178/255.0, 113/255.0, 60/255.0]);
    
    % if significantly different
    if kstest2(curSlopes, regionalSlopes{1}, 'alpha', 0.05)
        plot(r, nanmean(curSlopes), 'o', 'LineWidth', 1, 'MarkerSize', 15, 'MarkerFaceColor', [178/255.0, 113/255.0, 60/255.0], 'MarkerEdgeColor', [178/255.0, 113/255.0, 60/255.0], 'Color', [178/255.0, 113/255.0, 60/255.0]);
    end
end

ylabel('Slope: Bowen ratio to soil moisture', 'FontSize', 36);
xlim([0.5 4.5]);
set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'NH', 'US', 'Europe', 'Amazon'});
set(gca, 'FontSize', 36);


result = {lat, lon, slopes};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-15 0], ...
                  'cbXTicks', -15:5:0, ...
                  'plotTitle', ['Soil moisture & Bowen ratio'], ...
                  'fileTitle', ['slope-soilw-bowen.png'], ...
                  'plotXUnits', ['Slope'], ...
                  'blockWater', true, ...
                  'colormap', cmocean('-turbid'), ...
                  'magnify', '2');
plotFromDataFile(saveData);

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