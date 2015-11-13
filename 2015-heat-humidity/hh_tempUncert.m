% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
dataset = 'cmip5';

% models = {'bnu-esm', 'canesm2'};
models = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
var = 'wb';
rcp = 'rcp85';
ensemble = 'r1i1p1';

years = 2020:2069;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'pdf';

biasCorrect = true;

baseDir = 'e:/data/';
dataDir = 'cmip5/output';
yearStep = 1;

findMax = true;
months = 1:12;
maxMinStr = 'maximum';

lat = [];
lon = [];

ext = [];
globalWb = {};

for m = 1:length(models)
    if strcmp(models{m}, '')
        curModel = models{m};
    else
        curModel = [models{m} '/'];
    end

    globalWb{m} = [];
    
    decInd = 0;
    
    ['loading ' curModel ' base']
    for y = years(1):yearStep:years(end)
        ['year ' num2str(y) '...']
        
        if mod(y, 10) == 0
            decInd = decInd+1;
        end
        
        daily = loadDailyData([baseDir dataDir '/' curModel ensemble '/' rcp '/' var '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if length(lat) == 0
            lat = daily{1};
            lon = daily{2};
        end
        
        % select wb temps about 28
        %dailyLinear = reshape(daily{3}, [size(daily{3},1)*size(daily{3},2)*size(daily{3},3)*size(daily{3},4)*size(daily{3},5), 1]);
        %dailyLinear = dailyLinear(dailyLinear >= 28);
        %globalWb{m}(:, decInd) = cat(1, globalWb{m}(:, decInd), dailyLinear);
        
        ext(:, :, m, y-years(1)+1) = squeeze(nanmax(nanmax(daily{3}, [], 5), [], 4));
            
        clear daily dailyLinear extTmp;
    end
end

extStd30 = nanstd(nanmean(ext(:, :, :, 10:20), 4), [], 3);
extStd40 = nanstd(nanmean(ext(:, :, :, 20:30), 4), [], 3);
extStd50 = nanstd(nanmean(ext(:, :, :, 30:40), 4), [], 3);
extStd60 = nanstd(nanmean(ext(:, :, :, 40:50), 4), [], 3);


plotRange = [-5 5];
plotRegion = 'world';
plotXUnits = 'degrees C';
blockWater = true;

plotTitle = ['Mean annual maximum wet-bulb, 2030-2040'];
fileTitle = 'tempUncert-std-2030.pdf';
result = {lat, lon, extStd30};
saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater, ...
                  'plotCountries', true);

plotFromDataFile(saveData);



plotTitle = ['Mean annual maximum wet-bulb, 2040-2050'];
fileTitle = 'tempUncert-std-2040.pdf';
result = {lat, lon, extStd40};
saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater, ...
                  'plotCountries', true);

plotFromDataFile(saveData);



plotTitle = ['Mean annual maximum wet-bulb, 2050-2060'];
fileTitle = 'tempUncert-std-2050.pdf';
result = {lat, lon, extStd50};
saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater, ...
                  'plotCountries', true);

plotFromDataFile(saveData);



plotTitle = ['Mean annual maximum wet-bulb, 2060-2070'];
fileTitle = 'tempUncert-std-2060.pdf';
result = {lat, lon, extStd60};
saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater, ...
                  'plotCountries', true);

plotFromDataFile(saveData);
