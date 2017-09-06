
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

% soil and bowen for each year for each month / gridcell
soil = [];
bowen = [];

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
slopes(slopes == 0) = NaN'

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

result = {lat, lon, slopes};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-50 0], ...
                  'cbXTicks', -50:10:0, ...
                  'plotTitle', ['Soil moisture & Bowen ratio'], ...
                  'fileTitle', ['slope-soilw-bowen.png'], ...
                  'plotXUnits', ['Slope'], ...
                  'blockWater', true, ...
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