asosDir = 'e:/data/projects/heat/asos/wx-data/';
ncepDir = 'e:/data/ncep-reanalysis/output';

asosFiles = {'in', 'india', 'brazil', 'china', 'germany', 'nigeria', 'spain', 'saudi'};

% the asos data from each available file
asosFileData = {};

load lat;
load lon;

% the ncep grid cells to extract for comparison
ncepXlat = [];
ncepYlon = [];

for a = 1:length(asosFiles);
    load([asosDir 'asos-' asosFiles{a} '.mat']);
    
    % loop through all stations in this file
    for i = 1:length(asosData)
        curLat = asosData{i}{3};
        curLon = asosData{i}{2};
        
        % fix negative lons
        if curLon < 0
            curLon = curLon + 360;
        end
        
        % find the ncep lat/lon index associated with current station
        [latInd, lonInd] = latLonIndex({lat, lon, []}, [curLat curLon]);
        
        % if we don't already have this one, add it
        if ~(ismember(latInd, ncepXlat) && ismember(lonInd, ncepYlon))
            ncepXlat(end+1) = latInd;
            ncepYlon(end+1) = lonInd;
        end
        
        % replace lat in asos struct with [lat, latInd]
        asosData{i}{2} = [asosData{i}{2} latInd];
        asosData{i}{3} = [asosData{i}{3} lonInd];
    end
    
    % save modified asos data
    asosFileData{a} = asosData;
end

basePeriodYears = 2010:2016;

% ncep wb data for the required grid cells:
% (xlat, ylon, wb)
ncepData = {};

for y = basePeriodYears(1):1:basePeriodYears(end)
    ['year ' num2str(y) '...']

    % load current year of ncep
    baseDaily = loadDailyData([ncepDir '/wb-davies-jones-full/regrid/world'], 'yearStart', y, 'yearEnd', (y+1)-1);

    % reshape so it is linear for each gridcell
    baseDaily{3} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                          size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
    
    % loop through all asos data to select ncep grid cells
    for i = 1:length(ncepXlat)
        % new grid cell
        if length(ncepData) < i
            ncepData{i} = {ncepXlat(i), ncepYlon(i), squeeze(baseDaily{3}(ncepXlat(i), ncepYlon(i), :))};
        % adding a new year
        else
            ncepData{i} = {ncepXlat(i), ncepYlon(i), [ncepData{i}{3}; squeeze(baseDaily{3}(ncepXlat(i), ncepYlon(i), :))]};
        end
    end
    
    clear baseDaily baseExtTmp;
end

ncepBias = {};

% find ncep bias at each grid cell
% loop over all asos files
for af = 1:length(asosFileData)
    
    ncepBias{af} = {[], []};
    
    % loop over all grid cells
    for i = 1:length(ncepData)
        
        % and over each asos station
        for a = 1:length(asosFileData{af})
            
            % lat/lon indices match - station is in current ncep grid cell
            if asosFileData{af}{a}{2}(2) == ncepData{i}{1} && ...
               asosFileData{af}{a}{3}(2) == ncepData{i}{2}
                
                % mean difference between ncep and current station
                meanBias = nanmean(ncepData{i}{3}) - nanmean(asosFileData{af}{a}{end});
                % and std
                stdBias = nanstd(ncepData{i}{3}) - nanstd(asosFileData{af}{a}{end});
                
                % add to the bias lists
                ncepBias{af}{1} = [ncepBias{af}{1}, meanBias];
                ncepBias{af}{2} = [ncepBias{af}{2}, stdBias];
            end
            
        end
    end
end

figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;

colors = distinguishable_colors(length(asosFiles));
regions = {'US-Indiana', 'India', 'Brazil', 'China', 'Germany', ...
           'Nigeria', 'Spain', 'Saudi Arabia'};

legItems = [];
       
for n = 1:length(ncepBias)
    e = errorbar(n, nanmean(ncepBias{n}{1}), nanmean(ncepBias{n}{2}), 'o', 'Color', colors(n, :), 'MarkerSize', 15, 'LineWidth', 2);
    
    text(n, nanmean(ncepBias{n}{1}), regions{n}, 'Color', colors(n, :), 'FontSize', 32);
    
    if ttest(ncepBias{n}{1})
        p = plot(n, nanmean(ncepBias{n}{1}), 'o', 'MarkerSize', 15, 'MarkerFaceColor', colors(n, :), 'MarkerEdgeColor', colors(n, :));
        legItems(end+1) = p;
    else
        legItems(end+1) = e;
    end
    
end

%legend(legItems, regions);

set(gca, 'XTick', []);
set(gca, 'FontSize', 32);
ylabel(['NCEP wet bulb bias (' char(176) 'C)'], 'FontSize', 36');
ylim([-3 1]);
plotedit('on');