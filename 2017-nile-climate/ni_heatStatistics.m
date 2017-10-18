%tmaxBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1980, 'yearEnd', 2010);

load lat;
load lon;

regionBounds = [[2 35]; [25, 45]];
[latInds, lonInds] = latLonIndexRange(tmaxBase, regionBounds(1,:), regionBounds(2,:));

tmax = tmaxBase{3}(latInds, lonInds, :, :, :);
tmax = tmax-273.15;

% temperature: 
threshTemp = 37;
% duration (days)
threshDur = 3;

heatProb = [];

% for all months, calculate the chance of there being a heatwave matching
% defined characteristics...
for month = 1:12
    % loop over all gridcells
    for xlat = 1:size(tmax, 1)
        for ylon = 1:size(tmax, 2)
            % convert to 1D for current gridcell
            d = reshape(tmax(xlat, ylon, :, month, :), [numel(tmax(xlat, ylon, :, month, :)), 1]);
            
            % find all days above threshold temperature
            indTemp = find(d > threshTemp);
            
            % for how ever many days long wave we're looking for, take
            % difference of temp threshold indices - so if 1, that means
            % consequitive hot days
            % look for sub-arrays that contain X number of sequential ones
            indDur = length(findstr(diff(indTemp)', ones(1,threshDur)));
            
            
            % average number of events per year
            heatProb(xlat, ylon, month) = indDur / size(tmax, 3);
        end
    end
end

plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),heatProb(:,:,5)},'nile','countries',true,'caxis',[0 10]);