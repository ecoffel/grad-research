tempVar = 'tmax';
bowenVar = 'bowen';

timePeriod = 1981:2009;

ncepBaseDir = 'e:/data/ncep-reanalysis/output';
eraBaseDir = 'e:/data/era-interim/output';

regionInds = [2 4 7];

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

% the range of temperature increase to calculate recurrence for
warmingRange = 0:0.25:8;

% monthly mean daily max temps averaged over region
% dims: (month, year)
mmTempNcep = [];
mmTempEra = [];

% the base period per-gridcell temps
if ~exist('baseTempDataNcep')
    baseTempDataNcep = {};
end

if length(baseTempDataNcep) == 0
    for y = timePeriod(1):timePeriod(end)
        ['year ' num2str(y) '...']

        % load ncep and era bowen/temp data
        baseDailyTempNcep = loadDailyData([ncepBaseDir '/' tempVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);
        baseDailyTempEra = loadDailyData([eraBaseDir '/mx2t/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);

        % remove lat/lon data (we loaded this earlier)
        baseDailyTempNcep = baseDailyTempNcep{3};
        baseDailyTempEra = baseDailyTempEra{3};

        % convert K->C if needed
        if baseDailyTempNcep(1,1,1,1,1) > 100
            baseDailyTempNcep = baseDailyTempNcep - 273.15;
        end

        if baseDailyTempEra(1,1,1,1,1) > 100
            baseDailyTempEra = baseDailyTempEra - 273.15;
        end

        % loop over regions to extract temps
        for regionId = regionInds

            % create matrix for this region if doesn't exist yet
            if length(baseTempDataNcep) < regionId
                baseTempDataNcep{regionId} = [];
            end

            curLat = regionLatLonInd{regionId}{1};
            curLon = regionLatLonInd{regionId}{2};

            % add current year data
            baseTempDataNcep{regionId}(:, :, y-timePeriod(1)+1, :, :) = baseDailyTempNcep(curLat, curLon, :, :, :);

        end

    end
end

% look for days above 95th percentile
thresh = 95;

for regionId = regionInds
    futureCnt = [];
    for xlat = 1:size(baseTempDataNcep{regionId}, 1)
        for ylon = 1:size(baseTempDataNcep{regionId}, 2)
            % turn cur gridcell into 1D for each month
            for month = 1:12
                baseTemps = reshape(baseTempDataNcep{regionId}(xlat, ylon, :, month, :), [numel(baseTempDataNcep{regionId}(xlat, ylon, :, month, :)), 1]);
                
                % calculate temperature for selected threshold
                threshTemp = prctile(baseTemps, thresh);
                
                
                % loop over all warming ranges
                for w = 1:length(warmingRange)
                    % add warming offset to base
                    warmTemps = baseTemps + warmingRange(w);
                    
                    % count how many times new temps exceed threshold
                    threshExceedCnt = length(find(warmTemps > threshTemp));
                    
                    % record additional exceedances per month (future minus
                    % historical exceedences)
                    futureCnt(xlat, ylon, month, w) = threshExceedCnt / length(timePeriod);
                end
            end
        end
    end
    
    % load warming files from seasonal analysis
    load(['2017-bowen/warming/warming-' regionAb{regionId}]);
    
    monthGroups = [[12 1 2];
                   [3 4 5];
                   [6 7 8];
                   [9 10 11]];
    
    seasonalWarming = [];
               
    monthGroupNames = {'DJF', 'MAM', 'JJA', 'SON'};
               
    colors = distinguishable_colors(size(monthGroups, 1));
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    box on;
    
    legItems = [];
    
    for mg = 1:size(monthGroups, 1)
        % compute mean warming for this season
        seasonalWarming(mg) = nanmean(data{1}(monthGroups(mg, :))) + data{2};
        
        cury = squeeze(nanmean(nanmean(nanmean(futureCnt(:,:,monthGroups(mg, :),:), 3), 2), 1));
        p = plot(warmingRange, cury, 'Color', colors(mg, :), 'LineWidth', 3);
        legItems(mg) = p;
        
        % find the index of the y coordinate closest to the x value for
        % seasonal warming
        ind = find(abs(seasonalWarming(mg)-warmingRange)==min(abs(seasonalWarming(mg)-warmingRange)));
        
        % plot dashed line indicating seasonal warming level
        plot([seasonalWarming(mg) seasonalWarming(mg)], [0 cury(ind)], '--', 'LineWidth', 2, 'Color', colors(mg, :));
        plot([0 seasonalWarming(mg)], [cury(ind) cury(ind)], '--', 'LineWidth', 2, 'Color', colors(mg, :));
    end
    
    % find the index of the y coordinate closest to the x value for
    % seasonal warming
    ind = find(abs(data{2}-warmingRange)==min(abs(data{2}-warmingRange)));

    % plot dashed line indicating seasonal warming level
    plot(repmat(data{2}, [2, 1]), [-1 36], '--', 'LineWidth', 2, 'Color', [.5 .5 .5]);
    
    title(regionNames{regionId}, 'FontSize', 40);
    xlabel(['Warming (' char(176) 'C)'], 'FontSize', 36);
    ylabel('Days per month', 'FontSize', 36);
    set(gca, 'FontSize', 36);
    set(gca, 'XTick', 0:8);
    legend(legItems, monthGroupNames);
    ylim([0 35]);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['recurrence-diff-' regionAb{regionId} '.png'], '-m1');
    close all;
end