baseDir = 'C:\git-ecoffel\grad-research\bt-output';

state = 'ensemble';

ciPlot = true;
modelRangePlot = true;

if strcmp(state, 'multi-model')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
    kvals = {'077', 'mean', '221'};
    ensembles = 1;
    thresholds = [100];
    rcps = {'rcp45', 'rcp85'};
elseif strcmp(state, 'ensemble')
    models = {'csiro-mk3-6-0'};
    kvals = {'077', 'mean', '221'};
    rcps = {'rcp45', 'rcp85'};
    ensembles = 1:10;
    thresholds = [100];
end
    

if length(models) == 1
    fileExt = 'ensemble';
else
    fileExt = 'model-range';
end

lat = [];
lon = [];
rankings = [];
rankingsNames = {};

% confidence interval
ciThresh = 75;
CI = [];

cnt = 1;

for m = 1:length(models)
    model = models{m};
    
    for k = 1:length(kvals)
        curK = kvals{k};

        for e = ensembles
            for thresh = thresholds
                for r = 1:length(rcps)
                    if strcmp(model, 'mm')
                        path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-' model '-' rcps{r} '-bt-' num2str(thresh) '-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004.mat'];
                    else
                        path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-' model '-' rcps{r} '-bt-' num2str(thresh) '-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004-' model '.mat'];
                    end
                    load(path);

                    if length(lat) == 0
                        lat = saveData.data{1};
                        lon = saveData.data{2};
                    end

                    data = saveData.data{3};
                    rankings(:, :, cnt) = data;
                    rankingsNames{end+1} = models{m};
                    cnt = cnt + 1;

                    clear data saveData;
                end
            end
        end
    end
end

if ciPlot

    perclow = round((100-ciThresh)/100.0 * size(rankings, 3));
    perchigh = round(ciThresh/100.0 * size(rankings, 3));

    % rank & pick percentiles
    for xlat = 1:size(rankings, 1)
        for ylon = 1:size(rankings, 2)
            rankings(xlat, ylon, :) = sort(rankings(xlat, ylon, :));

            % lower
            CI(xlat, ylon, 1) = rankings(xlat, ylon, perclow+1);
            % higher
            CI(xlat, ylon, 2) = rankings(xlat, ylon, perchigh);
        end
    end

    resultLow = {lat, lon, CI(:, :, 1)};
    resultHigh = {lat, lon, CI(:, :, 2)};

    saveData = struct('data', {resultLow}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2005 2090], ...
                      'plotTitle', 'Time of emergence, 0% threshold', ...
                      'fileTitle', ['toe-ci-25p-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true, ...
                      'plotStates', true, ...
                      'plotCountries', false, ...
                      'colormap', brewermap(17, 'YlOrRd'));

    plotFromDataFile(saveData);

    saveData = struct('data', {resultHigh}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2005 2090], ...
                      'plotTitle', 'Time of emergence, 100% threshold', ...
                      'fileTitle', ['toe-ci-75p-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true, ...
                      'plotStates', true, ...
                      'plotCountries', false, ...
                      'colormap', brewermap(17, 'YlOrRd'));

    plotFromDataFile(saveData);
end


%     % plot std 
%     resultStd = {lat, lon, nanstd(rankings, [], 3)};
%     saveData = struct('data', {resultStd}, ...
%                       'plotRegion', 'usne', ...
%                       'plotRange', [0 15], ...
%                       'plotTitle', 'Time of emergence, STD', ...
%                       'fileTitle', ['toe-ci-std-' fileExt '.pdf'], ...
%                       'plotXUnits', 'Years', ...
%                       'blockWater', true);
% 
%     plotFromDataFile(saveData); 

if modelRangePlot
    % search for highest and lowest models
    minModel = -1;
    minModelInd = -1;
    
    maxModel = -1;
    maxModelInd = -1;
    
    for r = 1:size(rankings,3)
        rank = nanmean(nanmean(rankings(:,:,r)));
        
        if minModel == -1 || rank < minModel
            minModel = rank;
            minModelInd = r;
        end
        
        if maxModel == -1 || rank > maxModel
            maxModel = rank;
            maxModelInd = r;
        end
    end
    
    resultLow = {lat, lon, rankings(:,:,minModelInd)};
    resultHigh = {lat, lon, rankings(:,:,maxModelInd)};
    
    saveData = struct('data', {resultLow}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2005 2090], ...
                      'plotTitle', 'Time of emergence, lower bound', ...
                      'fileTitle', ['toe-ci-lower-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true, ...
                      'plotStates', true, ...
                      'plotCountries', true, ...
                      'colormap', brewermap(17, 'YlOrRd'));

    plotFromDataFile(saveData);

    saveData = struct('data', {resultHigh}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2005 2090], ...
                      'plotTitle', 'Time of emergence, upper bound', ...
                      'fileTitle', ['toe-ci-upper-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true, ...
                      'plotStates', true, ...
                      'plotCountries', true, ...
                      'colormap', brewermap(17, 'YlOrRd'));

    plotFromDataFile(saveData);
    
end





