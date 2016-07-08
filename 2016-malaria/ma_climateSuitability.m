% find climatic suitability for malaria transmission according to IRI
% formula: http://iridl.ldeo.columbia.edu/maproom/Health/Regional/Africa/Malaria/CSMT/

% load monthly mean temperature, relative humidity, and precipitation rate

% temp
load('E:\data\ncep-reanalysis\output\air\mean\air_mon_1979_01_01.mat');

air_mon_1979_01_01{3} = air_mon_1979_01_01{3} - 273.15;

% precip
load('E:\data\ncep-reanalysis\output\prate\mean\prate_mon_1979_01_01.mat');

% convert rate into monthly total precip
prate_mon_1979_01_01{3} = prate_mon_1979_01_01{3} * 24 * 60 * 60 * 30;

% rel humidity
load('E:\data\ncep-reanalysis\output\rhum\mean\rhum_mon_1979_01_01.mat');

% select the surface level
rhum_mon_1979_01_01{3} = squeeze(rhum_mon_1979_01_01{3}(:, :, 1, :));

lat = air_mon_1979_01_01{1};
lon = air_mon_1979_01_01{2};
suitable = [];

rhumRegrid = [];
% regrid rhum onto the gaussian grid
for m = 1:size(rhum_mon_1979_01_01{3}, 3)
    tmp = regridGriddata({rhum_mon_1979_01_01{1}, rhum_mon_1979_01_01{2}, squeeze(rhum_mon_1979_01_01{3}(:, :, m))}, ...
                                                     {lat, lon, []});
    rhumRegrid(:, :, m) = tmp{3};
end

rhum_mon_1979_01_01 = {lat, lon, rhumRegrid};

% loop over each month
for m = 1:size(air_mon_1979_01_01{3}, 3)
    temp = air_mon_1979_01_01{3}(:, :, m);
    precip = prate_mon_1979_01_01{3}(:, :, m);
    rhum = rhum_mon_1979_01_01{3}(:, :, m);
    
    suitable(:, :, m) = (temp > 18 & temp < 32) & precip > 80 & rhum > 60;
end

suitable = {lat, lon, suitable};

meanSuitable = round(nanmean(suitable{3}, 3));

saveData = struct('data', {{lat, lon, meanSuitable}}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [0 1], ...
                      'plotTitle', 'NCEP Mean transmission suitablility, 1979-2014', ...
                      'fileTitle', 'suitability.png', ...
                      'plotXUnits', 'Yes/No', ...
                      'plotCountries', true, ...
                      'plotStates', false, ...
                      'blockWater', true);
plotFromDataFile(saveData);

