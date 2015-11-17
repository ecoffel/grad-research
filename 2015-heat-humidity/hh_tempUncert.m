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

wbThresh = 27;

years = 2021:2070;

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

    globalWb{m} = {};
    
    decInd = 0;
    
    ['loading ' curModel ' base']
    for y = years(1):yearStep:years(end)
        ['year ' num2str(y) '...']
        
        if mod(y, 10) == 0
            decInd = decInd+1;
            globalWb{m}{decInd} = [];
        end
        
        daily = loadDailyData([baseDir dataDir '/' curModel ensemble '/' rcp '/' var '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if length(lat) == 0
            lat = daily{1};
            lon = daily{2};
        end
        
        % select wb temps about 26
        %dailyLinear = reshape(daily{3}, [size(daily{3}, 1)*size(daily{3}, 2)*size(daily{3}, 3)*size(daily{3}, 4)*size(daily{3}, 5), 1]);
        %dailyLinear = dailyLinear(dailyLinear >= wbThresh);
        %globalWb{m}{decInd} = cat(1, globalWb{m}{decInd}, dailyLinear);
        
        % save annual maximum wet-bulb temperature for each gridbox
        ext(:, :, m, y-years(1)+1) = squeeze(nanmax(nanmax(daily{3}, [], 5), [], 4));
            
        clear daily dailyLinear extTmp;
    end
end

latbounds = [-40 40];
lonbounds = [0 359];
[latindex, lonindex] = latLonIndexRange({lat, lon, []}, latbounds, lonbounds);
ext = ext(latindex, lonindex, :, :);
ext = squeeze(nanmax(nanmax(ext, [], 2), [], 1));

figure('Color', [1, 1, 1]);
hold on;
colors = distinguishable_colors(size(ext, 1));
legStr = '';
for m = 1:size(ext, 1)
    plot(years, ext(m, :), 'LineWidth', 2, 'Color', colors(m, :));
    legStr = [legStr '''' models{m} '''' ','];
end

% remove trailing comma
legStr = legStr(1:end-1);
eval(['legend(' legStr ');']);





gevAnalysis = true;
stdPlots = false;


if gevAnalysis
    
    gpdfs = [];
    
    x = linspace(wbThresh, 35, 200);
    
    for m = 1:length(models)
        ['fitting ' models{m}]
        % generate GEV fit for current model in 2060s
        [parmhat,parmci] = gevfit(globalWb{m}{5}(globalWb{m}{5} >= 30));
        
        kCI = parmci(:,1)
        sigmaCI = parmci(:,2)
        muCI = parmci(:,3)
        
        kMLE = parmhat(1)        % Shape parameter
        sigmaMLE = parmhat(2)    % Scale parameter
        muMLE = parmhat(3)       % Location parameter
        
        if ~isnan(kCI(1))
            gpdf = gevpdf(x, kMLE,sigmaMLE, muMLE);
            gpdfs(m, :) = gpdf;
        else
            gpdfs(m, :) = zeros(200);
        end
    end
    
    colors = distinguishable_colors(length(models));
    
    figure('Color',[1,1,1]);
    hold on;
    
    for g = 1:size(gpdfs, 1)
        rtnPeriod = zeros(size(gpdfs, 2));
        rtnInd = find(~isinf(1 ./ gpdfs(g, :)));
        rtnPeriod(rtnInd) = 1 ./ gpdfs(g, rtnInd);
        plot(x, rtnPeriod, 'LineWidth', 2, 'Color', colors(g, :));
    end
    
end


if stdPlots
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
end