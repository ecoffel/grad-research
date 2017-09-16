tempVar = 'tmax';
bowenVar = 'bowen';

timePeriod = 1981:2009;

ncepBaseDir = 'e:/data/ncep-reanalysis/output';
eraBaseDir = 'e:/data/era-interim/output';

regionInd = 1;

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
mmTempNcep = [];
mmTempEra = [];
% monthly mean daily mean bowen averaged over region
% dims: (month, year)
mmBowenNcep = [];
mmBowenEra = [];

for y = timePeriod(1):timePeriod(end)
    ['year ' num2str(y) '...']

    % load ncep and era bowen/temp data
    baseDailyTempNcep = loadDailyData([ncepBaseDir '/' tempVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
    baseDailyTempEra = loadDailyData([eraBaseDir '/mx2t/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
    baseDailyBowenNcep = loadDailyData([ncepBaseDir '/' bowenVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
    baseDailyBowenEra = loadDailyData([eraBaseDir '/bowen/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);

    % remove lat/lon data (we loaded this earlier)
    baseDailyTempNcep = baseDailyTempNcep{3};
    baseDailyBowenNcep = baseDailyBowenNcep{3};
    baseDailyTempEra = baseDailyTempEra{3};
    baseDailyBowenEra = baseDailyBowenEra{3};
    
    if baseDailyTempNcep(1,1,1,1,1) > 100
        baseDailyTempNcep = baseDailyTempNcep - 273.15;
    end
    
    if baseDailyTempEra(1,1,1,1,1) > 100
        baseDailyTempEra = baseDailyTempEra - 273.15;
    end
    
    % eliminate stray bowen values
    % global bowens can be much higher as considering desert regions
    baseDailyBowenNcep(baseDailyBowenNcep > 50) = NaN;
    baseDailyBowenNcep(baseDailyBowenNcep < 0) = NaN;
    baseDailyBowenEra(baseDailyBowenEra > 50) = NaN;
    baseDailyBowenEra(baseDailyBowenEra < 0) = NaN;
    
    % loop over months
    for month = 1:size(baseDailyTempNcep, 4)
        % take spatial average over daily data
        mmTempNcep(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyTempNcep(curLat, curLon, :, month, :), 5), 2), 1));
        mmBowenNcep(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyBowenNcep(curLat, curLon, :, month, :), 5), 2), 1));
    end
    
    for month = 1:size(baseDailyTempEra, 4)
        % take spatial average over daily data
        mmTempEra(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyTempEra(curLat, curLon, :, month, :), 5), 2), 1));
        mmBowenEra(month, y-timePeriod(1)+1) = squeeze(nanmean(nanmean(nanmean(baseDailyBowenEra(curLat, curLon, :, month, :), 5), 2), 1));
    end
end

% confidence 
ciThresh = 0.9;

slopeTmaxNcep = [];
slopeBowenNcep = [];
slopeTmaxEra = [];
slopeBowenEra = [];
CITmaxNcep = [];
CIBowenNcep = [];
CITmaxEra = [];
CIBowenEra = [];

for month = 1:12
    % linear fit for current month
    f = fit((1:size(mmTempNcep, 2))', mmTempNcep(month, :)', 'poly1');
    % get linear coefficient
    slopeTmaxNcep(month) = f.p1;
    
    % get and store confidence intervals for linear coefficient
    c = confint(f, ciThresh);
    CITmaxNcep(month, 1) = c(1,1);
    CITmaxNcep(month, 2) = c(2,1);
    
    % and same for era
    f = fit((1:size(mmTempEra, 2))', mmTempEra(month, :)', 'poly1');
    % get linear coefficient
    slopeTmaxEra(month) = f.p1;
    
    % get and store confidence intervals for linear coefficient for era
    c = confint(f, ciThresh);
    CITmaxEra(month, 1) = c(1,1);
    CITmaxEra(month, 2) = c(2,1);
    
    
    % and the same for bowen for ncep
    curBowen = mmBowenNcep(month, :)';
    % elimnate nans
    curBowen(isnan(curBowen)) = [];
    if length(curBowen) > 4
        f = fit((1:length(curBowen))',curBowen , 'poly1');
        % get linear coefficient
        slopeBowenNcep(month) = f.p1;

        % get and store confidence intervals for linear coefficient for ncep
        c = confint(f, ciThresh);
        CIBowenNcep(month, 1) = c(1,1);
        CIBowenNcep(month, 2) = c(2,1);
    else
        slopeBowenNcep(month) = NaN;
        CIBowenNcep(month, 1) = NaN;
        CIBowenNcep(month, 2) = NaN;
    end
    
    % and for era
    curBowen = mmBowenEra(month, :)';
    % elimnate nans
    curBowen(isnan(curBowen)) = [];
    if length(curBowen) > 4
        f = fit((1:length(curBowen))',curBowen , 'poly1');
        % get linear coefficient
        slopeBowenEra(month) = f.p1;

        % get and store confidence intervals for linear coefficient for era
        c = confint(f, ciThresh);
        CIBowenEra(month, 1) = c(1,1);
        CIBowenEra(month, 2) = c(2,1);
    else
        slopeBowenEra(month) = NaN;
        CIBowenEra(month, 1) = NaN;
        CIBowenEra(month, 2) = NaN;
    end
    
end

% convert from per year to per decade
slopeTmaxNcep = slopeTmaxNcep .* 10;
slopeBowenNcep = slopeBowenNcep .* 10;
slopeTmaxEra = slopeTmaxEra .* 10;
slopeBowenEra = slopeBowenEra .* 10;

figure('Color', [1,1,1]);
box on;

[ax,p1,p2] = plotyy(1:12, slopeTmaxNcep, 1:12, slopeBowenNcep);

hold(ax(1));
hold(ax(2));

p1Era = plot(ax(1), 1:12, slopeTmaxEra, 'LineStyle', '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
p2Era = plot(ax(2), 1:12, slopeBowenEra, 'LineStyle', '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

grid(ax(1));

axis(ax(1), 'square');
axis(ax(2), 'square');

set(p1, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 4);
set(p2, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

%plot(1:12, slopeTmax, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
%plot(1:12, slopeBowen, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);

for month = 1:12
    p3 = plot(ax(1), month, slopeTmaxNcep(month), 'o', 'MarkerSize', 15, 'Color', [239/255.0, 71/255.0, 85/255.0], 'MarkerEdgeColor', 'k');
    if (CITmaxNcep(month, 1) > 0 && CITmaxNcep(month, 2) > 0) || ...
       (CITmaxNcep(month, 1) < 0 && CITmaxNcep(month, 2) < 0)
        set(p3, 'LineWidth', 3, 'MarkerFaceColor', [239/255.0, 71/255.0, 85/255.0]);
    else
        set(p3, 'LineWidth', 3);
    end
    
    p3 = plot(ax(1), month, slopeTmaxEra(month), 'o', 'MarkerSize', 15, 'Color', [239/255.0, 71/255.0, 85/255.0], 'MarkerEdgeColor', 'k');
    if (CITmaxEra(month, 1) > 0 && CITmaxEra(month, 2) > 0) || ...
       (CITmaxEra(month, 1) < 0 && CITmaxEra(month, 2) < 0)
        set(p3, 'LineWidth', 3, 'MarkerFaceColor', [239/255.0, 71/255.0, 85/255.0]);
    else
        set(p3, 'LineWidth', 3);
    end
    
    p5 = plot(ax(2), month, slopeBowenNcep(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
    if (CIBowenNcep(month, 1) > 0 && CIBowenNcep(month, 2) > 0) || ...
       (CIBowenNcep(month, 1) < 0 && CIBowenNcep(month, 2) < 0)
        set(p5, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
    else
        set(p5, 'LineWidth', 3);
    end
    
    p6 = plot(ax(2), month, slopeBowenEra(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
    if (CIBowenEra(month, 1) > 0 && CIBowenEra(month, 2) > 0) || ...
       (CIBowenEra(month, 1) < 0 && CIBowenEra(month, 2) < 0)
        set(p6, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
    else
        set(p6, 'LineWidth', 3);
    end
end

plot(0:13, zeros(14,1), '--k', 'LineWidth', 2);

xlabel('Month', 'FontSize', 36);
ylabel(ax(1), ['Temperature slope (' char(176) '/decade)'], 'FontSize', 36);
ylabel(ax(2), ['Bowen ratio slope (per decade)'], 'FontSize', 36);
set(ax(1), 'FontSize', 36);
set(ax(2), 'FontSize', 36);

set(ax(1), 'XLim', [0.5 12.5], 'XTick', 1:12);
set(ax(2), 'XLim', [0.5 12.5], 'XTick', []);

set(ax(1), 'YLim', [-1 1], 'YTick', -1:.25:1);
set(ax(2), 'YLim', [-1 1], 'YTick', -1:.25:1);

set(ax(1), 'YColor', 'k');
set(ax(2), 'YColor', 'k');
title(regionNames{regionInd}, 'FontSize', 40);

l = legend([p1 p1Era p2 p2Era], 'Temperature (NCEP)', 'Temperature (Era)', 'Bowen (NCEP)', 'Bowen (Era)');
set(l, 'Location', 'northeastoutside');

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['reanalysisTrend-' regionAb{regionInd} '-.png'], '-m1');

