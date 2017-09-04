
% load NCEP temp / soil moisture and bowen relationships
load C:\git-ecoffel\grad-research\2017-concurrent-heat\bowen\monthly-soilw-temp\monthlySoilwTemp-ncep-reanalysis-historical--1985-2004.mat
ncepSoilw = dailySoilwTemp;
clear dailySoilwTemp;

load C:\git-ecoffel\grad-research\2017-concurrent-heat\bowen\monthly-bowen-temp\monthlyBowenTemp-ncep-reanalysis-historical--1985-2004.mat
ncepBowen = monthlyBowenTemp;
clear monthlyBowenTemp;

% constrain to -60 - 60 lat
latRange = 15:75;

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

dispLatRange = 57:66;
dispLonRange = 1:20;
dispMonth = 6:9;

% select subset of data and reshape to 1D
soilDisp = reshape(soil(dispLatRange, dispLonRange, dispMonth, :), [numel(soil(dispLatRange, dispLonRange, dispMonth, :)), 1]);
bowenDisp = reshape(bowen(dispLatRange, dispLonRange, dispMonth, :), [numel(bowen(dispLatRange, dispLonRange, dispMonth, :)), 1]);

% remove zeros or nan
ind = find(~(soilDisp==0) & ~(bowenDisp==0) & ~isnan(soilDisp) & ~isnan(bowenDisp));
soilDisp = soilDisp(ind);
bowenDisp = bowenDisp(ind);

% normalize
soilDisp = soilDisp ./ norm(soilDisp);
bowenDisp = bowenDisp ./ norm(bowenDisp);

scatter(soilDisp,bowenDisp);