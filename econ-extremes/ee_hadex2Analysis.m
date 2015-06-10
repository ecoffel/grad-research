
baseDir = 'e:/data/hadex2/output';
timePeriod = 1901:2010;

lat = [];
lon = [];

txxMonthly = loadMonthlyData([baseDir '/txx'], 'txx');

minStationLength = 30;
selectedPeriod = 1981:2010;

region = 'world';
plotZone = 'north america';
fileformat = 'pdf';
baseDir = 'e:/';

% nyc: 40-42, 285-287
% il: 39-40, 269-271
% az: 33-35, 247-249
if strcmp(region, 'ne')
    tempLatRange = [40 42];
    tempLonRange = [285 287];
elseif strcmp(region, 'nc')
    tempLatRange = [39 41];
    tempLonRange = [269 271];
elseif strcmp(region, 'sw')
    tempLatRange = [33 35];
    tempLonRange = [247 249];
elseif strcmp(region, 'se')
    tempLatRange = [34 36];
    tempLonRange = [266 268];
elseif strcmp(region, 'usa')
    tempLatRange = [23 50];
    tempLonRange = [232 297];
elseif strcmp(region, 'world')
    tempLatRange = [-30 30];
    tempLonRange = [0 360];
end

[latIndexRange, lonIndexRange] = latLonIndexRange(txxMonthly{1}{1}, tempLatRange, tempLonRange);

txxData = [];
txxRegionData = [];

for m = 1:length(txxMonthly)
    for y = 1:size(txxMonthly{m}, 2)

        if length(lat) == 0
            lat = txxMonthly{m}{y}{1};
            lon = txxMonthly{m}{y}{2};
        end

        txxData(:,:,m,y) = txxMonthly{m}{y}{3};
    end
end

% filter out stations with less than 60 yrs of data
% invalidStations = 0;
% validStations = 0;
% for x = 1:size(txxData, 1)
%     for y = 1:size(txxData, 2)
%         for m = 1:size(txxData, 3)
%             ind = find(~isnan(squeeze(txxData(x,y,m,:))));
%             if length(ind) < minStationLength
%                 txxMonthly{1}{1}{3}(x,y,:,:) = NaN;
%                 invalidStations = invalidStations+1;
%                 break;
%             else
%                 validStations = validStations+1;
%             end
%         end
%     end
% end

globalTxxMean = squeeze(nanmean(nanmean(nanmean(txxData(:,:,:,:), 3), 2), 1));
regionTxxMean = squeeze(nanmean(nanmean(nanmean(txxData(latIndexRange,lonIndexRange,:,:), 3), 2), 1));
regionJJATxx = squeeze(max(txxData(:,:,6:8,:), [], 3));

regionTxxSlopes = [];
for x = 1:size(regionJJATxx, 1)
    for y = 1:size(regionJJATxx, 2)
        gridboxData = squeeze(regionJJATxx(x,y,end-30:end));
        nonNanInd = find(~isnan(gridboxData));
        if length(nonNanInd) == 0
           continue
        end
        
        rx = 1:length(gridboxData);
        mdl = fit(rx(nonNanInd)', gridboxData(nonNanInd), 'poly1');
        regionTxxSlopes(x,y) = mdl.p1;
    end
end

figure('Color', [1, 1, 1]);
plot(selectedPeriod, regionTxxMean(selectedPeriod-timePeriod(1)), 'k', 'LineWidth', 2);
xlabel('year', 'FontSize', 20);
ylabel('maximum annual temperature (degrees C)', 'FontSize', 20);














