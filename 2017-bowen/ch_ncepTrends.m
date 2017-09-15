tempVar = 'tmax';
bowenVar = 'bowen';

timePeriod = 1981:2012;

baseDir = 'e:/data/ncep-reanalysis/output';

regionInd = 4;

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

load lat;
load lon;

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};

% monthly mean daily max temps averaged over region
% dims: (month, year)
mmTemp = [];
% monthly mean daily mean bowen averaged over region
% dims: (month, year)
mmBowen = [];

for y = timePeriod(1):timePeriod(end)
    ['year ' num2str(y) '...']

    baseDailyTemp = loadDailyData([baseDir '/' tempVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
    baseDailyBowen = loadDailyData([baseDir '/' bowenVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);

    % remove lat/lon data (we loaded this earlier)
    baseDailyTemp = baseDailyTemp{3};
    baseDailyBowen = baseDailyBowen{3};
    
    if baseDailyTemp(1,1,1,1,1) > 100
        baseDailyTemp = baseDailyTemp - 273.15;
    end
    
    % loop over months
    for month = 1:size(baseDailyTemp, 4)
        % take spatial average over daily data
        mmTemp(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyTemp(curLat, curLon, :, month, :), 5), 2), 1));
        mmBowen(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyBowen(curLat, curLon, :, month, :), 5), 2), 1));
    end
end

% confidence 
ciThresh = 0.9;

slopeTmax = [];
slopeBowen = [];
CITmax = [];
CIBowen = [];

for month = 1:12
    % linear fit for current month
    f = fit((1:size(mmTemp, 2))', mmTemp(month, :)', 'poly1');
    
    % get linear coefficient
    slopeTmax(month) = f.p1;
    
    % get and store confidence intervals for linear coefficient
    c = confint(f, ciThresh);
    CITmax(month, 1) = c(1,1);
    CITmax(month, 2) = c(2,1);
    
    % and the same for bowen
    f = fit((1:size(mmBowen, 2))', mmBowen(month, :)', 'poly1');
    
    % get linear coefficient
    slopeBowen(month) = f.p1;
    
    % get and store confidence intervals for linear coefficient
    c = confint(f, ciThresh);
    CIBowen(month, 1) = c(1,1);
    CIBowen(month, 2) = c(2,1);
end

figure('Color', [1,1,1]);
box on;

[ax,p1,p2] = plotyy(1:12, slopeTmax, 1:12, slopeBowen);
        
hold(ax(1));
hold(ax(2));

grid(ax(1));

axis(ax(1), 'square');
axis(ax(2), 'square');

set(p1, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 4);

%plot(1:12, slopeTmax, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
%plot(1:12, slopeBowen, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);

for month = 1:12
    p3 = plot(ax(1), month, slopeTmax(month), 'o', 'MarkerSize', 15, 'Color', [239/255.0, 71/255.0, 85/255.0], 'MarkerEdgeColor', 'k');
    if (CITmax(month, 1) > 0 && CITmax(month, 2) > 0) || ...
       (CITmax(month, 1) < 0 && CITmax(month, 2) < 0)
        set(p3, 'LineWidth', 3, 'MarkerFaceColor', [239/255.0, 71/255.0, 85/255.0]);
    else
        set(p3, 'LineWidth', 3);
    end
    
    p4 = plot(ax(2), month, slopeBowen(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
    if (CIBowen(month, 1) > 0 && CIBowen(month, 2) > 0) || ...
       (CIBowen(month, 1) < 0 && CIBowen(month, 2) < 0)
        set(p4, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
    else
        set(p4, 'LineWidth', 3);
    end
end

xlabel('Month', 'FontSize', 24);
ylabel(ax(1), ['Temperature slope (' char(176) '/yr)'], 'FontSize', 24);
ylabel(ax(2), ['Bowen ratio slope /yr)'], 'FontSize', 24);
set(ax(1), 'FontSize', 24);
set(ax(2), 'FontSize', 24);

set(ax(1), 'XLim', [0.5 12.5], 'XTick', 1:12);
set(ax(2), 'XLim', [0.5 12.5], 'XTick', []);

set(ax(1), 'YLim', [-0.5 0.5], 'YTick', -0.5:0.25:0.5);
set(ax(2), 'YLim', [-0.2 0.2], 'YTick', -0.2:0.1:0.2);

set(ax(1), 'YColor', 'k');
set(ax(2), 'YColor', 'k');
title(regionNames{regionInd}, 'FontSize', 24);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['ncepTrend-' regionAb{regionInd} '-.png']);

