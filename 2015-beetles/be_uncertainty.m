baseDir = 'C:\git-ecoffel\grad-research\bt-output';

state = 'ensemble';

if strcmp(state, 'multi-model')
    models = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
    kvals = {'mean'};
    ensembles = 1;
    thresholds = [100];
elseif strcmp(state, 'ensemble')
    models = {'csiro-mk3-6-0'};
    kvals = {'077', 'mean', '221'};
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
ciThresh = 95;
CI = [];

cnt = 1;

for m = 1:length(models)
    model = models{m};
    
    for k = 1:length(kvals)
        curK = kvals{k};

        for e = ensembles
            for thresh = thresholds
                if strcmp(model, 'mm')
                    path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-' model '-bt-' num2str(thresh) '-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004.mat'];
                else
                    path = [baseDir '\bt-toe-bc-' curK '-r' num2str(e) 'i1p1-' model '-bt-' num2str(thresh) '-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004-' model '.mat'];
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

if length(models) == 1

    perc5 = round((100-ciThresh)/100.0 * size(rankings, 3));
    perc95 = round(ciThresh/100.0 * size(rankings, 3));

    % rank & pick 5th & 95th percentile
    for xlat = 1:size(rankings, 1)
        for ylon = 1:size(rankings, 2)
            rankings(xlat, ylon, :) = sort(rankings(xlat, ylon, :));

            % lower
            CI(xlat, ylon, 1) = rankings(xlat, ylon, perc5);
            % higher
            CI(xlat, ylon, 2) = rankings(xlat, ylon, perc95);
        end
    end

    resultLow = {lat, lon, CI(:, :, 1)};
    resultHigh = {lat, lon, CI(:, :, 2)};

    saveData = struct('data', {resultLow}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2006 2090], ...
                      'plotTitle', 'Time of emergence, 5% threshold', ...
                      'fileTitle', ['toe-ci-5p-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true);

    plotFromDataFile(saveData);

    saveData = struct('data', {resultHigh}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2006 2090], ...
                      'plotTitle', 'Time of emergence, 95% threshold', ...
                      'fileTitle', ['toe-ci-95p-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true);

    plotFromDataFile(saveData);


    % plot std 
    resultStd = {lat, lon, nanstd(rankings, [], 3)};
    saveData = struct('data', {resultStd}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [0 15], ...
                      'plotTitle', 'Time of emergence, STD', ...
                      'fileTitle', ['toe-ci-std-' fileExt '.pdf'], ...
                      'plotXUnits', 'Years', ...
                      'blockWater', true);

    plotFromDataFile(saveData); 

else
    
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
                      'plotRange', [2006 2090], ...
                      'plotTitle', 'Time of emergence, lower bound', ...
                      'fileTitle', ['toe-ci-lower-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true);

    plotFromDataFile(saveData);

    saveData = struct('data', {resultHigh}, ...
                      'plotRegion', 'usne', ...
                      'plotRange', [2006 2090], ...
                      'plotTitle', 'Time of emergence, upper bound', ...
                      'fileTitle', ['toe-ci-upper-' fileExt '.pdf'], ...
                      'plotXUnits', 'Year', ...
                      'blockWater', true);

    plotFromDataFile(saveData);
    
end





