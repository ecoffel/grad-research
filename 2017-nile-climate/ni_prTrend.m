fprintf('loading data...\n');
gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1980, 'endYear', 2016);

lat = gpcp{1};
lon = gpcp{2};
data = gpcp{3};

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

trend = [];
sig = [];

fprintf('processing trends...\n');
for xlat = 1:size(lat,1)
    for ylon = 1:size(lat, 2)
        for month = 1:12
            d = squeeze(data(xlat, ylon, :, month));
            nn = find(~isnan(d));
            d = d(nn);
            if length(d) < 30
                continue; 
            end
            
            f = fit((1:length(d))', d, 'poly1');
            trend(xlat, ylon, month) = f.p1;
            sig(xlat, ylon, month) = Mann_Kendall(d, 0.05);
        end
    end
end

for month = 1:12
    result = {lat(latInds,lonInds), lon(latInds,lonInds), trend(latInds,lonInds,month)};
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-.1 .1], ...
                      'cbXTicks', [-.1 -.05 0 0.05 .1], ...
                      'plotTitle', ['Pr trend'], ...
                      'fileTitle', ['gpcp-pr-trend-' num2str(month) '.png'], ...
                      'plotXUnits', ['mm/day'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'RdBu'), ...
                      'statData', sig(latInds,lonInds,month),...
                      'plotCountries', true);
    plotFromDataFile(saveData);
end